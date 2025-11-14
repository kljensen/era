//// Era: A rigorous natural date/time parser for Gleam
////
//// Era parses natural language date and time expressions into strongly-typed results.
//// It uses parser combinators (not regexes) to handle a wide variety of temporal expressions,
//// from simple times like "5pm" to complex recurring patterns like "every Tuesday at 3pm".
////
//// ## Features
////
//// - **Parse natural language**: "tomorrow at 5pm", "next Tuesday", "in 3 days"
//// - **Multiple expression types**: single points, ranges, recurring events
//// - **Handles text "in the wild"**: Extracts dates from surrounding text
//// - **Type-safe results**: All parsing results are strongly typed
//// - **Ergonomic API**: Helper functions for common operations
//// - **Comprehensive formatting**: Convert results back to readable text
////
//// ## Quick Start
////
//// ```gleam
//// import era
////
//// // Parse a simple time
//// era.parse("5pm")
//// // => Ok(SinglePoint(DateTime { hour: Some(17), .. }))
////
//// // Parse multiple times
//// era.parse("Tuesday and Thursday at 3pm")
//// // => Ok(MultiplePoints([..]))
////
//// // Parse a range
//// era.parse("Monday 9am-5pm")
//// // => Ok(Range(TimeRange { .. }))
////
//// // Parse recurring
//// era.parse("every Tuesday at 2pm")
//// // => Ok(Recurring(RecurringEvent { .. }))
////
//// // Format back to text
//// let assert Ok(result) = era.parse("tomorrow at 5pm")
//// era.format(result)
//// // => "Tomorrow at 17:00"
//// ```
////
//// ## Building DateTime Values
////
//// Instead of constructing DateTime manually, use the ergonomic helper functions:
////
//// ```gleam
//// import era
////
//// // Times
//// era.time(14, 30)      // Today at 2:30pm (24-hour)
//// era.time_pm(2, 30)    // Today at 2:30pm (12-hour)
//// era.noon()            // Today at 12:00pm
////
//// // Dates
//// era.date(2024, 12, 25)  // Christmas 2024
////
//// // Full datetime
//// era.datetime(2024, 12, 25, 10, 30)
////
//// // Relative times
//// era.tomorrow()                  // Tomorrow
//// era.tomorrow_at_pm(5, 0)        // Tomorrow at 5pm
//// era.next_monday()               // Next Monday
//// era.next_monday_at(9, 0)        // Next Monday at 9am
//// era.in_days(3)                  // 3 days from now
////
//// // Recurring events
//// era.daily(era.time(9, 0))       // Every day at 9am
//// era.every(Monday, era.time_pm(2, 0))  // Every Monday at 2pm
//// ```
////
//// ## Working with Results
////
//// Use the inspection functions to check what was parsed:
////
//// ```gleam
//// let assert Ok(result) = era.parse("5pm")
////
//// era.is_single_point(result)  // True
//// era.describe(result)  // "single point in time"
////
//// // Extract the DateTime
//// let assert Ok(dt) = era.to_single_point(result)
//// ```
////
//// ## Validation
////
//// Validate DateTime values to ensure they have reasonable values:
////
//// ```gleam
//// let dt = era.time(14, 30)
//// era.validate(dt)  // Ok(DateTime { .. })
////
//// let bad = era.time(25, 0)  // Invalid hour
//// era.validate(bad)  // Error("Hour must be 0-23, got 25")
//// ```

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import nibble.{type Parser, do, return}
import nibble/lexer

// ============================================================================
// CORE TYPE SYSTEM
// ============================================================================

/// Represents a specific point in time, with optional components.
///
/// A DateTime can represent various levels of precision:
/// - Just a time: `DateTime { hour: Some(14), minute: Some(30), .. }`
/// - Just a date: `DateTime { year: Some(2024), month: Some(12), day: Some(25), .. }`
/// - Full datetime: All fields specified
/// - Relative time: `DateTime { relative: Some(Tomorrow), .. }`
///
/// Use the helper functions `time()`, `date()`, `datetime()`, and `relative()`
/// to create DateTime values more ergonomically.
pub type DateTime {
  DateTime(
    year: Option(Int),
    month: Option(Int),
    day: Option(Int),
    hour: Option(Int),
    minute: Option(Int),
    second: Option(Int),
    /// For relative dates like "tomorrow" or "next Tuesday"
    relative: Option(RelativeTime),
  )
}

/// Expressions for relative time, like "tomorrow", "next week", or "3 days ago".
///
/// These are used when the date/time is specified relative to the current moment
/// rather than as an absolute date. The actual calendar date is determined at
/// runtime based on when the expression is evaluated.
pub type RelativeTime {
  /// The current moment
  Now
  /// Today (any time during the current day)
  Today
  /// The day after today
  Tomorrow
  /// The day before today
  Yesterday
  /// N minutes in the past (e.g., "5 minutes ago")
  MinutesAgo(Int)
  /// N minutes in the future (e.g., "in 10 minutes")
  MinutesFromNow(Int)
  /// N hours in the past
  HoursAgo(Int)
  /// N hours in the future
  HoursFromNow(Int)
  /// N days in the past
  DaysAgo(Int)
  /// N days in the future
  DaysFromNow(Int)
  /// N weeks in the past
  WeeksAgo(Int)
  /// N weeks in the future
  WeeksFromNow(Int)
  /// N months in the past
  MonthsAgo(Int)
  /// N months in the future
  MonthsFromNow(Int)
  /// N years in the past
  YearsAgo(Int)
  /// N years in the future
  YearsFromNow(Int)
  /// The next occurrence of a weekday (e.g., "next Monday")
  NextWeekday(Weekday)
  /// The previous occurrence of a weekday (e.g., "last Friday")
  LastWeekday(Weekday)
  /// The nearest occurrence of a weekday in the current week
  ThisWeekday(Weekday)
}

/// Days of the week (Monday through Sunday)
pub type Weekday {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
}

/// Common time-of-day descriptors like "morning" or "noon".
///
/// These are approximate times that get mapped to specific hours:
/// - Morning: ~6am
/// - Afternoon: ~3pm
/// - Evening: ~8pm
/// - Night: ~10pm
/// - Noon: exactly 12pm
/// - Midnight: exactly 12am
pub type TimeOfDay {
  Morning
  Afternoon
  Evening
  Night
  Noon
  Midnight
}

/// A continuous period of time with a start and end point.
///
/// Both the start and end are DateTime values, which can have any
/// level of precision (date, time, or both).
///
/// ## Examples
/// - "9am to 5pm today"
/// - "Monday through Friday"
/// - "December 1-15, 2024"
pub type TimeRange {
  TimeRange(start: DateTime, end: DateTime)
}

/// Patterns for recurring events (daily, weekly, specific weekdays, etc.)
///
/// These describe how often an event repeats, without specifying the
/// actual time. The time is specified separately in a RecurringEvent.
pub type Recurrence {
  /// Every day
  Daily
  /// Every week (same day of week)
  Weekly
  /// Every month (same day of month)
  Monthly
  /// Every year (same date)
  Yearly
  /// Specific weekdays each week (e.g., "every Monday and Wednesday")
  EveryWeekday(weekdays: List(Weekday))
  /// Every N days
  EveryNDays(n: Int)
  /// Every N weeks
  EveryNWeeks(n: Int)
  /// Every N months
  EveryNMonths(n: Int)
  /// Nth occurrence of a weekday each month (e.g., "2nd Tuesday of each month")
  NthWeekdayOfMonth(n: Int, weekday: Weekday)
}

/// A recurring event: a pattern combined with a time template.
///
/// This represents events that happen repeatedly, like "every Tuesday at 3pm"
/// or "daily at 9am". The `pattern` describes when it repeats, the `time`
/// describes what time, and the optional `until` date specifies when to stop.
///
/// ## Examples
/// ```gleam
/// RecurringEvent {
///   pattern: EveryWeekday([Tuesday, Thursday]),
///   time: DateTime { hour: Some(15), minute: Some(0), .. },
///   until: None,
/// }
/// // "Every Tuesday and Thursday at 3pm"
/// ```
pub type RecurringEvent {
  RecurringEvent(
    /// How often the event repeats
    pattern: Recurrence,
    /// What time the event occurs (template for each occurrence)
    time: DateTime,
    /// Optional end date for the recurrence
    until: Option(DateTime),
  )
}

/// The main result type: what we parsed from the input
///
/// This represents the different types of temporal expressions that can be parsed:
/// - `SinglePoint`: A single moment in time, like "tomorrow at 5pm"
/// - `MultiplePoints`: Multiple discrete moments, like "Tuesday and Thursday at 5pm"
/// - `Range`: A continuous time period, like "Monday 9am-5pm"
/// - `MultipleRanges`: Multiple time periods, like "Mon-Wed 9-5 and Fri 10-4"
/// - `Recurring`: A repeating pattern, like "every Tuesday at 3pm"
pub type ParsedDate {
  SinglePoint(DateTime)
  MultiplePoints(List(DateTime))
  Range(TimeRange)
  MultipleRanges(List(TimeRange))
  Recurring(RecurringEvent)
}

// ============================================================================
// HELPER FUNCTIONS - Convenience builders and utilities
// ============================================================================

