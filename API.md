# Era API Reference

## Overview

Era is a natural language date/time parser for Gleam. It converts human-readable date/time expressions into strongly-typed results using parser combinators.

## Core Types

### ParsedDate

The main result type representing what was parsed:

```gleam
pub type ParsedDate {
  SinglePoint(DateTime)          // "tomorrow at 5pm"
  MultiplePoints(List(DateTime)) // "Tuesday and Thursday at 3pm"
  Range(TimeRange)                // "Monday 9am-5pm"
  MultipleRanges(List(TimeRange)) // "Mon-Wed 9-5 and Fri 10-4"
  Recurring(RecurringEvent)       // "every Tuesday at 2pm"
}
```

### DateTime

Represents a point in time with optional components:

```gleam
pub type DateTime {
  DateTime(
    year: Option(Int),
    month: Option(Int),
    day: Option(Int),
    hour: Option(Int),
    minute: Option(Int),
    second: Option(Int),
    relative: Option(RelativeTime),
  )
}
```

## Main API Functions

### parse(String) -> Result(ParsedDate, String)

Parse a natural language date/time expression.

**Examples:**

```gleam
era.parse("5pm")
// => Ok(SinglePoint(DateTime { hour: Some(17), .. }))

era.parse("next Tuesday and Thursday at 3pm")
// => Ok(MultiplePoints([..]))

era.parse("Monday 9am-5pm")
// => Ok(Range(..))

era.parse("every Monday at 9am")
// => Ok(Recurring(..))
```

**Supported Expressions:**
- Times: "5pm", "14:30", "noon", "midnight"
- Relative dates: "today", "tomorrow", "yesterday", "next Tuesday"
- Specific dates: "2024-12-25", "December 25", "12/25/2024"
- Ranges: "9am-5pm", "Monday-Friday", "Dec 1-15"
- Multiple points: "Tuesday and Thursday", "9am, 2pm, and 5pm"
- Recurring: "every Monday", "daily at 9am", "every weekday"
- Offsets: "in 5 minutes", "3 days ago", "2 weeks from now"

## Builder Functions

Instead of constructing DateTime values manually, use these helpers:

### time(Int, Int) -> DateTime

Create a time for today (24-hour format).

```gleam
era.time(14, 30)  // Today at 2:30pm
era.time(9, 0)    // Today at 9:00am
```

### time_pm(Int, Int) -> DateTime

Create a time for today in PM (12-hour format).

```gleam
era.time_pm(5, 30)   // Today at 5:30pm (17:30)
era.time_pm(12, 0)   // Today at noon (12:00)
era.time_pm(1, 15)   // Today at 1:15pm (13:15)
```

### time_am(Int, Int) -> DateTime

Create a time for today in AM (12-hour format).

```gleam
era.time_am(9, 0)    // Today at 9:00am
era.time_am(12, 0)   // Today at midnight (00:00)
era.time_am(6, 30)   // Today at 6:30am
```

### date(Int, Int, Int) -> DateTime

Create a date without time.

```gleam
era.date(2024, 12, 25)  // Christmas 2024
era.date(2025, 1, 1)    // New Year's Day 2025
```

### datetime(Int, Int, Int, Int, Int) -> DateTime

Create a full date and time.

```gleam
era.datetime(2024, 12, 25, 10, 30)  // Christmas 2024 at 10:30am
```

### relative(RelativeTime) -> DateTime

Create a relative time expression.

```gleam
era.relative(era.Tomorrow)              // Tomorrow
era.relative(era.NextWeekday(era.Monday))  // Next Monday
```

### relative_time(RelativeTime, Int, Int) -> DateTime

Create a relative time with specific time of day.

```gleam
era.relative_time(era.Tomorrow, 14, 30)  // Tomorrow at 2:30pm
era.relative_time(era.NextWeekday(era.Friday), 9, 0)  // Next Friday at 9am
```

### range(DateTime, DateTime) -> TimeRange

Create a time range.

```gleam
era.range(era.time(9, 0), era.time(17, 0))  // 9am to 5pm today
```

## Ergonomic Helpers

These convenience functions make common tasks simple and intuitive:

### Simple Relative Times

```gleam
era.now()        // Current moment
era.today()      // Today
era.tomorrow()   // Tomorrow
era.yesterday()  // Yesterday
```

### Tomorrow With Time

```gleam
era.tomorrow_at(14, 30)        // Tomorrow at 2:30pm (24-hour)
era.tomorrow_at_pm(5, 30)      // Tomorrow at 5:30pm
era.tomorrow_at_am(9, 0)       // Tomorrow at 9:00am
```

