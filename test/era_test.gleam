import era.{
  type DateTime, type ParsedDate, type RelativeTime, type Weekday, DateTime,
  Friday, Monday, MultiplePoints, NextWeekday, SinglePoint, Thursday, Today,
  Tomorrow, Tuesday, Wednesday, Yesterday,
}
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

// ============================================================================
// SIMPLE TIME PARSING TESTS
// ============================================================================

pub fn parse_5pm_test() {
  let result = era.parse("5pm")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(17),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
}

pub fn parse_14_30_test() {
  let result = era.parse("14:30")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(14),
    minute: Some(30),
    second: Some(0),
    relative: Some(Today),
  )))
}

pub fn parse_3_45_pm_test() {
  let result = era.parse("3:45 PM")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(15),
    minute: Some(45),
    second: Some(0),
    relative: Some(Today),
  )))
}

pub fn parse_noon_test() {
  let result = era.parse("noon")
  // TODO: Implement noon parser
  result |> should.be_error
}

pub fn parse_midnight_test() {
  let result = era.parse("midnight")
  // TODO: Implement midnight parser
  result |> should.be_error
}

// ============================================================================
// RELATIVE DAY TESTS (from chrono)
// ============================================================================

pub fn parse_now_test() {
  let result = era.parse("now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.Now))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_today_test() {
  let result = era.parse("today")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: None,
    minute: None,
    second: None,
    relative: Some(Today),
  )))
}

pub fn parse_tomorrow_test() {
  let result = era.parse("tomorrow")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: None,
    minute: None,
    second: None,
    relative: Some(Tomorrow),
  )))
}

pub fn parse_yesterday_test() {
  let result = era.parse("yesterday")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: None,
    minute: None,
    second: None,
    relative: Some(Yesterday),
  )))
}

// ============================================================================
// DAY + TIME COMBINATIONS (from chrono)
// ============================================================================

pub fn parse_today_5pm_test() {
  let result = era.parse("today 5PM")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(17),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
}

pub fn parse_tomorrow_at_noon_test() {
  let result = era.parse("Tomorrow at noon")
  // TODO: Implement noon parser
  result |> should.be_error
}

pub fn parse_tomorrow_at_5pm_test() {
  let result = era.parse("tomorrow at 5pm")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(17),
    minute: Some(0),
    second: Some(0),
    relative: Some(Tomorrow),
  )))
}

// ============================================================================
// WEEKDAY TESTS (from chronic)
// ============================================================================

pub fn parse_friday_test() {
  let result = era.parse("friday")
  // Should parse as "next Friday"
  result |> should.be_error  // Not yet implemented without "next"
}

pub fn parse_next_friday_test() {
  let result = era.parse("next friday")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: None,
    minute: None,
    second: None,
    relative: Some(NextWeekday(Friday)),
  )))
}

pub fn parse_last_monday_test() {
  let result = era.parse("last monday")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: None,
    minute: None,
    second: None,
    relative: Some(era.LastWeekday(Monday)),
  )))
}

pub fn parse_next_tuesday_at_5pm_test() {
  let result = era.parse("next Tuesday at 5pm")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(17),
    minute: Some(0),
    second: Some(0),
    relative: Some(NextWeekday(Tuesday)),
  )))
}

// ============================================================================
// MULTIPLE POINTS TESTS (the key feature!)
// ============================================================================

pub fn parse_tuesday_and_thursday_test() {
  let result = era.parse("Tuesday and Thursday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates
        |> should.equal([
          DateTime(
            year: None,
            month: None,
            day: None,
            hour: None,
            minute: None,
            second: None,
            relative: Some(NextWeekday(Tuesday)),
          ),
          DateTime(
            year: None,
            month: None,
            day: None,
            hour: None,
            minute: None,
            second: None,
            relative: Some(NextWeekday(Thursday)),
          ),
        ])
      }
      _ -> panic as "Expected MultiplePoints"
    }
  }
}