/// Creates a DateTime representing just a time (24-hour format)
/// Defaults to today with the specified time.
///
/// ## Examples
/// ```gleam
/// time(14, 30)  // Today at 2:30pm
/// time(9, 0)    // Today at 9:00am
/// ```
pub fn time(hour: Int, minute: Int) -> DateTime {
  DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(hour),
    minute: Some(minute),
    second: Some(0),
    relative: Some(Today),
  )
}

/// Creates a DateTime for a time in the PM (12-hour format)
///
/// ## Examples
/// ```gleam
/// time_pm(5, 30)  // Today at 5:30pm (17:30)
/// time_pm(12, 0)  // Today at noon (12:00)
/// ```
pub fn time_pm(hour: Int, minute: Int) -> DateTime {
  let hour_24 = case hour {
    12 -> 12
    h -> h + 12
  }
  time(hour_24, minute)
}

/// Creates a DateTime for a time in the AM (12-hour format)
///
/// ## Examples
/// ```gleam
/// time_am(9, 30)   // Today at 9:30am
/// time_am(12, 0)   // Today at midnight (00:00)
/// ```
pub fn time_am(hour: Int, minute: Int) -> DateTime {
  let hour_24 = case hour {
    12 -> 0
    h -> h
  }
  time(hour_24, minute)
}

/// Creates a DateTime representing a date (year, month, day)
/// Time fields are left unspecified.
///
/// ## Examples
/// ```gleam
/// date(2024, 12, 25)  // Christmas 2024
/// date(2025, 1, 1)    // New Year's Day 2025
/// ```
pub fn date(year: Int, month: Int, day: Int) -> DateTime {
  DateTime(
    year: Some(year),
    month: Some(month),
    day: Some(day),
    hour: None,
    minute: None,
    second: None,
    relative: None,
  )
}

/// Creates a DateTime with both date and time
///
/// ## Examples
/// ```gleam
/// datetime(2024, 12, 25, 10, 30)  // Christmas 2024 at 10:30am
/// ```
pub fn datetime(
  year: Int,
  month: Int,
  day: Int,
  hour: Int,
  minute: Int,
) -> DateTime {
  DateTime(
    year: Some(year),
    month: Some(month),
    day: Some(day),
    hour: Some(hour),
    minute: Some(minute),
    second: Some(0),
    relative: None,
  )
}

/// Creates a DateTime representing a relative time expression
///
/// This is the low-level function. Consider using the specific helpers like
/// `tomorrow()`, `next_monday()`, `in_days(3)` instead for better ergonomics.
///
/// ## Examples
/// ```gleam
/// relative(Tomorrow)              // Tomorrow (unspecified time)
/// relative(NextWeekday(Monday))   // Next Monday
/// ```
pub fn relative(rel: RelativeTime) -> DateTime {
  DateTime(
    year: None,
    month: None,
    day: None,
    hour: None,
    minute: None,
    second: None,
    relative: Some(rel),
  )
}

/// Creates a DateTime with a relative time and specific time of day
///
/// This is the low-level function. Consider using `tomorrow_at()`, `next_monday_at()`
/// instead for common patterns.
///
/// ## Examples
/// ```gleam
/// relative_time(Tomorrow, 14, 30)  // Tomorrow at 2:30pm
/// relative_time(NextWeekday(Friday), 9, 0)  // Next Friday at 9am
/// ```
pub fn relative_time(rel: RelativeTime, hour: Int, minute: Int) -> DateTime {
  DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(hour),
    minute: Some(minute),
    second: Some(0),
    relative: Some(rel),
  )
}

// ============================================================================
// SIMPLE RELATIVE TIME HELPERS - Ergonomic functions for common cases
// ============================================================================

/// The current moment
pub fn now() -> DateTime {
  relative(Now)
}

/// Today (any time during the current day)
pub fn today() -> DateTime {
  relative(Today)
}

/// Tomorrow (no specific time)
pub fn tomorrow() -> DateTime {
  relative(Tomorrow)
}

/// Yesterday (no specific time)
pub fn yesterday() -> DateTime {
  relative(Yesterday)
}

/// Tomorrow at a specific time (24-hour format)
///
/// ## Examples
/// ```gleam
/// tomorrow_at(14, 30)  // Tomorrow at 2:30pm
/// ```
pub fn tomorrow_at(hour: Int, minute: Int) -> DateTime {
  relative_time(Tomorrow, hour, minute)
}

/// Tomorrow at a PM time (12-hour format)
///
/// ## Examples
/// ```gleam
/// tomorrow_at_pm(5, 30)  // Tomorrow at 5:30pm
/// ```
pub fn tomorrow_at_pm(hour: Int, minute: Int) -> DateTime {
  let hour_24 = case hour {
    12 -> 12
    h -> h + 12
  }
  relative_time(Tomorrow, hour_24, minute)
}

/// Tomorrow at an AM time (12-hour format)
///
/// ## Examples
/// ```gleam
/// tomorrow_at_am(9, 30)  // Tomorrow at 9:30am
/// ```
pub fn tomorrow_at_am(hour: Int, minute: Int) -> DateTime {
  let hour_24 = case hour {
    12 -> 0
    h -> h
  }
  relative_time(Tomorrow, hour_24, minute)
}

// ============================================================================
// WEEKDAY HELPERS - Next/last occurrences of specific weekdays
// ============================================================================

/// Next occurrence of a specific weekday
///
/// ## Examples
/// ```gleam
/// next(Monday)     // Next Monday
/// next(Friday)     // Next Friday
/// ```
pub fn next(weekday: Weekday) -> DateTime {
  relative(NextWeekday(weekday))
}

/// Next occurrence of a weekday at a specific time
///
/// ## Examples
/// ```gleam
/// next_at(Monday, 9, 0)     // Next Monday at 9am
/// next_at(Friday, 17, 30)   // Next Friday at 5:30pm
/// ```
pub fn next_at(weekday: Weekday, hour: Int, minute: Int) -> DateTime {
  relative_time(NextWeekday(weekday), hour, minute)
}

/// Previous occurrence of a specific weekday
///
/// ## Examples
/// ```gleam
/// last(Monday)     // Last Monday
/// last(Friday)     // Last Friday
/// ```
pub fn last(weekday: Weekday) -> DateTime {
  relative(LastWeekday(weekday))
}

/// Previous occurrence of a weekday at a specific time
///
/// ## Examples
/// ```gleam
/// last_at(Monday, 9, 0)     // Last Monday at 9am
/// ```
pub fn last_at(weekday: Weekday, hour: Int, minute: Int) -> DateTime {
  relative_time(LastWeekday(weekday), hour, minute)
}

// Specific weekday helpers for discoverability
/// Next Monday
pub fn next_monday() -> DateTime {
  next(Monday)
}

/// Next Monday at a specific time
pub fn next_monday_at(hour: Int, minute: Int) -> DateTime {
  next_at(Monday, hour, minute)
}

/// Next Tuesday
pub fn next_tuesday() -> DateTime {
  next(Tuesday)
}

/// Next Tuesday at a specific time
pub fn next_tuesday_at(hour: Int, minute: Int) -> DateTime {
  next_at(Tuesday, hour, minute)
}

/// Next Wednesday
pub fn next_wednesday() -> DateTime {
  next(Wednesday)
}

/// Next Wednesday at a specific time
pub fn next_wednesday_at(hour: Int, minute: Int) -> DateTime {
  next_at(Wednesday, hour, minute)
}

/// Next Thursday
pub fn next_thursday() -> DateTime {
  next(Thursday)
}

/// Next Thursday at a specific time
pub fn next_thursday_at(hour: Int, minute: Int) -> DateTime {
  next_at(Thursday, hour, minute)
}

/// Next Friday
pub fn next_friday() -> DateTime {
  next(Friday)
}

/// Next Friday at a specific time
pub fn next_friday_at(hour: Int, minute: Int) -> DateTime {
  next_at(Friday, hour, minute)
}

/// Next Saturday
pub fn next_saturday() -> DateTime {
  next(Saturday)
}

/// Next Saturday at a specific time
pub fn next_saturday_at(hour: Int, minute: Int) -> DateTime {
  next_at(Saturday, hour, minute)
}

/// Next Sunday
pub fn next_sunday() -> DateTime {
  next(Sunday)
}

/// Next Sunday at a specific time
pub fn next_sunday_at(hour: Int, minute: Int) -> DateTime {
  next_at(Sunday, hour, minute)
}

// ============================================================================
// OFFSET HELPERS - Relative time offsets (past and future)
// ============================================================================

/// N minutes in the future
///
/// ## Examples
/// ```gleam
/// in_minutes(5)   // 5 minutes from now
/// in_minutes(30)  // 30 minutes from now
/// ```
pub fn in_minutes(n: Int) -> DateTime {
  relative(MinutesFromNow(n))
}

/// N minutes in the past
///
/// ## Examples
/// ```gleam
/// ago_minutes(5)   // 5 minutes ago
/// ago_minutes(30)  // 30 minutes ago
/// ```
pub fn ago_minutes(n: Int) -> DateTime {
  relative(MinutesAgo(n))
}

/// N hours in the future
///
/// ## Examples
/// ```gleam
/// in_hours(2)   // 2 hours from now
/// in_hours(24)  // 24 hours from now
/// ```
pub fn in_hours(n: Int) -> DateTime {
  relative(HoursFromNow(n))
}

/// N hours in the past
///
/// ## Examples
/// ```gleam
/// ago_hours(2)   // 2 hours ago
/// ago_hours(24)  // 24 hours ago
/// ```
pub fn ago_hours(n: Int) -> DateTime {
  relative(HoursAgo(n))
}

