// Era: A rigorous natural date/time parser using parser combinators
//
// This library parses natural language date/time expressions and returns
// strongly-typed results representing:
// - Single points in time: "next Tuesday at 5pm"
// - Multiple points in time: "Tuesday and Thursday at 5pm"
// - Time ranges: "Tuesday 4-5pm"
// - Recurrent events: "every Tuesday at 5pm"
// - Recurrent events with multiple days: "every Monday and Wednesday at 5pm"

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

/// Represents a specific point in time
pub type DateTime {
  DateTime(
    year: Option(Int),
    month: Option(Int),
    day: Option(Int),
    hour: Option(Int),
    minute: Option(Int),
    second: Option(Int),
    // For relative dates, we need to know the relationship to "now"
    relative: Option(RelativeTime),
  )
}

/// Relative time expressions
pub type RelativeTime {
  Now
  Today
  Tomorrow
  Yesterday
  // Relative offsets
  DaysAgo(Int)
  DaysFromNow(Int)
  WeeksAgo(Int)
  WeeksFromNow(Int)
  MonthsAgo(Int)
  MonthsFromNow(Int)
  YearsAgo(Int)
  YearsFromNow(Int)
  // Day of week relative
  NextWeekday(Weekday)
  LastWeekday(Weekday)
  ThisWeekday(Weekday)
}

/// Days of the week
pub type Weekday {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
}

/// Time of day descriptors
pub type TimeOfDay {
  Morning    // ~6am
  Afternoon  // ~3pm
  Evening    // ~8pm
  Night      // ~10pm
  Noon       // 12pm
  Midnight   // 12am
}

/// A time range has a start and end
pub type TimeRange {
  TimeRange(start: DateTime, end: DateTime)
}

/// Recurrence patterns
pub type Recurrence {
  // Simple patterns
  Daily
  Weekly
  Monthly
  Yearly
  // Specific day patterns
  EveryWeekday(weekdays: List(Weekday))
  // Interval patterns
  EveryNDays(n: Int)
  EveryNWeeks(n: Int)
  EveryNMonths(n: Int)
  // Ordinal patterns like "2nd Tuesday of each month"
  NthWeekdayOfMonth(n: Int, weekday: Weekday)
}

/// A recurring event combines a recurrence pattern with a time/date template
pub type RecurringEvent {
  RecurringEvent(
    pattern: Recurrence,
    time: DateTime,
    until: Option(DateTime),  // Optional end date
  )
}

/// The main result type: what we parsed from the input
pub type ParsedDate {
  // Single point in time
  SinglePoint(DateTime)
  // Multiple discrete points
  MultiplePoints(List(DateTime))
  // A continuous range
  Range(TimeRange)
  // Multiple ranges
  MultipleRanges(List(TimeRange))
  // A recurring event
  Recurring(RecurringEvent)
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
pub fn lexer() -> lexer.Lexer(Token, Nil) {
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
  ])
  |> lexer.ignore(whitespace)
}

// ============================================================================
// PARSER COMBINATORS
// ============================================================================

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

/// Parse a time like "5pm", "14:30", "3:45:30 PM"
fn time() -> Parser(DateTime, Token, e) {
  nibble.one_of([
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

/// Parse a single point in time (date + optional time)
fn single_point() -> Parser(DateTime, Token, e) {
  nibble.one_of([
    // Date with time: "tomorrow at 5pm"
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

/// Main parser that handles all cases
fn date_expression() -> Parser(ParsedDate, Token, e) {
  nibble.one_of([
    // Try multiple points first
    multiple_points() |> nibble.map(MultiplePoints),
    // Then single point
    single_point() |> nibble.map(SinglePoint),
  ])
}

// ============================================================================
// PUBLIC API
// ============================================================================

/// Parse a natural language date/time string
pub fn parse(input: String) -> Result(ParsedDate, String) {
  let lex = lexer()

  case lexer.run(input, lex) {
    Ok(tokens) -> {
      case nibble.run(tokens, date_expression()) {
        Ok(result) -> Ok(result)
        Error(e) -> Error("Parse error: " <> string.inspect(e))
      }
    }
    Error(e) -> Error("Lexer error: " <> string.inspect(e))
  }
}

/// Helper to format a DateTime for display
pub fn format_datetime(dt: DateTime) -> String {
  let year_str = case dt.year {
    Some(y) -> int.to_string(y)
    None -> "????"
  }
  let month_str = case dt.month {
    Some(m) -> int.to_string(m)
    None -> "??"
  }
  let day_str = case dt.day {
    Some(d) -> int.to_string(d)
    None -> "??"
  }
  let hour_str = case dt.hour {
    Some(h) -> int.to_string(h)
    None -> "??"
  }
  let minute_str = case dt.minute {
    Some(m) -> {
      let s = int.to_string(m)
      case string.length(s) {
        1 -> "0" <> s
        _ -> s
      }
    }
    None -> "??"
  }

  let date_part = year_str <> "-" <> month_str <> "-" <> day_str
  let time_part = hour_str <> ":" <> minute_str

  case dt.relative {
    Some(rel) -> date_part <> " " <> time_part <> " (" <> string.inspect(rel) <> ")"
    None -> date_part <> " " <> time_part
  }
}

pub fn main() -> Nil {
  // This will be filled in with examples
  todo as "main function not yet implemented"
}
