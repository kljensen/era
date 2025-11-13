import era.{
  type DateTime, type ParsedDate, type Recurrence, type RecurringEvent,
  type TimeRange, type Weekday, Daily, DateTime, DaysAgo, DaysFromNow,
  EveryWeekday, Friday, HoursAgo, HoursFromNow, MinutesAgo, MinutesFromNow,
  Monday, MultiplePoints, NextWeekday, Range, Recurring, RecurringEvent,
  SinglePoint, Thursday, TimeRange, Today, Tomorrow, Tuesday, Wednesday,
  WeeksAgo, WeeksFromNow, Yesterday,
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
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(12),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
}

pub fn parse_midnight_test() {
  let result = era.parse("midnight")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(0),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
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
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(12),
    minute: Some(0),
    second: Some(0),
    relative: Some(Tomorrow),
  )))
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
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(16))
        tr.end.hour |> should.equal(Some(17))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_10am_to_noon_test() {
  let result = era.parse("10am to noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(12))
      }
      _ -> panic as "Expected Range"
    }
  }
}

// ============================================================================
// RECURRENCE TESTS
// ============================================================================

pub fn parse_every_tuesday_test() {
  let result = era.parse("every tuesday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> days |> should.equal([Tuesday])
          _ -> panic as "Expected EveryWeekday pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_every_tuesday_at_5pm_test() {
  let result = era.parse("every tuesday at 5pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> days |> should.equal([Tuesday])
          _ -> panic as "Expected EveryWeekday pattern"
        }
        re.time.hour |> should.equal(Some(17))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_daily_test() {
  let result = era.parse("daily")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          Daily -> Nil
          _ -> panic as "Expected Daily pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

// ============================================================================
// RELATIVE OFFSET TESTS (from chronic)
// ============================================================================

pub fn parse_3_days_ago_test() {
  let result = era.parse("3 days ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(DaysAgo(3)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_2_weeks_from_now_test() {
  let result = era.parse("2 weeks from now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(WeeksFromNow(2)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// ABSOLUTE DATE TESTS (from parsedatetime)
// ============================================================================

pub fn parse_august_25_2006_test() {
  let result = era.parse("August 25, 2006")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: Some(2006),
    month: Some(8),
    day: Some(25),
    hour: None,
    minute: None,
    second: None,
    relative: None,
  )))
}

pub fn parse_08_25_2006_test() {
  let result = era.parse("08/25/2006")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: Some(2006),
    month: Some(8),
    day: Some(25),
    hour: None,
    minute: None,
    second: None,
    relative: None,
  )))
}

pub fn parse_august_25_5pm_test() {
  let result = era.parse("August 25 5pm")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: Some(8),
    day: Some(25),
    hour: Some(17),
    minute: Some(0),
    second: Some(0),
    relative: None,
  )))
}

// ============================================================================
// TIME OF DAY TESTS (from chrono)
// ============================================================================

pub fn parse_this_morning_test() {
  let result = era.parse("this morning")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(6),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
}

pub fn parse_this_afternoon_test() {
  let result = era.parse("this afternoon")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(15),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
}