/// N days in the future
///
/// ## Examples
/// ```gleam
/// in_days(3)   // 3 days from now
/// in_days(7)   // 1 week from now
/// ```
pub fn in_days(n: Int) -> DateTime {
  relative(DaysFromNow(n))
}

/// N days in the past
///
/// ## Examples
/// ```gleam
/// ago_days(3)   // 3 days ago
/// ago_days(7)   // 1 week ago
/// ```
pub fn ago_days(n: Int) -> DateTime {
  relative(DaysAgo(n))
}

/// N weeks in the future
///
/// ## Examples
/// ```gleam
/// in_weeks(2)   // 2 weeks from now
/// in_weeks(4)   // 4 weeks from now
/// ```
pub fn in_weeks(n: Int) -> DateTime {
  relative(WeeksFromNow(n))
}

/// N weeks in the past
///
/// ## Examples
/// ```gleam
/// ago_weeks(2)   // 2 weeks ago
/// ```
pub fn ago_weeks(n: Int) -> DateTime {
  relative(WeeksAgo(n))
}

/// N months in the future
///
/// ## Examples
/// ```gleam
/// in_months(3)   // 3 months from now
/// in_months(6)   // 6 months from now
/// ```
pub fn in_months(n: Int) -> DateTime {
  relative(MonthsFromNow(n))
}

/// N months in the past
///
/// ## Examples
/// ```gleam
/// ago_months(3)   // 3 months ago
/// ```
pub fn ago_months(n: Int) -> DateTime {
  relative(MonthsAgo(n))
}

/// N years in the future
///
/// ## Examples
/// ```gleam
/// in_years(1)   // 1 year from now
/// in_years(5)   // 5 years from now
/// ```
pub fn in_years(n: Int) -> DateTime {
  relative(YearsFromNow(n))
}

/// N years in the past
///
/// ## Examples
/// ```gleam
/// ago_years(1)   // 1 year ago
/// ago_years(10)  // 10 years ago
/// ```
pub fn ago_years(n: Int) -> DateTime {
  relative(YearsAgo(n))
}

/// Creates a TimeRange from two DateTimes
///
/// ## Examples
/// ```gleam
/// range(time(9, 0), time(17, 0))  // 9am to 5pm today
/// ```
pub fn range(start: DateTime, end: DateTime) -> TimeRange {
  TimeRange(start: start, end: end)
}

/// Noon (12:00pm) today
///
/// ## Examples
/// ```gleam
/// noon()  // Today at 12:00pm
/// ```
pub fn noon() -> DateTime {
  time(12, 0)
}

/// Midnight (00:00) today
///
/// ## Examples
/// ```gleam
/// midnight()  // Today at midnight (00:00)
/// ```
pub fn midnight() -> DateTime {
  time(0, 0)
}

// ============================================================================
// RECURRING EVENT HELPERS
// ============================================================================

/// Create a daily recurring event at a specific time
///
/// ## Examples
/// ```gleam
/// daily(time(9, 0))  // Every day at 9am
/// daily(time_pm(2, 30))  // Every day at 2:30pm
/// ```
pub fn daily(at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Daily, time: at, until: None)
}

/// Create a daily recurring event that ends on a specific date
///
/// ## Examples
/// ```gleam
/// daily_until(time(9, 0), date(2024, 12, 31))  // Every day at 9am until Dec 31
/// ```
pub fn daily_until(at: DateTime, end: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Daily, time: at, until: Some(end))
}

/// Create a weekly recurring event at a specific time
///
/// ## Examples
/// ```gleam
/// weekly(time(14, 0))  // Every week at 2pm
/// ```
pub fn weekly(at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Weekly, time: at, until: None)
}

/// Create a weekly recurring event that ends on a specific date
///
/// ## Examples
/// ```gleam
/// weekly_until(time(10, 0), date(2025, 6, 1))  // Every week at 10am until June 1
/// ```
pub fn weekly_until(at: DateTime, end: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Weekly, time: at, until: Some(end))
}

/// Create a monthly recurring event at a specific time
///
/// ## Examples
/// ```gleam
/// monthly(time(9, 0))  // Every month at 9am
/// ```
pub fn monthly(at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Monthly, time: at, until: None)
}

/// Create a monthly recurring event that ends on a specific date
///
/// ## Examples
/// ```gleam
/// monthly_until(time(15, 0), date(2025, 12, 31))  // Every month at 3pm until end of year
/// ```
pub fn monthly_until(at: DateTime, end: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Monthly, time: at, until: Some(end))
}

/// Create a yearly recurring event at a specific time
///
/// ## Examples
/// ```gleam
/// yearly(datetime(2024, 1, 1, 0, 0))  // Every year on Jan 1 at midnight
/// ```
pub fn yearly(at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Yearly, time: at, until: None)
}

/// Create a yearly recurring event that ends on a specific date
///
/// ## Examples
/// ```gleam
/// yearly_until(datetime(2024, 7, 4, 12, 0), date(2030, 12, 31))  // Every July 4th at noon until 2030
/// ```
pub fn yearly_until(at: DateTime, end: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: Yearly, time: at, until: Some(end))
}

/// Create a recurring event for specific weekdays
///
/// ## Examples
/// ```gleam
/// every_weekday([Monday, Wednesday, Friday], time(9, 0))  // MWF at 9am
/// every_weekday([Tuesday, Thursday], time_pm(2, 0))  // Tue/Thu at 2pm
/// ```
pub fn every_weekday(days: List(Weekday), at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: EveryWeekday(days), time: at, until: None)
}

/// Create a recurring event for specific weekdays that ends on a date
///
/// ## Examples
/// ```gleam
/// every_weekday_until([Monday, Wednesday], time(10, 0), date(2025, 6, 1))
/// ```
pub fn every_weekday_until(
  days: List(Weekday),
  at: DateTime,
  end: DateTime,
) -> RecurringEvent {
  RecurringEvent(pattern: EveryWeekday(days), time: at, until: Some(end))
}

/// Create a recurring event for a single weekday
///
/// ## Examples
/// ```gleam
/// every(Monday, time(9, 0))  // Every Monday at 9am
/// every(Friday, time_pm(5, 0))  // Every Friday at 5pm
/// ```
pub fn every(day: Weekday, at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: EveryWeekday([day]), time: at, until: None)
}

/// Create a recurring event for a single weekday that ends on a date
///
/// ## Examples
/// ```gleam
/// every_until(Tuesday, time(14, 0), date(2025, 12, 31))  // Every Tuesday at 2pm until end of year
/// ```
pub fn every_until(day: Weekday, at: DateTime, end: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: EveryWeekday([day]), time: at, until: Some(end))
}

/// Create a recurring event every N days
///
/// ## Examples
/// ```gleam
/// every_n_days(3, time(10, 0))  // Every 3 days at 10am
/// ```
pub fn every_n_days(n: Int, at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: EveryNDays(n), time: at, until: None)
}

/// Create a recurring event every N weeks
///
/// ## Examples
/// ```gleam
/// every_n_weeks(2, time(9, 0))  // Every 2 weeks (bi-weekly) at 9am
/// ```
pub fn every_n_weeks(n: Int, at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: EveryNWeeks(n), time: at, until: None)
}

/// Create a recurring event every N months
///
/// ## Examples
/// ```gleam
/// every_n_months(3, time(15, 0))  // Every 3 months (quarterly) at 3pm
/// ```
pub fn every_n_months(n: Int, at: DateTime) -> RecurringEvent {
  RecurringEvent(pattern: EveryNMonths(n), time: at, until: None)
}

// ============================================================================
// INSPECTION FUNCTIONS
// ============================================================================

/// Check if a ParsedDate represents a single point in time
///
/// ## Examples
/// ```gleam
/// is_single_point(SinglePoint(time(9, 0)))  // True
/// is_single_point(Range(..))                // False
/// ```
pub fn is_single_point(parsed: ParsedDate) -> Bool {
  case parsed {
    SinglePoint(_) -> True
    _ -> False
  }
}

/// Check if a ParsedDate represents multiple points in time
pub fn is_multiple_points(parsed: ParsedDate) -> Bool {
  case parsed {
    MultiplePoints(_) -> True
    _ -> False
  }
}

/// Check if a ParsedDate represents a time range
pub fn is_range(parsed: ParsedDate) -> Bool {
  case parsed {
    Range(_) -> True
    _ -> False
  }
}

/// Check if a ParsedDate represents multiple time ranges
pub fn is_multiple_ranges(parsed: ParsedDate) -> Bool {
  case parsed {
    MultipleRanges(_) -> True
    _ -> False
  }
}

/// Check if a ParsedDate represents a recurring event
pub fn is_recurring(parsed: ParsedDate) -> Bool {
  case parsed {
    Recurring(_) -> True
    _ -> False
  }
}

/// Extract the DateTime if ParsedDate is a SinglePoint
///
/// ## Examples
/// ```gleam
/// to_single_point(SinglePoint(dt))  // Ok(dt)
/// to_single_point(Range(..))        // Error("Not a single point")
/// ```
pub fn to_single_point(parsed: ParsedDate) -> Result(DateTime, String) {
  case parsed {
    SinglePoint(dt) -> Ok(dt)
    _ -> Error("Not a single point in time")
  }
}

