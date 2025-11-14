# era

**A natural language date/time parser for Gleam**

[![Package Version](https://img.shields.io/hexpm/v/era)](https://hex.pm/packages/era)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/era/)

Parse human-friendly date and time expressions into type-safe results.

```gleam
import era

// Parse natural language
era.parse("tomorrow at 5pm")
era.parse("next Tuesday and Thursday")
era.parse("every Monday at 9am")
era.parse("in 3 days")

// Or build programmatically
era.tomorrow_at_pm(5, 0)
era.next_monday()
era.in_days(3)
era.daily(era.time(9, 0))
```

## Features

- **Natural language parsing** — "tomorrow at 5pm", "next Tuesday", "in 3 days"
- **Multiple expression types** — Single times, ranges, multiple points, recurring events
- **Type-safe results** — Pattern match on `ParsedDate` variants
- **Ergonomic builders** — 70+ helper functions for common patterns
- **Parser combinators** — Built with [nibble](https://github.com/hayleigh-dot-dev/nibble), not regex
- **Thoroughly tested** — 690+ tests from real-world usage

## Installation

```sh
gleam add era
```

## Quick Start

```gleam
import era
import gleam/io

pub fn main() {
  // Parse and inspect
  case era.parse("tomorrow at 5pm") {
    Ok(result) -> {
      io.println(era.describe(result))
      // => "single point in time"

      io.println(era.format(result))
      // => "Tomorrow at 17:00"
    }
    Error(msg) -> io.println("Error: " <> msg)
  }

  // Use ergonomic builders
  let meeting = era.next_monday_at(14, 30)
  let daily_standup = era.daily(era.time(9, 0))
  let work_week = era.every_weekday(era.weekdays, era.time_am(9, 0))
}
```

## What You Can Parse

**Times**
```gleam
era.parse("5pm")              // => Ok(SinglePoint(...))
era.parse("14:30")            // => Ok(SinglePoint(...))
era.parse("noon")             // => Ok(SinglePoint(...))
```

**Relative Dates**
```gleam
era.parse("tomorrow")         // => Ok(SinglePoint(...))
era.parse("next Tuesday")     // => Ok(SinglePoint(...))
era.parse("in 3 days")        // => Ok(SinglePoint(...))
era.parse("2 weeks ago")      // => Ok(SinglePoint(...))
```

**Ranges**
```gleam
era.parse("9am-5pm")          // => Ok(Range(...))
era.parse("Monday to Friday") // => Ok(Range(...))
```

**Multiple Points**
```gleam
era.parse("Tuesday and Thursday at 3pm")  // => Ok(MultiplePoints(...))
era.parse("9am, 2pm, and 5pm")            // => Ok(MultiplePoints(...))
```

**Recurring Events**
```gleam
era.parse("every Monday at 9am")          // => Ok(Recurring(...))
era.parse("daily at 10am")                // => Ok(Recurring(...))
era.parse("every Tuesday and Thursday")   // => Ok(Recurring(...))
```

## Programmatic Building

Instead of parsing strings, you can build date/time values directly:

```gleam
// Times with AM/PM support
era.time_pm(5, 30)        // Today at 5:30pm
era.noon()                // Today at 12:00pm

// Relative times
era.tomorrow()            // Tomorrow
era.next_monday()         // Next Monday
era.next_friday_at(17, 0) // Next Friday at 5pm
era.in_days(3)            // 3 days from now
era.ago_hours(2)          // 2 hours ago

// Recurring events
era.daily(era.time(9, 0))                    // Every day at 9am
era.every(Monday, era.time_pm(2, 0))         // Every Monday at 2pm
era.every_weekday(era.weekdays, era.time(9, 0))  // Every weekday at 9am
```

See the [full API documentation](https://hexdocs.pm/era/) for all 70+ helper functions.

## Working with Results

Pattern match on `ParsedDate` to handle different types:

```gleam
case era.parse(input) {
  Ok(SinglePoint(dt)) -> // Handle single date/time
  Ok(Range(time_range)) -> // Handle range
  Ok(MultiplePoints(dates)) -> // Handle list of times
  Ok(Recurring(event)) -> // Handle recurring pattern
  Error(msg) -> // Handle parse error
}
```

Or use inspection functions:

```gleam
let result = era.parse("5pm")
era.is_single_point(result)  // => True
era.describe(result)         // => "single point in time"

// Extract values
let assert Ok(dt) = era.to_single_point(result)
era.format_datetime(dt)      // => "Today at 17:00"
```

## Development

```sh
gleam test  # Run 690+ tests
gleam build
```

## Documentation

Complete API documentation with examples: <https://hexdocs.pm/era>

## License

Apache 2.0

## Inspiration

Era draws inspiration from natural language date parsing libraries across ecosystems:
- [chrono](https://github.com/wanasit/chrono) (JavaScript) — The original inspiration
- [chronic](https://github.com/mojombo/chronic) (Ruby) — Elegant natural language parsing
- [dateparser](https://github.com/scrapinghub/dateparser) (Python) — Comprehensive multi-locale support
- [kronos](https://github.com/kljensen/kronos) (Go) — Context-aware parsing

Built with [nibble](https://github.com/hayleigh-dot-dev/nibble) parser combinators for Gleam.