pub fn parse_tuesday_and_thursday_at_5pm_test() {
  let result = era.parse("Tuesday and Thursday at 5pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates
        |> should.equal([
          DateTime(
            year: None,
            month: None,
            day: None,
            hour: Some(17),
            minute: Some(0),
            second: Some(0),
            relative: Some(NextWeekday(Tuesday)),
          ),
          DateTime(
            year: None,
            month: None,
            day: None,
            hour: Some(17),
            minute: Some(0),
            second: Some(0),
            relative: Some(NextWeekday(Thursday)),
          ),
        ])
      }
      _ -> panic as "Expected MultiplePoints"
    }
  }
}

pub fn parse_monday_wednesday_friday_test() {
  let result = era.parse("Monday and Wednesday and Friday at 9am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates
        |> should.equal([
          DateTime(
            year: None,
            month: None,
            day: None,
            hour: Some(9),
            minute: Some(0),
            second: Some(0),
            relative: Some(NextWeekday(Monday)),
          ),
          DateTime(
            year: None,
            month: None,
            day: None,
            hour: Some(9),
            minute: Some(0),
            second: Some(0),
            relative: Some(NextWeekday(Wednesday)),
          ),
          DateTime(
            year: None,
            month: None,
            day: None,
            hour: Some(9),
            minute: Some(0),
            second: Some(0),
            relative: Some(NextWeekday(Friday)),
          ),
        ])
      }
      _ -> panic as "Expected MultiplePoints"
    }
  }
}

// ============================================================================
// TIME RANGE TESTS (from chrono)
// ============================================================================

pub fn parse_4_to_5pm_test() {
  let result = era.parse("4-5pm")
  // TODO: Implement time ranges
  result |> should.be_error
}

pub fn parse_10am_to_noon_test() {
  let result = era.parse("10am to noon")
  // TODO: Implement time ranges
  result |> should.be_error
}

// ============================================================================
// RECURRENCE TESTS
// ============================================================================

pub fn parse_every_tuesday_test() {
  let result = era.parse("every tuesday")
  // TODO: Implement recurrence parsing
  result |> should.be_error
}

pub fn parse_every_tuesday_at_5pm_test() {
  let result = era.parse("every tuesday at 5pm")
  // TODO: Implement recurrence parsing
  result |> should.be_error
}

pub fn parse_daily_test() {
  let result = era.parse("daily")
  // TODO: Implement recurrence parsing
  result |> should.be_error
}

// ============================================================================
// RELATIVE OFFSET TESTS (from chronic)
// ============================================================================

pub fn parse_3_days_ago_test() {
  let result = era.parse("3 days ago")
  // TODO: Implement relative offset parsing
  result |> should.be_error
}

pub fn parse_2_weeks_from_now_test() {
  let result = era.parse("2 weeks from now")
  // TODO: Implement relative offset parsing
  result |> should.be_error
}

// ============================================================================
// ABSOLUTE DATE TESTS (from parsedatetime)
// ============================================================================

pub fn parse_august_25_2006_test() {
  let result = era.parse("August 25, 2006")
  // TODO: Implement absolute date parsing
  result |> should.be_error
}

pub fn parse_08_25_2006_test() {
  let result = era.parse("08/25/2006")
  // TODO: Implement absolute date parsing
  result |> should.be_error
}

pub fn parse_august_25_5pm_test() {
  let result = era.parse("August 25 5pm")
  // TODO: Implement absolute date + time parsing
  result |> should.be_error
}

// ============================================================================
// TIME OF DAY TESTS (from chrono)
// ============================================================================

pub fn parse_this_morning_test() {
  let result = era.parse("this morning")
  // TODO: Implement time of day parsing
  result |> should.be_error
}

pub fn parse_this_afternoon_test() {
  let result = era.parse("this afternoon")
  // TODO: Implement time of day parsing
  result |> should.be_error
}

pub fn parse_tonight_test() {
  let result = era.parse("tonight")
  // TODO: Implement time of day parsing
  result |> should.be_error
}

// ============================================================================
// EDGE CASES AND NEGATIVE TESTS
// ============================================================================

pub fn parse_empty_string_test() {
  let result = era.parse("")
  result |> should.be_error
}

pub fn parse_invalid_input_test() {
  let result = era.parse("xyzabc123")
  result |> should.be_error
}

pub fn parse_partial_word_test() {
  // From chrono: these should NOT parse
  let result = era.parse("notoday")
  result |> should.be_error
}