/// Extract the list of DateTimes if ParsedDate is MultiplePoints
pub fn to_multiple_points(parsed: ParsedDate) -> Result(List(DateTime), String) {
  case parsed {
    MultiplePoints(dates) -> Ok(dates)
    _ -> Error("Not multiple points in time")
  }
}

/// Extract the TimeRange if ParsedDate is a Range
pub fn to_range(parsed: ParsedDate) -> Result(TimeRange, String) {
  case parsed {
    Range(tr) -> Ok(tr)
    _ -> Error("Not a time range")
  }
}

/// Extract the list of TimeRanges if ParsedDate is MultipleRanges
///
/// ## Examples
/// ```gleam
/// to_multiple_ranges(MultipleRanges([r1, r2]))  // Ok([r1, r2])
/// to_multiple_ranges(SinglePoint(..))           // Error("Not multiple ranges")
/// ```
pub fn to_multiple_ranges(
  parsed: ParsedDate,
) -> Result(List(TimeRange), String) {
  case parsed {
    MultipleRanges(ranges) -> Ok(ranges)
    _ -> Error("Not multiple time ranges")
  }
}

/// Extract the RecurringEvent if ParsedDate is Recurring
pub fn to_recurring(parsed: ParsedDate) -> Result(RecurringEvent, String) {
  case parsed {
    Recurring(re) -> Ok(re)
    _ -> Error("Not a recurring event")
  }
}

/// Get a human-readable description of what type of ParsedDate this is
///
/// ## Examples
/// ```gleam
/// describe(SinglePoint(..))   // "single point in time"
/// describe(Range(..))         // "time range"
/// describe(Recurring(..))     // "recurring event"
/// ```
pub fn describe(parsed: ParsedDate) -> String {
  case parsed {
    SinglePoint(_) -> "single point in time"
    MultiplePoints(dates) ->
      int.to_string(list.length(dates)) <> " points in time"
    Range(_) -> "time range"
    MultipleRanges(ranges) ->
      int.to_string(list.length(ranges)) <> " time ranges"
    Recurring(_) -> "recurring event"
  }
}

// ============================================================================
// VALIDATION - Check DateTime values for validity
// ============================================================================

/// Validate that a DateTime has reasonable values.
///
/// Checks that numeric fields are within valid ranges:
/// - Month: 1-12
/// - Day: 1-31 (basic check, doesn't validate per-month limits)
/// - Hour: 0-23
/// - Minute: 0-59
/// - Second: 0-59
///
/// Returns Ok(dt) if valid, or Error with a description of what's wrong.
///
/// ## Examples
/// ```gleam
/// validate(time(14, 30))  // Ok(DateTime { .. })
/// validate(time(25, 0))   // Error("Hour must be 0-23, got 25")
/// validate(date(2024, 13, 1))  // Error("Month must be 1-12, got 13")
/// ```
pub fn validate(dt: DateTime) -> Result(DateTime, String) {
  case dt.month {
    Some(m) if m < 1 || m > 12 ->
      Error("Month must be 1-12, got " <> int.to_string(m))
    _ -> Ok(dt)
  }
  |> result.then(fn(_) {
    case dt.day {
      Some(d) if d < 1 || d > 31 ->
        Error("Day must be 1-31, got " <> int.to_string(d))
      _ -> Ok(dt)
    }
  })
  |> result.then(fn(_) {
    case dt.hour {
      Some(h) if h < 0 || h > 23 ->
        Error("Hour must be 0-23, got " <> int.to_string(h))
      _ -> Ok(dt)
    }
  })
  |> result.then(fn(_) {
    case dt.minute {
      Some(m) if m < 0 || m > 59 ->
        Error("Minute must be 0-59, got " <> int.to_string(m))
      _ -> Ok(dt)
    }
  })
  |> result.then(fn(_) {
    case dt.second {
      Some(s) if s < 0 || s > 59 ->
        Error("Second must be 0-59, got " <> int.to_string(s))
      _ -> Ok(dt)
    }
  })
}

/// Check if a DateTime has a time component (hour and/or minute)
///
/// ## Examples
/// ```gleam
/// has_time(time(14, 30))  // True
/// has_time(date(2024, 12, 25))  // False
/// ```
pub fn has_time(dt: DateTime) -> Bool {
  case dt.hour, dt.minute {
    None, None -> False
    _, _ -> True
  }
}

/// Check if a DateTime has a date component (year, month, day)
///
/// ## Examples
/// ```gleam
/// has_date(date(2024, 12, 25))  // True
/// has_date(time(14, 30))  // False
/// ```
pub fn has_date(dt: DateTime) -> Bool {
  case dt.year, dt.month, dt.day {
    None, None, None -> False
    _, _, _ -> True
  }
}

/// Check if a DateTime is fully specified (has both date and time)
///
/// ## Examples
/// ```gleam
/// is_complete(datetime(2024, 12, 25, 14, 30))  // True
/// is_complete(time(14, 30))  // False
/// is_complete(date(2024, 12, 25))  // False
/// ```
pub fn is_complete(dt: DateTime) -> Bool {
  has_time(dt) && has_date(dt)
}

/// Check if a DateTime represents a relative expression
///
/// ## Examples
/// ```gleam
/// is_relative(relative(Tomorrow))  // True
/// is_relative(date(2024, 12, 25))  // False
/// ```
pub fn is_relative(dt: DateTime) -> Bool {
  case dt.relative {
    Some(_) -> True
    None -> False
  }
}

// ============================================================================
// LEXER - Tokenize the input
// ============================================================================

pub type Token {
  // Numbers
  Number(Int)
  // Time separators
  Colon
  Dash
  Slash
  Dot
  Comma
  // Keywords - relative
  TokNow
  TokToday
  TokTomorrow
  TokYesterday
  TokNext
  TokLast
  TokThis
  TokAgo
  TokFrom
  // Keywords - time units
  TokMinute
  TokMinutes
  TokHour
  TokHours
  TokDay
  TokDays
  TokWeek
  TokWeeks
  TokMonth
  TokMonths
  TokYear
  TokYears
  // Keywords - weekdays
  TokMonday
  TokTuesday
  TokWednesday
  TokThursday
  TokFriday
  TokSaturday
  TokSunday
  // Keywords - time of day
  TokMorning
  TokAfternoon
  TokEvening
  TokNight
  TokTonight
  TokNoon
  TokMidnight
  // Keywords - AM/PM
  TokAM
  TokPM
  // Keywords - recurrence
  TokEvery
  TokDaily
  TokWeekly
  TokMonthly
  TokYearly
  TokUntil
  // Keywords - conjunctions
  TokAnd
  TokOr
  TokTo
  TokThrough
  TokThru
  // Keywords - prepositions
  TokAt
  TokOn
  TokIn
  TokOf
  // Month names
  TokJanuary
  TokFebruary
  TokMarch
  TokApril
  TokMay
  TokJune
  TokJuly
  TokAugust
  TokSeptember
  TokOctober
  TokNovember
  TokDecember
  // Special
  Whitespace
  Unknown(String)
}