### Common Times

```gleam
era.noon()       // Today at 12:00pm
era.midnight()   // Today at 00:00
```

### Weekday Helpers

Get the next or last occurrence of a weekday:

```gleam
era.next(era.Monday)           // Next Monday
era.next_at(era.Monday, 9, 0)  // Next Monday at 9am
era.last(era.Friday)           // Last Friday
era.last_at(era.Friday, 17, 0) // Last Friday at 5pm
```

### Specific Weekday Functions

For better discoverability, each weekday has dedicated functions:

```gleam
// Next occurrence
era.next_monday()
era.next_tuesday()
era.next_wednesday()
era.next_thursday()
era.next_friday()
era.next_saturday()
era.next_sunday()

// Next occurrence at specific time
era.next_monday_at(9, 0)
era.next_tuesday_at(14, 30)
era.next_wednesday_at(10, 0)
// ... and so on for all weekdays

// Last occurrence
era.last_monday()
era.last_tuesday()
// ... and so on

// Last occurrence at specific time
era.last_monday_at(17, 0)
era.last_tuesday_at(15, 30)
// ... and so on
```

### Time Offset Helpers

Create times relative to now:

```gleam
// Future
era.in_minutes(30)    // 30 minutes from now
era.in_hours(2)       // 2 hours from now
era.in_days(3)        // 3 days from now
era.in_weeks(2)       // 2 weeks from now
era.in_months(6)      // 6 months from now
era.in_years(1)       // 1 year from now

// Past
era.ago_minutes(15)   // 15 minutes ago
era.ago_hours(3)      // 3 hours ago
era.ago_days(7)       // 7 days ago (last week)
era.ago_weeks(4)      // 4 weeks ago
era.ago_months(2)     // 2 months ago
era.ago_years(5)      // 5 years ago
```

## Inspection Functions

### is_single_point(ParsedDate) -> Bool

Check if the result is a single point in time.

```gleam
era.is_single_point(SinglePoint(..))  // True
era.is_single_point(Range(..))        // False
```

### is_multiple_points(ParsedDate) -> Bool

Check if the result represents multiple points.

### is_range(ParsedDate) -> Bool

Check if the result is a time range.

### is_recurring(ParsedDate) -> Bool

Check if the result is a recurring event.

### describe(ParsedDate) -> String

Get a human-readable description of the result type.

```gleam
era.describe(SinglePoint(..))   // "single point in time"
era.describe(MultiplePoints([a, b, c]))  // "3 points in time"
era.describe(Range(..))         // "time range"
era.describe(Recurring(..))     // "recurring event"
```

## Extraction Functions

### to_single_point(ParsedDate) -> Result(DateTime, String)

Extract the DateTime if it's a SinglePoint.

```gleam
let assert Ok(result) = era.parse("5pm")
let assert Ok(dt) = era.to_single_point(result)
// dt is the DateTime
```

### to_multiple_points(ParsedDate) -> Result(List(DateTime), String)

Extract the list of DateTimes if it's MultiplePoints.

### to_range(ParsedDate) -> Result(TimeRange, String)

Extract the TimeRange if it's a Range.

### to_recurring(ParsedDate) -> Result(RecurringEvent, String)

Extract the RecurringEvent if it's Recurring.

## Formatting Functions

### format(ParsedDate) -> String

Format any ParsedDate back to readable text.

```gleam
let assert Ok(result) = era.parse("tomorrow at 5pm")
era.format(result)
// => "Tomorrow at 17:00"

let assert Ok(result) = era.parse("Monday 9am-5pm")
era.format(result)
// => "Next Monday 9:00 to Next Monday 17:00"
```

### format_datetime(DateTime) -> String

Format a DateTime as readable text.

```gleam
era.format_datetime(era.time(14, 30))
// => "Today at 14:30"

era.format_datetime(era.datetime(2024, 12, 25, 10, 0))
// => "2024-12-25 at 10:00"

era.format_datetime(era.relative(era.Tomorrow))
// => "Tomorrow"
```

### format_range(TimeRange) -> String

Format a TimeRange as readable text.

```gleam
era.format_range(era.range(era.time(9, 0), era.time(17, 0)))
// => "Today 9:00 to Today 17:00"
```

## Validation Functions

### validate(DateTime) -> Result(DateTime, String)

Validate that a DateTime has reasonable values.

Checks:
- Month: 1-12
- Day: 1-31
- Hour: 0-23
- Minute: 0-59
- Second: 0-59