pub fn parse_tonight_test() {
  let result = era.parse("tonight")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(22),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
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

// ============================================================================
// ADDITIONAL COMPREHENSIVE TESTS
// ============================================================================

// More time formats
pub fn parse_1am_test() {
  let result = era.parse("1am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(1))
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_12pm_test() {
  let result = era.parse("12pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(12))
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_12am_test() {
  let result = era.parse("12am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(0))
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Weekday abbreviations
pub fn parse_mon_test() {
  let result = era.parse("mon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_next_wed_test() {
  let result = era.parse("next wed")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Wednesday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Multiple weekdays with times
pub fn parse_monday_tuesday_wednesday_at_9am_test() {
  let result = era.parse("Monday and Tuesday and Wednesday at 9am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        // Should have 3 dates
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
            relative: Some(NextWeekday(Tuesday)),
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
        ])
      }
      _ -> panic as "Expected MultiplePoints"
    }
  }
}

// More relative offsets
pub fn parse_1_day_ago_test() {
  let result = era.parse("1 day ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(DaysAgo(1)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_5_weeks_ago_test() {
  let result = era.parse("5 weeks ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(WeeksAgo(5)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// More absolute dates
pub fn parse_january_1_test() {
  let result = era.parse("January 1")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(1))
        dt.day |> should.equal(Some(1))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_dec_25_2024_test() {
  let result = era.parse("Dec 25, 2024")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(12))
        dt.day |> should.equal(Some(25))
        dt.year |> should.equal(Some(2024))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// More recurrence patterns
pub fn parse_weekly_test() {
  let result = era.parse("weekly")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          era.Weekly -> Nil
          _ -> panic as "Expected Weekly pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_every_monday_and_friday_test() {
  let result = era.parse("every Monday and Friday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> {
            days |> should.equal([Monday, Friday])
          }
          _ -> panic as "Expected EveryWeekday pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

// Time ranges with different formats
pub fn parse_8pm_to_11pm_test() {
  let result = era.parse("8pm to 11pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(20))
        tr.end.hour |> should.equal(Some(23))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_9am_to_5pm_test() {
  let result = era.parse("9am to 5pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(9))
        tr.end.hour |> should.equal(Some(17))
      }
      _ -> panic as "Expected Range"
    }
  }
}

// Combined date and time
pub fn parse_next_monday_at_3pm_test() {
  let result = era.parse("next Monday at 3pm")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(15),
    minute: Some(0),
    second: Some(0),
    relative: Some(NextWeekday(Monday)),
  )))
}

pub fn parse_friday_at_noon_test() {
  let result = era.parse("friday at noon")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(12),
    minute: Some(0),
    second: Some(0),
    relative: Some(NextWeekday(Friday)),
  )))
}

// Time with minutes
pub fn parse_2_30pm_test() {
  let result = era.parse("2:30pm")
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

pub fn parse_23_59_test() {
  let result = era.parse("23:59")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(23),
    minute: Some(59),
    second: Some(0),
    relative: Some(Today),
  )))
}

// ============================================================================
// FINE-GRAINED TIME UNIT TESTS (minutes and hours)
// ============================================================================

pub fn parse_30_minutes_ago_test() {
  let result = era.parse("30 minutes ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesAgo(30)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_15_minutes_test() {
  let result = era.parse("in 15 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(15)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_2_hours_ago_test() {
  let result = era.parse("2 hours ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(HoursAgo(2)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_3_hours_test() {
  let result = era.parse("in 3 hours")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(HoursFromNow(3)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_1_hour_ago_test() {
  let result = era.parse("1 hour ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(HoursAgo(1)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// HH:MM:SS TIME FORMAT TESTS
// ============================================================================

pub fn parse_14_30_45_test() {
  let result = era.parse("14:30:45")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(14),
    minute: Some(30),
    second: Some(45),
    relative: Some(Today),
  )))
}

pub fn parse_3_45_30_pm_test() {
  let result = era.parse("3:45:30 PM")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(15),
    minute: Some(45),
    second: Some(30),
    relative: Some(Today),
  )))
}

pub fn parse_12_00_00_am_test() {
  let result = era.parse("12:00:00 am")
  result
  |> should.be_ok
  |> should.equal(SinglePoint(DateTime(
    year: None,
    month: None,
    day: None,
    hour: Some(0),
    minute: Some(0),
    second: Some(0),
    relative: Some(Today),
  )))
}

// ============================================================================
// "IN N DAYS" SYNTAX TESTS
// ============================================================================

pub fn parse_in_3_days_test() {
  let result = era.parse("in 3 days")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(DaysFromNow(3)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_2_weeks_test() {
  let result = era.parse("in 2 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(WeeksFromNow(2)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_1_month_test() {
  let result = era.parse("in 1 month")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.MonthsFromNow(1)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}