/// Create the lexer for tokenizing natural date input
// Lexer is internal implementation detail, not exposed in public API
fn lexer() -> lexer.Lexer(Token, Nil) {
  let whitespace = lexer.whitespace(Nil)

  lexer.simple([
    // Numbers
    lexer.int(Number),

    // Punctuation
    lexer.token(":", Colon),
    lexer.token("-", Dash),
    lexer.token("/", Slash),
    lexer.token(".", Dot),
    lexer.token(",", Comma),

    // Relative time keywords (case insensitive via multiple patterns)
    lexer.keyword("now", "NOW", TokNow),
    lexer.keyword("today", "TODAY", TokToday),
    lexer.keyword("tomorrow", "TOMORROW", TokTomorrow),
    lexer.keyword("yesterday", "YESTERDAY", TokYesterday),
    lexer.keyword("next", "NEXT", TokNext),
    lexer.keyword("last", "LAST", TokLast),
    lexer.keyword("this", "THIS", TokThis),
    lexer.keyword("ago", "AGO", TokAgo),
    lexer.keyword("from", "FROM", TokFrom),

    // Time units
    lexer.keyword("minute", "MINUTE", TokMinute),
    lexer.keyword("minutes", "MINUTES", TokMinutes),
    lexer.keyword("hour", "HOUR", TokHour),
    lexer.keyword("hours", "HOURS", TokHours),
    lexer.keyword("day", "DAY", TokDay),
    lexer.keyword("days", "DAYS", TokDays),
    lexer.keyword("week", "WEEK", TokWeek),
    lexer.keyword("weeks", "WEEKS", TokWeeks),
    lexer.keyword("month", "MONTH", TokMonth),
    lexer.keyword("months", "MONTHS", TokMonths),
    lexer.keyword("year", "YEAR", TokYear),
    lexer.keyword("years", "YEARS", TokYears),

    // Weekdays
    lexer.keyword("monday", "MONDAY", TokMonday),
    lexer.keyword("mon", "MON", TokMonday),
    lexer.keyword("tuesday", "TUESDAY", TokTuesday),
    lexer.keyword("tue", "TUE", TokTuesday),
    lexer.keyword("tues", "TUES", TokTuesday),
    lexer.keyword("wednesday", "WEDNESDAY", TokWednesday),
    lexer.keyword("wed", "WED", TokWednesday),
    lexer.keyword("thursday", "THURSDAY", TokThursday),
    lexer.keyword("thu", "THU", TokThursday),
    lexer.keyword("thur", "THUR", TokThursday),
    lexer.keyword("thurs", "THURS", TokThursday),
    lexer.keyword("friday", "FRIDAY", TokFriday),
    lexer.keyword("fri", "FRI", TokFriday),
    lexer.keyword("saturday", "SATURDAY", TokSaturday),
    lexer.keyword("sat", "SAT", TokSaturday),
    lexer.keyword("sunday", "SUNDAY", TokSunday),
    lexer.keyword("sun", "SUN", TokSunday),

    // Time of day
    lexer.keyword("morning", "MORNING", TokMorning),
    lexer.keyword("afternoon", "AFTERNOON", TokAfternoon),
    lexer.keyword("evening", "EVENING", TokEvening),
    lexer.keyword("tonight", "TONIGHT", TokTonight),
    lexer.keyword("night", "NIGHT", TokNight),
    lexer.keyword("noon", "NOON", TokNoon),
    lexer.keyword("midnight", "MIDNIGHT", TokMidnight),

    // AM/PM
    lexer.keyword("am", "AM", TokAM),
    lexer.keyword("a.m.", "A.M.", TokAM),
    lexer.keyword("pm", "PM", TokPM),
    lexer.keyword("p.m.", "P.M.", TokPM),

    // Recurrence
    lexer.keyword("every", "EVERY", TokEvery),
    lexer.keyword("daily", "DAILY", TokDaily),
    lexer.keyword("weekly", "WEEKLY", TokWeekly),
    lexer.keyword("monthly", "MONTHLY", TokMonthly),
    lexer.keyword("yearly", "YEARLY", TokYearly),
    lexer.keyword("until", "UNTIL", TokUntil),

    // Conjunctions
    lexer.keyword("and", "AND", TokAnd),
    lexer.keyword("or", "OR", TokOr),
    lexer.keyword("to", "TO", TokTo),
    lexer.keyword("through", "THROUGH", TokThrough),
    lexer.keyword("thru", "THRU", TokThru),

    // Prepositions
    lexer.keyword("at", "AT", TokAt),
    lexer.keyword("on", "ON", TokOn),
    lexer.keyword("in", "IN", TokIn),
    lexer.keyword("of", "OF", TokOf),

    // Months
    lexer.keyword("january", "JANUARY", TokJanuary),
    lexer.keyword("jan", "JAN", TokJanuary),
    lexer.keyword("february", "FEBRUARY", TokFebruary),
    lexer.keyword("feb", "FEB", TokFebruary),
    lexer.keyword("march", "MARCH", TokMarch),
    lexer.keyword("mar", "MAR", TokMarch),
    lexer.keyword("april", "APRIL", TokApril),
    lexer.keyword("apr", "APR", TokApril),
    lexer.keyword("may", "MAY", TokMay),
    lexer.keyword("june", "JUNE", TokJune),
    lexer.keyword("jun", "JUN", TokJune),
    lexer.keyword("july", "JULY", TokJuly),
    lexer.keyword("jul", "JUL", TokJuly),
    lexer.keyword("august", "AUGUST", TokAugust),
    lexer.keyword("aug", "AUG", TokAugust),
    lexer.keyword("september", "SEPTEMBER", TokSeptember),
    lexer.keyword("sep", "SEP", TokSeptember),
    lexer.keyword("sept", "SEPT", TokSeptember),
    lexer.keyword("october", "OCTOBER", TokOctober),
    lexer.keyword("oct", "OCT", TokOctober),
    lexer.keyword("november", "NOVEMBER", TokNovember),
    lexer.keyword("nov", "NOV", TokNovember),
    lexer.keyword("december", "DECEMBER", TokDecember),
    lexer.keyword("dec", "DEC", TokDecember),

    // Catch-all for unknown words (MUST be last to not shadow keywords)
    lexer.identifier(
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'",
      Unknown
    ),
    // Unknown punctuation (!, ?, ;, etc.)
    lexer.token("?", fn(_) { Unknown("?") }),
    lexer.token("!", fn(_) { Unknown("!") }),
    lexer.token(";", fn(_) { Unknown(";") }),
    lexer.token("(", fn(_) { Unknown("(") }),
    lexer.token(")", fn(_) { Unknown(")") }),
    lexer.token("[", fn(_) { Unknown("[") }),
    lexer.token("]", fn(_) { Unknown("]") }),
    lexer.token("{", fn(_) { Unknown("{") }),
    lexer.token("}", fn(_) { Unknown("}") }),
    lexer.token("'", fn(_) { Unknown("'") }),
    lexer.token("\"", fn(_) { Unknown("\"") }),
  ])
  |> lexer.ignore(whitespace)
}

// ============================================================================
// PARSER COMBINATORS
// ============================================================================

/// Skip any number of Unknown word tokens
fn skip_unknown() -> Parser(Nil, Token, e) {
  nibble.many(nibble.take_if(fn(token) {
    case token {
      Unknown(_) -> Ok(Nil)
      _ -> Error(Nil)
    }
  }))
  |> nibble.replace(Nil)
}

/// Parse a weekday token
fn weekday() -> Parser(Weekday, Token, e) {
  nibble.one_of([
    nibble.token(TokMonday) |> nibble.replace(Monday),
    nibble.token(TokTuesday) |> nibble.replace(Tuesday),
    nibble.token(TokWednesday) |> nibble.replace(Wednesday),
    nibble.token(TokThursday) |> nibble.replace(Thursday),
    nibble.token(TokFriday) |> nibble.replace(Friday),
    nibble.token(TokSaturday) |> nibble.replace(Saturday),
    nibble.token(TokSunday) |> nibble.replace(Sunday),
  ])
}

/// Parse a number token
fn number() -> Parser(Int, Token, e) {
  nibble.take_if(fn(token) {
    case token {
      Number(n) -> Ok(n)
      _ -> Error(Nil)
    }
  })
}

/// Parse AM or PM
fn meridiem() -> Parser(Bool, Token, e) {
  nibble.one_of([
    nibble.token(TokAM) |> nibble.replace(False),  // False = AM
    nibble.token(TokPM) |> nibble.replace(True),   // True = PM
  ])
}

/// Parse named times: "noon", "midnight"
fn named_time() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    nibble.token(TokNoon) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: Some(12), minute: Some(0), second: Some(0),
      relative: None,
    )),
    nibble.token(TokMidnight) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: Some(0), minute: Some(0), second: Some(0),
      relative: None,
    )),
  ])
}

/// Parse time of day: "morning", "afternoon", "evening", "night"
fn time_of_day() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    nibble.token(TokMorning) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: Some(6), minute: Some(0), second: Some(0),
      relative: None,
    )),
    nibble.token(TokAfternoon) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: Some(15), minute: Some(0), second: Some(0),
      relative: None,
    )),
    nibble.token(TokEvening) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: Some(20), minute: Some(0), second: Some(0),
      relative: None,
    )),
    nibble.token(TokNight) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: Some(22), minute: Some(0), second: Some(0),
      relative: None,
    )),
  ])
}

/// Parse a time like "5pm", "14:30", "3:45:30 PM", "noon", "midnight"
fn time() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    // Named times: "noon", "midnight"
    named_time(),

    // Simple hour with meridiem: "5pm"
    do(number(), fn(hour) {
      do(meridiem(), fn(is_pm) {
        let adjusted_hour = case is_pm, hour {
          True, h if h < 12 -> h + 12
          True, 12 -> 12
          False, 12 -> 0
          False, h -> h
        }
        return(DateTime(
          year: None,
          month: None,
          day: None,
          hour: Some(adjusted_hour),
          minute: Some(0),
          second: Some(0),
          relative: None,
        ))
      })
    }),

    // Hour:Minute:Second with optional meridiem: "14:30:45" or "3:45:30 PM"
    do(number(), fn(hour) {
      do(nibble.token(Colon), fn(_) {
        do(number(), fn(minute) {
          do(nibble.token(Colon), fn(_) {
            do(number(), fn(second) {
              do(nibble.optional(meridiem()), fn(maybe_meridiem) {
                let adjusted_hour = case maybe_meridiem {
                  Some(True) if hour < 12 -> hour + 12
                  Some(True) if hour == 12 -> 12
                  Some(False) if hour == 12 -> 0
                  _ -> hour
                }
                return(DateTime(
                  year: None,
                  month: None,
                  day: None,
                  hour: Some(adjusted_hour),
                  minute: Some(minute),
                  second: Some(second),
                  relative: None,
                ))
              })
            })
          })
        })
      })
    }),

    // Hour:Minute with optional meridiem: "14:30" or "3:45 PM"
    do(number(), fn(hour) {
      do(nibble.token(Colon), fn(_) {
        do(number(), fn(minute) {
          do(nibble.optional(meridiem()), fn(maybe_meridiem) {
            let adjusted_hour = case maybe_meridiem {
              Some(True) if hour < 12 -> hour + 12
              Some(True) if hour == 12 -> 12
              Some(False) if hour == 12 -> 0
              _ -> hour
            }
            return(DateTime(
              year: None,
              month: None,
              day: None,
              hour: Some(adjusted_hour),
              minute: Some(minute),
              second: Some(0),
              relative: None,
            ))
          })
        })
      })
    }),
  ])
}

