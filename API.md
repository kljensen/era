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

Create a time for today.

```gleam
era.time(14, 30)  // Today at 2:30pm
era.time(9, 0)    // Today at 9:00am
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

pub fn main() {
  // Parse various expressions
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

  // Build and validate a custom DateTime
  let my_time = era.time(14, 30)
  case era.validate(my_time) {
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
// Before (verbose)
DateTime(
  year: None,
  month: None,
  day: None,
  hour: Some(14),
  minute: Some(30),
  second: Some(0),
  relative: Some(Today),
)

// After (concise)
era.time(14, 30)
```

All the builder functions are designed to match common use cases and reduce boilerplate.