```gleam
era.validate(era.time(14, 30))
// => Ok(DateTime { .. })

era.validate(era.time(25, 0))
// => Error("Hour must be 0-23, got 25")

era.validate(era.date(2024, 13, 1))
// => Error("Month must be 1-12, got 13")
```

### has_time(DateTime) -> Bool

Check if a DateTime has a time component.

```gleam
era.has_time(era.time(14, 30))        // True
era.has_time(era.date(2024, 12, 25))  // False
```

### has_date(DateTime) -> Bool

Check if a DateTime has a date component.

```gleam
era.has_date(era.date(2024, 12, 25))  // True
era.has_date(era.time(14, 30))        // False
```

### is_complete(DateTime) -> Bool

Check if a DateTime has both date and time.

```gleam
era.is_complete(era.datetime(2024, 12, 25, 14, 30))  // True
era.is_complete(era.time(14, 30))                     // False
era.is_complete(era.date(2024, 12, 25))               // False
```

### is_relative(DateTime) -> Bool

Check if a DateTime represents a relative expression.

```gleam
era.is_relative(era.relative(era.Tomorrow))  // True
era.is_relative(era.date(2024, 12, 25))      // False
```

## Complete Example

```gleam
import era
import gleam/io
import gleam/list

pub fn main() {
  // Parse natural language expressions
  let examples = [
    "tomorrow at 5pm",
    "next Tuesday and Thursday at 3pm",
    "every Monday at 9am",
    "Monday 9am-5pm",
    "in 3 days",
  ]

  examples
  |> list.each(fn(input) {
    case era.parse(input) {
      Ok(result) -> {
        io.println("Input: " <> input)
        io.println("Type: " <> era.describe(result))
        io.println("Formatted: " <> era.format(result))
        io.println("")
      }
      Error(msg) -> {
        io.println("Error parsing '" <> input <> "': " <> msg)
      }
    }
  })

  // Use ergonomic builder functions (no parsing needed!)
  let meeting = era.next_monday_at(14, 30)
  io.println("Next meeting: " <> era.format_datetime(meeting))

  let deadline = era.in_days(7)
  io.println("Deadline: " <> era.format_datetime(deadline))

  let lunch = era.tomorrow_at_pm(12, 0)
  io.println("Lunch: " <> era.format_datetime(lunch))

  // Create ranges easily
  let work_hours = era.range(
    era.time_am(9, 0),
    era.time_pm(5, 0)
  )
  io.println("Work hours: " <> era.format_range(work_hours))

  // Validate if needed
  let custom_time = era.time_pm(2, 30)
  case era.validate(custom_time) {
    Ok(dt) -> {
      io.println("Valid time: " <> era.format_datetime(dt))
    }
    Error(msg) -> {
      io.println("Invalid: " <> msg)
    }
  }
}
```

## Error Handling

The `parse()` function returns helpful error messages:

```gleam
case era.parse(some_input) {
  Ok(result) -> {
    // Handle successful parse
    case result {
      SinglePoint(dt) -> // ...
      MultiplePoints(dates) -> // ...
      Range(tr) -> // ...
      Recurring(re) -> // ...
    }
  }
  Error(msg) -> {
    // msg contains a human-readable error message with examples
    io.println_error(msg)
  }
}
```

## Performance Tips

1. **Reuse results**: The parse operation is relatively expensive. Cache results when possible.

2. **Use builders**: The helper functions like `time()`, `date()`, etc. are much faster than parsing strings.

3. **Validate once**: Call `validate()` only when you need to ensure correctness, not on every operation.

4. **Pattern match directly**: When you know the expected result type, pattern match directly instead of using extraction functions:

```gleam
// Good
case era.parse("5pm") {
  Ok(SinglePoint(dt)) -> // work with dt directly
  _ -> // handle other cases
}

// Less efficient
let assert Ok(result) = era.parse("5pm")
let assert Ok(dt) = era.to_single_point(result)
```

## Migration from Raw Constructors

If you were previously constructing DateTime values manually:

```gleam
// Before (very verbose)
DateTime(
  year: None,
  month: None,
  day: None,
  hour: Some(14),
  minute: Some(30),
  second: Some(0),
  relative: Some(Today),
)

// After with builders (concise)
era.time(14, 30)

// Even better with AM/PM helpers (most intuitive)
era.time_pm(2, 30)
```

Similarly for relative times:

```gleam
// Before (verbose)
era.relative(Tomorrow)
era.relative_time(NextWeekday(Monday), 9, 0)

// After with ergonomic helpers (simple)
era.tomorrow()
era.next_monday_at(9, 0)
```

All the builder and helper functions are designed to match common use cases and reduce boilerplate while improving readability.