/// Parse relative day: "today", "tomorrow", "yesterday"
fn relative_day() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    nibble.token(TokNow) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: None, minute: None, second: None,
      relative: Some(Now),
    )),
    nibble.token(TokToday) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: None, minute: None, second: None,
      relative: Some(Today),
    )),
    nibble.token(TokTomorrow) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: None, minute: None, second: None,
      relative: Some(Tomorrow),
    )),
    nibble.token(TokYesterday) |> nibble.replace(DateTime(
      year: None, month: None, day: None,
      hour: None, minute: None, second: None,
      relative: Some(Yesterday),
    )),
  ])
}

/// Parse "next [weekday]"
fn next_weekday() -> Parser(DateTime, Token, e) {
  do(nibble.token(TokNext), fn(_) {
    do(weekday(), fn(day) {
      return(DateTime(
        year: None, month: None, day: None,
        hour: None, minute: None, second: None,
        relative: Some(NextWeekday(day)),
      ))
    })
  })
}

/// Parse "last [weekday]"
fn last_weekday() -> Parser(DateTime, Token, e) {
  do(nibble.token(TokLast), fn(_) {
    do(weekday(), fn(day) {
      return(DateTime(
        year: None, month: None, day: None,
        hour: None, minute: None, second: None,
        relative: Some(LastWeekday(day)),
      ))
    })
  })
}

/// Parse time unit tokens (singular or plural)
fn time_unit_minutes() -> Parser(Nil, Token, e) {
  nibble.one_of([
    nibble.token(TokMinute),
    nibble.token(TokMinutes),
  ])
}

fn time_unit_hours() -> Parser(Nil, Token, e) {
  nibble.one_of([
    nibble.token(TokHour),
    nibble.token(TokHours),
  ])
}

fn time_unit_days() -> Parser(Nil, Token, e) {
  nibble.one_of([
    nibble.token(TokDay),
    nibble.token(TokDays),
  ])
}

fn time_unit_weeks() -> Parser(Nil, Token, e) {
  nibble.one_of([
    nibble.token(TokWeek),
    nibble.token(TokWeeks),
  ])
}

fn time_unit_months() -> Parser(Nil, Token, e) {
  nibble.one_of([
    nibble.token(TokMonth),
    nibble.token(TokMonths),
  ])
}

fn time_unit_years() -> Parser(Nil, Token, e) {
  nibble.one_of([
    nibble.token(TokYear),
    nibble.token(TokYears),
  ])
}

/// Parse relative offset: "3 days ago", "2 weeks from now", "in 3 days", "30 minutes ago"
fn relative_offset() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    // N minutes/hours/days/weeks/months/years ago
    do(number(), fn(n) {
      do(nibble.one_of([
        time_unit_minutes() |> nibble.replace("minutes"),
        time_unit_hours() |> nibble.replace("hours"),
        time_unit_days() |> nibble.replace("days"),
        time_unit_weeks() |> nibble.replace("weeks"),
        time_unit_months() |> nibble.replace("months"),
        time_unit_years() |> nibble.replace("years"),
      ]), fn(unit) {
        do(nibble.token(TokAgo), fn(_) {
          let rel = case unit {
            "minutes" -> MinutesAgo(n)
            "hours" -> HoursAgo(n)
            "days" -> DaysAgo(n)
            "weeks" -> WeeksAgo(n)
            "months" -> MonthsAgo(n)
            "years" -> YearsAgo(n)
            _ -> DaysAgo(n)
          }
          return(DateTime(
            year: None, month: None, day: None,
            hour: None, minute: None, second: None,
            relative: Some(rel),
          ))
        })
      })
    }),

    // N minutes/hours/days/weeks/months/years from now
    do(number(), fn(n) {
      do(nibble.one_of([
        time_unit_minutes() |> nibble.replace("minutes"),
        time_unit_hours() |> nibble.replace("hours"),
        time_unit_days() |> nibble.replace("days"),
        time_unit_weeks() |> nibble.replace("weeks"),
        time_unit_months() |> nibble.replace("months"),
        time_unit_years() |> nibble.replace("years"),
      ]), fn(unit) {
        do(nibble.token(TokFrom), fn(_) {
          do(nibble.optional(nibble.token(TokNow)), fn(_) {
            let rel = case unit {
              "minutes" -> MinutesFromNow(n)
              "hours" -> HoursFromNow(n)
              "days" -> DaysFromNow(n)
              "weeks" -> WeeksFromNow(n)
              "months" -> MonthsFromNow(n)
              "years" -> YearsFromNow(n)
              _ -> DaysFromNow(n)
            }
            return(DateTime(
              year: None, month: None, day: None,
              hour: None, minute: None, second: None,
              relative: Some(rel),
            ))
          })
        })
      })
    }),

    // "in N minutes/hours/days/weeks/months/years"
    do(nibble.token(TokIn), fn(_) {
      do(number(), fn(n) {
        do(nibble.one_of([
          time_unit_minutes() |> nibble.replace("minutes"),
          time_unit_hours() |> nibble.replace("hours"),
          time_unit_days() |> nibble.replace("days"),
          time_unit_weeks() |> nibble.replace("weeks"),
          time_unit_months() |> nibble.replace("months"),
          time_unit_years() |> nibble.replace("years"),
        ]), fn(unit) {
          let rel = case unit {
            "minutes" -> MinutesFromNow(n)
            "hours" -> HoursFromNow(n)
            "days" -> DaysFromNow(n)
            "weeks" -> WeeksFromNow(n)
            "months" -> MonthsFromNow(n)
            "years" -> YearsFromNow(n)
            _ -> DaysFromNow(n)
          }
          return(DateTime(
            year: None, month: None, day: None,
            hour: None, minute: None, second: None,
            relative: Some(rel),
          ))
        })
      })
    }),
  ])
}

/// Parse "this [time of day]": "this morning", "this afternoon"
fn this_time_of_day() -> Parser(DateTime, Token, e) {
  do(nibble.token(TokThis), fn(_) {
    do(time_of_day(), fn(tod) {
      return(combine_date_time(
        DateTime(year: None, month: None, day: None,
                 hour: None, minute: None, second: None,
                 relative: Some(Today)),
        tod
      ))
    })
  })
}

/// Parse "last night"
fn last_night() -> Parser(DateTime, Token, e) {
  do(nibble.token(TokLast), fn(_) {
    do(nibble.token(TokNight), fn(_) {
      return(DateTime(
        year: None, month: None, day: None,
        hour: Some(0), minute: Some(0), second: Some(0),
        relative: Some(Yesterday),
      ))
    })
  })
}

/// Parse "tonight"
fn tonight() -> Parser(DateTime, Token, e) {
  nibble.token(TokTonight) |> nibble.replace(DateTime(
    year: None, month: None, day: None,
    hour: Some(22), minute: Some(0), second: Some(0),
    relative: Some(Today),
  ))
}

/// Combine a date with a time
fn combine_date_time(date: DateTime, time: DateTime) -> DateTime {
  DateTime(
    year: date.year,
    month: date.month,
    day: date.day,
    hour: time.hour,
    minute: time.minute,
    second: time.second,
    relative: date.relative,
  )
}

/// Parse month tokens
fn month() -> Parser(Int, Token, e) {
  nibble.one_of([
    nibble.token(TokJanuary) |> nibble.replace(1),
    nibble.token(TokFebruary) |> nibble.replace(2),
    nibble.token(TokMarch) |> nibble.replace(3),
    nibble.token(TokApril) |> nibble.replace(4),
    nibble.token(TokMay) |> nibble.replace(5),
    nibble.token(TokJune) |> nibble.replace(6),
    nibble.token(TokJuly) |> nibble.replace(7),
    nibble.token(TokAugust) |> nibble.replace(8),
    nibble.token(TokSeptember) |> nibble.replace(9),
    nibble.token(TokOctober) |> nibble.replace(10),
    nibble.token(TokNovember) |> nibble.replace(11),
    nibble.token(TokDecember) |> nibble.replace(12),
  ])
}

/// Parse absolute date: "August 25, 2006" or "August 25"
fn absolute_date() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    // "August 25, 2006"
    do(month(), fn(m) {
      do(number(), fn(day) {
        do(nibble.optional(nibble.token(Comma)), fn(_) {
          do(nibble.optional(number()), fn(maybe_year) {
            return(DateTime(
              year: maybe_year,
              month: Some(m),
              day: Some(day),
              hour: None,
              minute: None,
              second: None,
              relative: None,
            ))
          })
        })
      })
    }),

    // "08/25/2006" or "8/25" (MM/DD or MM/DD/YYYY)
    // Smart UK/GB format detection: if first number > 12, it's DD/MM (UK)
    // Otherwise, assume MM/DD (US) - ambiguous dates like 01/02 default to US
    do(number(), fn(first) {
      do(nibble.token(Slash), fn(_) {
        do(number(), fn(second) {
          do(nibble.optional(nibble.token(Slash)), fn(_) {
            do(nibble.optional(number()), fn(maybe_year) {
              // Smart format detection
              let #(month, day) = case first > 12 {
                True -> #(second, first)  // DD/MM (UK format)
                False -> #(first, second)  // MM/DD (US format)
              }
              return(DateTime(
                year: maybe_year,
                month: Some(month),
                day: Some(day),
                hour: None,
                minute: None,
                second: None,
                relative: None,
              ))
            })
          })
        })
      })
    }),
  ])
}

/// Parse a single point in time (date + optional time)
fn single_point() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    // Special cases first
    last_night(),
    tonight(),
    this_time_of_day(),

    // Relative offsets: "3 days ago", "2 weeks from now"
    do(relative_offset(), fn(date) {
      do(nibble.optional(nibble.token(TokAt)), fn(_) {
        do(nibble.optional(time()), fn(maybe_time) {
          case maybe_time {
            Some(t) -> return(combine_date_time(date, t))
            None -> return(date)
          }
        })
      })
    }),

    // Absolute date with optional time: "August 25 5pm"
    do(absolute_date(), fn(date) {
      do(nibble.optional(nibble.token(TokAt)), fn(_) {
        do(nibble.optional(time()), fn(maybe_time) {
          case maybe_time {
            Some(t) -> return(combine_date_time(date, t))
            None -> return(date)
          }
        })
      })
    }),

    // Date with time: "tomorrow at 5pm", "next tuesday at 5pm"
    do(nibble.one_of([relative_day(), next_weekday(), last_weekday()]), fn(date) {
      do(nibble.optional(nibble.token(TokAt)), fn(_) {
        do(nibble.optional(time()), fn(maybe_time) {
          case maybe_time {
            Some(t) -> return(combine_date_time(date, t))
            None -> return(date)
          }
        })
      })
    }),

    // Standalone weekday: "friday" (implies "next friday")
    do(weekday(), fn(day) {
      do(nibble.optional(nibble.token(TokAt)), fn(_) {
        do(nibble.optional(time()), fn(maybe_time) {
          let base = DateTime(
            year: None, month: None, day: None,
            hour: None, minute: None, second: None,
            relative: Some(NextWeekday(day)),
          )
          case maybe_time {
            Some(t) -> return(combine_date_time(base, t))
            None -> return(base)
          }
        })
      })
    }),

    // Just a time: "5pm" (implies today)
    do(time(), fn(t) {
      return(combine_date_time(
        DateTime(year: None, month: None, day: None,
                 hour: None, minute: None, second: None,
                 relative: Some(Today)),
        t
      ))
    }),
  ])
}

/// Parse multiple points connected by "and": "Tuesday and Thursday at 5pm"
fn multiple_points() -> Parser(List(DateTime), Token, e) {
  // First, try to parse weekdays connected by "and"
  do(weekday(), fn(day1) {
    do(nibble.token(TokAnd), fn(_) {
      do(nibble.many(
        do(nibble.optional(nibble.token(Comma)), fn(_) {
          do(nibble.optional(nibble.token(TokAnd)), fn(_) {
            weekday()
          })
        })
      ), fn(more_days) {
        // Now optionally parse a time that applies to all
        do(nibble.optional(nibble.token(TokAt)), fn(_) {
          do(nibble.optional(time()), fn(maybe_time) {
            let all_days = [day1, ..more_days]
            let dates = list.map(all_days, fn(day) {
              let base = DateTime(
                year: None, month: None, day: None,
                hour: None, minute: None, second: None,
                relative: Some(NextWeekday(day)),
              )
              case maybe_time {
                Some(t) -> combine_date_time(base, t)
                None -> base
              }
            })
            return(dates)
          })
        })
      })
    })
  })
}

/// Parse time ranges like "4-5pm", "8pm-11pm", "10am to noon"
fn time_range() -> Parser(TimeRange, Token, e) {
  nibble.one_of([
    // Pattern: "4-5pm" or "8-11pm" (shared meridiem)
    do(number(), fn(start_hour) {
      do(nibble.token(Dash), fn(_) {
        do(number(), fn(end_hour) {
          do(meridiem(), fn(is_pm) {
            let adjusted_start = case is_pm, start_hour {
              True, h if h < 12 -> h + 12
              True, 12 -> 12
              False, 12 -> 0
              False, h -> h
            }
            let adjusted_end = case is_pm, end_hour {
              True, h if h < 12 -> h + 12
              True, 12 -> 12
              False, 12 -> 0
              False, h -> h
            }
            return(TimeRange(
              start: DateTime(
                year: None, month: None, day: None,
                hour: Some(adjusted_start), minute: Some(0), second: Some(0),
                relative: Some(Today),
              ),
              end: DateTime(
                year: None, month: None, day: None,
                hour: Some(adjusted_end), minute: Some(0), second: Some(0),
                relative: Some(Today),
              ),
            ))
          })
        })
      })
    }),

    // Pattern: "8pm - 11pm" or "10am to 5pm" (separate meridiems)
    do(number(), fn(start_hour) {
      do(meridiem(), fn(start_is_pm) {
        do(nibble.one_of([nibble.token(Dash), nibble.token(TokTo)]), fn(_) {
          do(number(), fn(end_hour) {
            do(meridiem(), fn(end_is_pm) {
              let adjusted_start = case start_is_pm, start_hour {
                True, h if h < 12 -> h + 12
                True, 12 -> 12
                False, 12 -> 0
                False, h -> h
              }
              let adjusted_end = case end_is_pm, end_hour {
                True, h if h < 12 -> h + 12
                True, 12 -> 12
                False, 12 -> 0
                False, h -> h
              }
              return(TimeRange(
                start: DateTime(
                  year: None, month: None, day: None,
                  hour: Some(adjusted_start), minute: Some(0), second: Some(0),
                  relative: Some(Today),
                ),
                end: DateTime(
                  year: None, month: None, day: None,
                  hour: Some(adjusted_end), minute: Some(0), second: Some(0),
                  relative: Some(Today),
                ),
              ))
            })
          })
        })
      })
    }),

    // Pattern: "10am to noon"
    do(time(), fn(start_time) {
      do(nibble.one_of([nibble.token(Dash), nibble.token(TokTo)]), fn(_) {
        do(time(), fn(end_time) {
          return(TimeRange(
            start: combine_date_time(
              DateTime(year: None, month: None, day: None,
                       hour: None, minute: None, second: None,
                       relative: Some(Today)),
              start_time
            ),
            end: combine_date_time(
              DateTime(year: None, month: None, day: None,
                       hour: None, minute: None, second: None,
                       relative: Some(Today)),
              end_time
            ),
          ))
        })
      })
    }),
  ])
}

/// Parse recurrence patterns
fn recurrence_pattern() -> Parser(RecurringEvent, Token, e) {
  nibble.one_of([
    // "every [weekday]" or "every [weekday] and [weekday]"
    do(nibble.token(TokEvery), fn(_) {
      do(weekday(), fn(day1) {
        do(nibble.optional(
          do(nibble.token(TokAnd), fn(_) {
            nibble.many1(
              do(nibble.optional(nibble.token(Comma)), fn(_) {
                do(nibble.optional(nibble.token(TokAnd)), fn(_) {
                  weekday()
                })
              })
            )
          })
        ), fn(maybe_more_days) {
          let all_days = case maybe_more_days {
            Some(more) -> [day1, ..more]
            None -> [day1]
          }
          // Optionally parse time
          do(nibble.optional(nibble.token(TokAt)), fn(_) {
            do(nibble.optional(time()), fn(maybe_time) {
              // Optionally parse "until [date]"
              do(nibble.optional(
                do(nibble.token(TokUntil), fn(_) {
                  single_point()
                })
              ), fn(maybe_until) {
                let base_time = case maybe_time {
                  Some(t) -> t
                  None -> DateTime(
                    year: None, month: None, day: None,
                    hour: None, minute: None, second: None,
                    relative: None,
                  )
                }
                return(RecurringEvent(
                  pattern: EveryWeekday(all_days),
                  time: base_time,
                  until: maybe_until,
                ))
              })
            })
          })
        })
      })
    }),

    // "daily" / "weekly" / "monthly" / "yearly"
    nibble.one_of([
      nibble.token(TokDaily) |> nibble.replace(Daily),
      nibble.token(TokWeekly) |> nibble.replace(Weekly),
      nibble.token(TokMonthly) |> nibble.replace(Monthly),
      nibble.token(TokYearly) |> nibble.replace(Yearly),
    ])
    |> nibble.then(fn(pattern) {
      // Optionally parse time
      do(nibble.optional(nibble.token(TokAt)), fn(_) {
        do(nibble.optional(time()), fn(maybe_time) {
          // Optionally parse "until [date]"
          do(nibble.optional(
            do(nibble.token(TokUntil), fn(_) {
              single_point()
            })
          ), fn(maybe_until) {
            let base_time = case maybe_time {
              Some(t) -> t
              None -> DateTime(
                year: None, month: None, day: None,
                hour: None, minute: None, second: None,
                relative: None,
              )
            }
            return(RecurringEvent(
              pattern: pattern,
              time: base_time,
              until: maybe_until,
            ))
          })
        })
      })
    }),
  ])
}

/// Main parser that handles all cases
/// Helper: wrap a parser to skip unknown tokens before and after
fn extract(parser: Parser(a, Token, e)) -> Parser(a, Token, e) {
  do(skip_unknown(), fn(_) {
    do(parser, fn(result) {
      do(skip_unknown(), fn(_) {
        return(result)
      })
    })
  })
}

fn date_expression() -> Parser(ParsedDate, Token, e) {
  nibble.one_of([
    // Try recurrence patterns first (skip unknown tokens around them)
    extract(recurrence_pattern()) |> nibble.map(Recurring),
    // Try time ranges
    extract(time_range()) |> nibble.map(Range),
    // Try multiple points
    extract(multiple_points()) |> nibble.map(MultiplePoints),
    // Then single point
    extract(single_point()) |> nibble.map(SinglePoint),
  ])
}

// ============================================================================
// PUBLIC API - Parsing
// ============================================================================

/// Parse a natural language date/time string into a structured result.
///
/// This is the main entry point for the library. It accepts any natural language
/// date/time expression and returns a typed representation of what was parsed.
///
/// ## Examples
/// ```gleam
/// parse("tomorrow at 5pm")
/// // => Ok(SinglePoint(DateTime { hour: Some(17), relative: Some(Tomorrow), .. }))
///
/// parse("next Tuesday and Thursday at 3pm")
/// // => Ok(MultiplePoints([DateTime { .. }, DateTime { .. }]))
///
/// parse("Monday 9am-5pm")
/// // => Ok(Range(TimeRange { start: .., end: .. }))
///
/// parse("every Tuesday at 2pm")
/// // => Ok(Recurring(RecurringEvent { .. }))
/// ```
///
/// ## Supported Expressions
/// - **Times**: "5pm", "14:30", "noon", "midnight"
/// - **Relative dates**: "today", "tomorrow", "yesterday", "next Tuesday"
/// - **Specific dates**: "2024-12-25", "December 25", "12/25/2024"
/// - **Ranges**: "9am-5pm", "Monday-Friday", "Dec 1-15"
/// - **Multiple points**: "Tuesday and Thursday", "9am, 2pm, and 5pm"
/// - **Recurring**: "every Monday", "daily at 9am", "every weekday"
/// - **Offsets**: "in 5 minutes", "3 days ago", "2 weeks from now"
///
/// ## Error Handling
/// Returns an error if the input cannot be parsed, with a message describing
/// what went wrong. Common errors include:
/// - Unrecognized date/time format
/// - Invalid number combinations
/// - Incomplete expressions
pub fn parse(input: String) -> Result(ParsedDate, String) {
  let lex = lexer()

  case lexer.run(input, lex) {
    Ok(tokens) -> {
      case nibble.run(tokens, date_expression()) {
        Ok(result) -> Ok(result)
        Error(_) ->
          Error(
            "Could not parse date/time expression. Please check the format and try again.\n"
            <> "Examples: 'tomorrow at 5pm', 'next Tuesday', 'every Monday at 9am'",
          )
      }
    }
    Error(_) ->
      Error(
        "Could not understand the input. Please use common date/time words and numbers.\n"
        <> "Examples: 'tomorrow', '5pm', 'next week', '2024-12-25'",
      )
  }
}

// ============================================================================
// PUBLIC API - Formatting
// ============================================================================

/// Format a DateTime as a human-readable string.
///
/// This function converts a DateTime back into readable text. It handles
/// various combinations of date, time, and relative expressions.
///
/// ## Examples
/// ```gleam
/// format_datetime(time(14, 30))
/// // => "Today at 14:30"
///
/// format_datetime(datetime(2024, 12, 25, 10, 0))
/// // => "2024-12-25 at 10:00"
///
/// format_datetime(relative(Tomorrow))
/// // => "Tomorrow"
/// ```
pub fn format_datetime(dt: DateTime) -> String {
  // Handle relative expressions first
  case dt.relative {
    Some(Today) -> format_time_part(dt) |> prepend_if_present("Today at ")
    Some(Tomorrow) -> format_time_part(dt) |> prepend_if_present("Tomorrow at ")
    Some(Yesterday) ->
      format_time_part(dt) |> prepend_if_present("Yesterday at ")
    Some(NextWeekday(day)) ->
      format_time_part(dt)
      |> prepend_if_present("Next " <> format_weekday(day) <> " at ")
    Some(LastWeekday(day)) ->
      format_time_part(dt)
      |> prepend_if_present("Last " <> format_weekday(day) <> " at ")
    Some(rel) -> format_relative(rel)
    None -> {
      let date_part = format_date_part(dt)
      let time_part = format_time_part(dt)
      case date_part, time_part {
        "", "" -> "(no date/time specified)"
        "", time -> time
        date, "" -> date
        date, time -> date <> " at " <> time
      }
    }
  }
}

/// Format a TimeRange as a human-readable string.
///
/// ## Examples
/// ```gleam
/// format_range(range(time(9, 0), time(17, 0)))
/// // => "Today 9:00 - 17:00"
/// ```
pub fn format_range(tr: TimeRange) -> String {
  format_datetime(tr.start) <> " to " <> format_datetime(tr.end)
}

/// Format a RecurringEvent as a human-readable string.
///
/// ## Examples
/// ```gleam
/// format_recurring_event(daily(time(9, 0)))
/// // => "Daily at 9:00"
///
/// format_recurring_event(every(Monday, time_pm(2, 30)))
/// // => "Every Monday at 14:30"
/// ```
pub fn format_recurring_event(re: RecurringEvent) -> String {
  format_recurring_internal(re)
}

/// Format a ParsedDate as a human-readable string.
///
/// This is a convenience function that formats any ParsedDate variant.
///
/// ## Examples
/// ```gleam
/// format(SinglePoint(time(14, 30)))
/// // => "Today at 14:30"
///
/// format(Range(..))
/// // => "Today 9:00 to 17:00"
/// ```
pub fn format(parsed: ParsedDate) -> String {
  case parsed {
    SinglePoint(dt) -> format_datetime(dt)
    MultiplePoints(dates) ->
      list.map(dates, format_datetime)
      |> string.join(", ")
    Range(tr) -> format_range(tr)
    MultipleRanges(ranges) ->
      list.map(ranges, format_range)
      |> string.join("; ")
    Recurring(re) -> format_recurring_internal(re)
  }
}

// ============================================================================
// FORMATTING HELPERS (Internal)
// ============================================================================

fn format_date_part(dt: DateTime) -> String {
  case dt.year, dt.month, dt.day {
    Some(y), Some(m), Some(d) -> {
      int.to_string(y)
      <> "-"
      <> pad_zero(m)
      <> "-"
      <> pad_zero(d)
    }
    _, Some(m), Some(d) -> int.to_string(m) <> "/" <> int.to_string(d)
    _, _, _ -> ""
  }
}

fn format_time_part(dt: DateTime) -> String {
  case dt.hour, dt.minute {
    Some(h), Some(m) -> int.to_string(h) <> ":" <> pad_zero(m)
    Some(h), None -> int.to_string(h) <> ":00"
    None, _ -> ""
  }
}

fn format_weekday(day: Weekday) -> String {
  case day {
    Monday -> "Monday"
    Tuesday -> "Tuesday"
    Wednesday -> "Wednesday"
    Thursday -> "Thursday"
    Friday -> "Friday"
    Saturday -> "Saturday"
    Sunday -> "Sunday"
  }
}

fn format_relative(rel: RelativeTime) -> String {
  case rel {
    Now -> "Now"
    Today -> "Today"
    Tomorrow -> "Tomorrow"
    Yesterday -> "Yesterday"
    MinutesAgo(n) -> int.to_string(n) <> " minutes ago"
    MinutesFromNow(n) -> "in " <> int.to_string(n) <> " minutes"
    HoursAgo(n) -> int.to_string(n) <> " hours ago"
    HoursFromNow(n) -> "in " <> int.to_string(n) <> " hours"
    DaysAgo(n) -> int.to_string(n) <> " days ago"
    DaysFromNow(n) -> "in " <> int.to_string(n) <> " days"
    WeeksAgo(n) -> int.to_string(n) <> " weeks ago"
    WeeksFromNow(n) -> "in " <> int.to_string(n) <> " weeks"
    MonthsAgo(n) -> int.to_string(n) <> " months ago"
    MonthsFromNow(n) -> "in " <> int.to_string(n) <> " months"
    YearsAgo(n) -> int.to_string(n) <> " years ago"
    YearsFromNow(n) -> "in " <> int.to_string(n) <> " years"
    NextWeekday(day) -> "Next " <> format_weekday(day)
    LastWeekday(day) -> "Last " <> format_weekday(day)
    ThisWeekday(day) -> "This " <> format_weekday(day)
  }
}

fn format_recurring_internal(re: RecurringEvent) -> String {
  let pattern_str = case re.pattern {
    Daily -> "Daily"
    Weekly -> "Weekly"
    Monthly -> "Monthly"
    Yearly -> "Yearly"
    EveryWeekday(days) ->
      "Every "
      <> {
        list.map(days, format_weekday)
        |> string.join(", ")
      }
    EveryNDays(n) -> "Every " <> int.to_string(n) <> " days"
    EveryNWeeks(n) -> "Every " <> int.to_string(n) <> " weeks"
    EveryNMonths(n) -> "Every " <> int.to_string(n) <> " months"
    NthWeekdayOfMonth(n, day) ->
      int.to_string(n) <> "th " <> format_weekday(day) <> " of each month"
  }

  let time_str = case re.time.hour {
    Some(_) -> " at " <> format_time_part(re.time)
    None -> ""
  }

  pattern_str <> time_str
}

fn pad_zero(n: Int) -> String {
  let s = int.to_string(n)
  case string.length(s) {
    1 -> "0" <> s
    _ -> s
  }
}

fn prepend_if_present(suffix: String, prefix: String) -> String {
  case suffix {
    "" -> string.drop_right(prefix, 4)  // Remove " at " if no time
    _ -> prefix <> suffix
  }
}
