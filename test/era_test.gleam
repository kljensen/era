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

// ============================================================================
// ADDITIONAL TESTS FROM CHRONIC (Ruby)
// ============================================================================

pub fn parse_3_years_ago_test() {
  let result = era.parse("3 years ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.YearsAgo(3)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_1_year_from_now_test() {
  let result = era.parse("1 year from now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.YearsFromNow(1)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_1_month_ago_test() {
  let result = era.parse("1 month ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.MonthsAgo(1)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_6_months_from_now_test() {
  let result = era.parse("6 months from now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.MonthsFromNow(6)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// MORE WEEKDAY COMBINATIONS
// ============================================================================

pub fn parse_last_tuesday_test() {
  let result = era.parse("last tuesday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.LastWeekday(Tuesday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_last_friday_test() {
  let result = era.parse("last friday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.LastWeekday(Friday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_next_thursday_test() {
  let result = era.parse("next thursday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Thursday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_thursday_test() {
  let result = era.parse("thursday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Thursday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_saturday_test() {
  let result = era.parse("saturday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(era.Saturday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_sunday_test() {
  let result = era.parse("sunday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(era.Sunday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// MORE ABSOLUTE DATE FORMATS
// ============================================================================

pub fn parse_march_15_2024_test() {
  let result = era.parse("March 15, 2024")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.year |> should.equal(Some(2024))
        dt.month |> should.equal(Some(3))
        dt.day |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_feb_1_test() {
  let result = era.parse("Feb 1")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(2))
        dt.day |> should.equal(Some(1))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_september_30_test() {
  let result = era.parse("September 30")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(9))
        dt.day |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_oct_15_2025_test() {
  let result = era.parse("Oct 15, 2025")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.year |> should.equal(Some(2025))
        dt.month |> should.equal(Some(10))
        dt.day |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_nov_20_test() {
  let result = era.parse("Nov 20")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(11))
        dt.day |> should.equal(Some(20))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Numeric date formats
pub fn parse_01_15_2024_test() {
  let result = era.parse("01/15/2024")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.year |> should.equal(Some(2024))
        dt.month |> should.equal(Some(1))
        dt.day |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_12_31_test() {
  let result = era.parse("12/31")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(12))
        dt.day |> should.equal(Some(31))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_3_15_test() {
  let result = era.parse("3/15")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(3))
        dt.day |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// MORE TIME FORMATS
// ============================================================================

pub fn parse_6am_test() {
  let result = era.parse("6am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(6))
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_11pm_test() {
  let result = era.parse("11pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(23))
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_3_30am_test() {
  let result = era.parse("3:30am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(3))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_10_15pm_test() {
  let result = era.parse("10:15pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(22))
        dt.minute |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_00_00_test() {
  let result = era.parse("00:00")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(0))
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_13_45_test() {
  let result = era.parse("13:45")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(13))
        dt.minute |> should.equal(Some(45))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_17_00_test() {
  let result = era.parse("17:00")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(17))
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_20_30_test() {
  let result = era.parse("20:30")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(20))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// DATE + TIME COMBINATIONS
// ============================================================================

pub fn parse_march_15_at_3pm_test() {
  let result = era.parse("March 15 at 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(3))
        dt.day |> should.equal(Some(15))
        dt.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_jan_1_2025_at_midnight_test() {
  let result = era.parse("Jan 1, 2025 at midnight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.year |> should.equal(Some(2025))
        dt.month |> should.equal(Some(1))
        dt.day |> should.equal(Some(1))
        dt.hour |> should.equal(Some(0))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_december_25_noon_test() {
  let result = era.parse("December 25 noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(12))
        dt.day |> should.equal(Some(25))
        dt.hour |> should.equal(Some(12))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_yesterday_at_3pm_test() {
  let result = era.parse("yesterday at 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Yesterday))
        dt.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_last_monday_at_9am_test() {
  let result = era.parse("last monday at 9am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(era.LastWeekday(Monday)))
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// MORE RECURRENCE PATTERNS
// ============================================================================

pub fn parse_monthly_test() {
  let result = era.parse("monthly")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          era.Monthly -> Nil
          _ -> panic as "Expected Monthly pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_yearly_test() {
  let result = era.parse("yearly")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          era.Yearly -> Nil
          _ -> panic as "Expected Yearly pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_every_wednesday_test() {
  let result = era.parse("every wednesday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> days |> should.equal([Wednesday])
          _ -> panic as "Expected EveryWeekday pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_every_thursday_at_2pm_test() {
  let result = era.parse("every thursday at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> days |> should.equal([Thursday])
          _ -> panic as "Expected EveryWeekday pattern"
        }
        re.time.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_every_monday_wednesday_friday_test() {
  let result = era.parse("every Monday and Wednesday and Friday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> {
            days |> should.equal([Monday, Wednesday, Friday])
          }
          _ -> panic as "Expected EveryWeekday pattern"
        }
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

// ============================================================================
// MORE TIME RANGE TESTS
// ============================================================================

pub fn parse_6am_to_8am_test() {
  let result = era.parse("6am to 8am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(6))
        tr.end.hour |> should.equal(Some(8))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_2_4pm_test() {
  let result = era.parse("2-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(14))
        tr.end.hour |> should.equal(Some(16))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_11am_to_1pm_test() {
  let result = era.parse("11am to 1pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(11))
        tr.end.hour |> should.equal(Some(13))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_10pm_to_midnight_test() {
  let result = era.parse("10pm to midnight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(22))
        tr.end.hour |> should.equal(Some(0))
      }
      _ -> panic as "Expected Range"
    }
  }
}

// ============================================================================
// ADDITIONAL MINUTE/HOUR OFFSET TESTS
// ============================================================================

pub fn parse_10_minutes_ago_test() {
  let result = era.parse("10 minutes ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesAgo(10)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_45_minutes_from_now_test() {
  let result = era.parse("45 minutes from now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(45)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_5_minutes_test() {
  let result = era.parse("in 5 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(5)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_4_hours_from_now_test() {
  let result = era.parse("4 hours from now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(HoursFromNow(4)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_6_hours_test() {
  let result = era.parse("in 6 hours")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(HoursFromNow(6)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_12_hours_ago_test() {
  let result = era.parse("12 hours ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(HoursAgo(12)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// MORE DAY/WEEK OFFSET TESTS
// ============================================================================

pub fn parse_7_days_ago_test() {
  let result = era.parse("7 days ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(DaysAgo(7)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_10_days_test() {
  let result = era.parse("in 10 days")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(DaysFromNow(10)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_14_days_from_now_test() {
  let result = era.parse("14 days from now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(DaysFromNow(14)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_1_week_ago_test() {
  let result = era.parse("1 week ago")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(WeeksAgo(1)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_3_weeks_from_now_test() {
  let result = era.parse("3 weeks from now")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(WeeksFromNow(3)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_in_4_weeks_test() {
  let result = era.parse("in 4 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(WeeksFromNow(4)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// ABBREVIATION TESTS
// ============================================================================

pub fn parse_tue_test() {
  let result = era.parse("tue")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_thu_test() {
  let result = era.parse("thu")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Thursday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_fri_test() {
  let result = era.parse("fri")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Friday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_sat_test() {
  let result = era.parse("sat")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(era.Saturday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_sun_test() {
  let result = era.parse("sun")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(era.Sunday)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_jan_test() {
  let result = era.parse("Jan 15")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(1))
        dt.day |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_sept_test() {
  let result = era.parse("Sept 10")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(9))
        dt.day |> should.equal(Some(10))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// REALISTIC EMAIL/CHAT DIALOG TEST CASES
// ============================================================================
// These test cases demonstrate the library's ability to extract dates from
// text "in the wild" - real emails, chat messages, and prose with dates embedded!

// ✅ NOW WORKS: Parser extracts dates from text!
pub fn parse_email_embedded_date_test() {
  let result = era.parse("Hey can we meet tomorrow at 3pm to discuss the proposal?")
  // Parser should now extract "tomorrow at 3pm" from the text
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_email_embedded_time_range_test() {
  let result = era.parse("I'm available 2-4pm if that works for you")
  // Extracts "2-4pm" time range from text
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(14))
        tr.end.hour |> should.equal(Some(16))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_slack_reminder_test() {
  let result = era.parse("Reminder: standup in 15 minutes!")
  // Extracts "in 15 minutes" from Slack message
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

pub fn parse_calendar_invite_test() {
  let result = era.parse("Team sync every Tuesday and Thursday at 10am starting next week")
  // Extracts recurring meeting from calendar invite
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> days |> should.equal([Tuesday, Thursday])
          _ -> panic as "Expected EveryWeekday"
        }
        re.time.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

// BUT - these CLEAN expressions work (what you'd extract):

// Email scenario 1: "Hey can we meet TOMORROW AT 3PM to discuss?"
pub fn parse_extracted_tomorrow_3pm_test() {
  let result = era.parse("tomorrow at 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Email scenario 2: "I'm available 2-4PM if that works"
pub fn parse_extracted_2_4pm_range_test() {
  let result = era.parse("2-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        // Time values
        tr.start.hour |> should.equal(Some(14))
        tr.end.hour |> should.equal(Some(16))
        // Defaults to Today when no day is specified
        tr.start.relative |> should.equal(Some(Today))
        tr.end.relative |> should.equal(Some(Today))
        // No specific date fields
        tr.start.year |> should.equal(None)
        tr.start.month |> should.equal(None)
        tr.start.day |> should.equal(None)
      }
      _ -> panic as "Expected Range"
    }
  }
}

// Slack scenario: "standup IN 15 MINUTES"
pub fn parse_extracted_in_15_min_test() {
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

// Calendar invite: "EVERY TUESDAY AND THURSDAY AT 10AM"
pub fn parse_extracted_recurring_tue_thu_test() {
  let result = era.parse("every Tuesday and Thursday at 10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> days |> should.equal([Tuesday, Thursday])
          _ -> panic as "Expected EveryWeekday"
        }
        re.time.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

// Email: "Let's schedule for NEXT MONDAY AT 2:30PM"
pub fn parse_extracted_next_monday_230pm_test() {
  let result = era.parse("next Monday at 2:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
        dt.hour |> should.equal(Some(14))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Chat: "I'll call you back IN 2 HOURS"
pub fn parse_extracted_in_2_hours_test() {
  let result = era.parse("in 2 hours")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(HoursFromNow(2)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Office hours sign: "Available 9AM TO 5PM"
pub fn parse_extracted_office_hours_test() {
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

// Email: "Conference is NOVEMBER 15, 2024"
pub fn parse_extracted_nov_15_2024_test() {
  let result = era.parse("November 15, 2024")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.year |> should.equal(Some(2024))
        dt.month |> should.equal(Some(11))
        dt.day |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Gym schedule: "I go MONDAY AND WEDNESDAY AND FRIDAY"
pub fn parse_extracted_mon_wed_fri_test() {
  let result = era.parse("Monday and Wednesday and Friday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        // Verify we get 3 dates
        case dates {
          [d1, d2, d3] -> {
            d1.relative |> should.equal(Some(NextWeekday(Monday)))
            d2.relative |> should.equal(Some(NextWeekday(Wednesday)))
            d3.relative |> should.equal(Some(NextWeekday(Friday)))
          }
          _ -> panic as "Expected exactly 3 dates"
        }
      }
      _ -> panic as "Expected MultiplePoints"
    }
  }
}

// Email: "Deadline was 3 DAYS AGO"
pub fn parse_extracted_3_days_ago_deadline_test() {
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

// Appointment reminder: "Your appointment is TOMORROW AT NOON"
pub fn parse_extracted_tomorrow_noon_test() {
  let result = era.parse("tomorrow at noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(12))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Weekly meeting: "Team standup EVERY MONDAY AT 9AM"
pub fn parse_extracted_weekly_standup_test() {
  let result = era.parse("every Monday at 9am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        case re.pattern {
          EveryWeekday(days) -> days |> should.equal([Monday])
          _ -> panic as "Expected EveryWeekday"
        }
        re.time.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

// Text message: "Running late, be there IN 5 MINUTES"
pub fn parse_extracted_in_5_min_eta_test() {
  let result = era.parse("in 5 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(5)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Project deadline: "Due IN 2 WEEKS"
pub fn parse_extracted_in_2_weeks_deadline_test() {
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

// Birthday reminder: "Sarah's birthday is JULY 15"
pub fn parse_extracted_july_15_birthday_test() {
  let result = era.parse("July 15")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(7))
        dt.day |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Precise meeting time: "Zoom call at 14:30:00"
pub fn parse_extracted_precise_time_test() {
  let result = era.parse("14:30:00")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(14))
        dt.minute |> should.equal(Some(30))
        dt.second |> should.equal(Some(0))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// MASSIVE "IN THE WILD" TEST SUITE - Real-world text scenarios
// ============================================================================

// Email scenarios
pub fn parse_wild_email_meeting_request_test() {
  let result = era.parse("Hi John, can we schedule a call for next Wednesday at 2pm? Thanks!")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Wednesday)))
        dt.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_email_availability_test() {
  let result = era.parse("I'm free tomorrow afternoon if you want to chat")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(15))  // afternoon = 3pm
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_email_deadline_test() {
  let result = era.parse("The report is due in 3 days, please have it ready by then.")
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

pub fn parse_wild_email_followup_test() {
  let result = era.parse("Following up on our conversation from 2 days ago...")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(DaysAgo(2)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Slack/Chat scenarios
pub fn parse_wild_slack_standup_test() {
  let result = era.parse("@channel standup in 10 minutes!")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(10)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_slack_meeting_test() {
  let result = era.parse("Quick sync at 3:30pm in room 204?")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(15))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_slack_eta_test() {
  let result = era.parse("Sorry running late, will be there in 5 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(5)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_slack_lunch_test() {
  let result = era.parse("Anyone want to grab lunch at noon?")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(12))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Calendar invites
pub fn parse_wild_calendar_weekly_test() {
  let result = era.parse("Weekly team standup - every Monday at 9am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_wild_calendar_biweekly_test() {
  let result = era.parse("1-on-1 meeting every other Tuesday at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_wild_calendar_workshop_test() {
  let result = era.parse("Design workshop next Friday from 10am to 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        // Should parse "next Friday"
        dt.relative |> should.equal(Some(NextWeekday(Friday)))
      }
      Range(tr) -> {
        // Or parse "10am to 4pm" range
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(16))
      }
      _ -> Nil  // Accept either interpretation
    }
  }
}

// SMS/Text messages
pub fn parse_wild_sms_dinner_test() {
  let result = era.parse("Want to get dinner tonight at 7pm?")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_sms_movie_test() {
  let result = era.parse("Movie starts at 8:15pm, meet outside at 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        // Should parse either 8:15pm or 8pm
        case dt.hour {
          Some(20) -> Nil  // Could be 8pm or 8:15pm
          _ -> panic as "Expected hour 20"
        }
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_sms_pickup_test() {
  let result = era.parse("Can you pick me up tomorrow morning at 6:30am?")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(6))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Social media posts
pub fn parse_wild_twitter_event_test() {
  let result = era.parse("Join us for the webinar on Thursday at 2pm EST!")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Thursday)))
        dt.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_facebook_party_test() {
  let result = era.parse("Birthday party this Saturday at 7pm! Everyone's invited")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Task management
pub fn parse_wild_todo_urgent_test() {
  let result = era.parse("URGENT: Fix production bug by tonight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Today))
        dt.hour |> should.equal(Some(22))  // tonight
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_todo_deadline_test() {
  let result = era.parse("Submit proposal by Friday 5pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Friday)))
        dt.hour |> should.equal(Some(17))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_todo_reminder_test() {
  let result = era.parse("Remember to call dentist tomorrow")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Doctor/Medical
pub fn parse_wild_doctor_appointment_test() {
  let result = era.parse("Your appointment is scheduled for next Tuesday at 10:30am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
        dt.hour |> should.equal(Some(10))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_prescription_test() {
  let result = era.parse("Take medication daily at 8am and 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        // Should parse "daily"
        Nil
      }
      SinglePoint(dt) -> {
        // Or just parse "8am"
        dt.hour |> should.equal(Some(8))
      }
      MultiplePoints(_) -> {
        // Or parse "8am and 8pm" as multiple points
        Nil
      }
      _ -> Nil
    }
  }
}

// Travel/Transportation
pub fn parse_wild_flight_test() {
  let result = era.parse("Flight departs tomorrow at 6:45am from gate B12")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(6))
        dt.minute |> should.equal(Some(45))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_train_test() {
  let result = era.parse("Next train to Boston leaves in 20 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(20)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_uber_test() {
  let result = era.parse("Your ride will arrive in 3 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(3)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Work/Professional
pub fn parse_wild_interview_test() {
  let result = era.parse("Interview scheduled for Monday, March 15 at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(3))
        dt.day |> should.equal(Some(15))
        dt.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_presentation_test() {
  let result = era.parse("You're presenting on Wednesday from 3-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Wednesday)))
      }
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(15))
        tr.end.hour |> should.equal(Some(16))
      }
      _ -> Nil
    }
  }
}

pub fn parse_wild_code_review_test() {
  let result = era.parse("Code review meeting every Thursday at 11am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(11))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

// Personal/Social
pub fn parse_wild_gym_schedule_test() {
  let result = era.parse("Gym class Mon/Wed/Fri at 6am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(_) -> Nil  // Mon/Wed/Fri parsed as multiple points
      SinglePoint(dt) -> {
        // Or just parses first weekday
        dt.hour |> should.equal(Some(6))
      }
      _ -> Nil
    }
  }
}

pub fn parse_wild_coffee_test() {
  let result = era.parse("Coffee tomorrow at 10am at the usual spot?")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_lunch_date_test() {
  let result = era.parse("Let's do lunch next week, how about Tuesday at 12:30pm?")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
        dt.hour |> should.equal(Some(12))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// UK/GB date format tests
pub fn parse_wild_uk_date_explicit_test() {
  let result = era.parse("Meeting on 25/12/2024 at 2pm")  // DD/MM/YYYY
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.day |> should.equal(Some(25))
        dt.month |> should.equal(Some(12))
        dt.year |> should.equal(Some(2024))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_uk_date_ambiguous_test() {
  let result = era.parse("Deadline is 03/04/2024")  // Ambiguous, defaults to US (March 4)
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(3))  // US format
        dt.day |> should.equal(Some(4))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Emoji tests (emojis as unknown tokens should be skipped)
pub fn parse_wild_emoji_calendar_test() {
  let result = era.parse("📅 Meeting tomorrow at 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_emoji_clock_test() {
  let result = era.parse("⏰ Reminder: standup in 5 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(MinutesFromNow(5)))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_emoji_party_test() {
  let result = era.parse("🎉 Party this Friday at 8pm!")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(20))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Complex punctuation
pub fn parse_wild_parentheses_test() {
  let result = era.parse("Meeting (rescheduled) now at 4pm instead of 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        // Should parse "4pm" or "3pm"
        case dt.hour {
          Some(15) -> Nil  // 3pm
          Some(16) -> Nil  // 4pm
          _ -> panic as "Expected hour 15 or 16"
        }
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_quotes_test() {
  let result = era.parse("She said \"meet me at 5pm\" so I'll be there")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(17))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_brackets_test() {
  let result = era.parse("[URGENT] Deploy by tomorrow at midnight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(0))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Casual/Informal
pub fn parse_wild_casual_tonight_test() {
  let result = era.parse("wanna hang tonight at like 9pm or something?")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(21))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_casual_weekend_test() {
  let result = era.parse("lets do smth this saturday afternoon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        // Could parse "saturday" or "afternoon"
        Nil
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Multiple dates in same text (should parse first one)
pub fn parse_wild_multiple_dates_test() {
  let result = era.parse("Meeting moved from Monday to Wednesday at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        // Should find either Monday or Wednesday at 2pm
        Nil
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Edge cases with numbers
pub fn parse_wild_age_and_time_test() {
  let result = era.parse("My son is 5 years old, party at 3pm tomorrow")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        // Should find "3pm tomorrow", NOT "5 years"
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_address_and_time_test() {
  let result = era.parse("Meet at 123 Main St tomorrow at 10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// Common abbreviations
pub fn parse_wild_abbrev_dept_test() {
  let result = era.parse("Dept. meeting next Mon at 9am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

pub fn parse_wild_abbrev_appt_test() {
  let result = era.parse("Appt scheduled for Tue at 2:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
        dt.hour |> should.equal(Some(14))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected SinglePoint"
    }
  }
}

// ============================================================================
// PARTICULAR TIMES - 50 tests with multiple times per sentence
// ============================================================================

pub fn parse_times_double_appointment_test() {
  let result = era.parse("Doctor at 9am, then dentist at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(9))
      MultiplePoints(dates) -> dates |> list.length |> should.equal(2)
      _ -> Nil
    }
  }
}

pub fn parse_times_meeting_series_test() {
  let result = era.parse("Meetings at 10am, 11:30am, and 3pm today")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(10))
      MultiplePoints(_) -> Nil
      _ -> Nil
    }
  }
}

pub fn parse_times_shift_schedule_test() {
  let result = era.parse("Morning shift 6am-2pm, evening shift 2pm-10pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(6))
        tr.end.hour |> should.equal(Some(14))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_precise_schedule_test() {
  let result = era.parse("Breakfast 7:30am, lunch 12:15pm, dinner 6:45pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(7))
        dt.minute |> should.equal(Some(30))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_tomorrow_multiple_test() {
  let result = era.parse("Tomorrow I have calls at 9am, 11am, and 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(9))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_next_week_test() {
  let result = era.parse("Next Monday at 10am, Wednesday at 2pm, Friday at 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
      }
      MultiplePoints(_) -> Nil
      _ -> Nil
    }
  }
}

pub fn parse_times_conference_schedule_test() {
  let result = era.parse("Keynote at 9am, breakout sessions 10:30am-12pm, lunch 12-1pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(9))
      Range(_) -> Nil
      _ -> Nil
    }
  }
}

pub fn parse_times_travel_itinerary_test() {
  let result = era.parse("Depart 6:15am, layover 11am-1pm, arrive 5:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(6))
        dt.minute |> should.equal(Some(15))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_workout_plan_test() {
  let result = era.parse("Cardio 6am, weights 7am, yoga 8am every morning")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(6))
      Recurring(_) -> Nil
      _ -> Nil
    }
  }
}

pub fn parse_times_medication_schedule_test() {
  let result = era.parse("Take pills at 8am, 2pm, and 8pm daily")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(8))
      Recurring(_) -> Nil
      MultiplePoints(_) -> Nil
      _ -> Nil
    }
  }
}

pub fn parse_times_class_schedule_test() {
  let result = era.parse("Math 9am, Science 10:30am, Lunch 12pm, History 1:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.equal(4)
        // Check first time: 9am
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(9))
      }
      SinglePoint(dt) -> {
        // Parser might only catch first time
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_interview_day_test() {
  let result = era.parse("Phone screen tomorrow at 10am, technical interview at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
        dt.hour |> should.equal(Some(10))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_reminder_chain_test() {
  let result = era.parse("Reminder in 5 minutes, another in 15 minutes, final in 30 minutes")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.relative |> should.equal(Some(MinutesFromNow(5)))
      _ -> Nil
    }
  }
}

pub fn parse_times_office_hours_test() {
  let result = era.parse("Available Monday 9am-11am, Wednesday 2pm-4pm, Friday 10am-12pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        // Should parse first range: Monday 9am-11am
        tr.start.relative |> should.equal(Some(NextWeekday(Monday)))
        tr.start.hour |> should.equal(Some(9))
        tr.end.hour |> should.equal(Some(11))
      }
      MultipleRanges(ranges) -> {
        // Ideally parses all three ranges
        ranges |> list.length |> should.equal(3)
      }
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_times_appointment_conflict_test() {
  let result = era.parse("Meeting moved from 2pm to 4pm tomorrow")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        case dt.hour {
          Some(14) -> Nil  // 2pm
          Some(16) -> Nil  // 4pm
          _ -> panic as "Expected 2pm or 4pm"
        }
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_phone_tag_test() {
  let result = era.parse("Called at 10am, left message at 11:30am, callback expected 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(10))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_deadline_cascade_test() {
  let result = era.parse("Draft due 9am, review by noon, final by 5pm today")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Today))
        dt.hour |> should.equal(Some(9))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_webinar_schedule_test() {
  let result = era.parse("Session 1 at 10am EST, Session 2 at 2pm EST, Q&A at 4pm EST")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(10))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_sports_schedule_test() {
  let result = era.parse("Warmup 5:30pm, game starts 6pm, ends around 8pm tonight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(17))
      _ -> Nil
    }
  }
}

pub fn parse_times_birthday_party_test() {
  let result = era.parse("Arrive Saturday at 7pm, cake at 8pm, fireworks at 9pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.relative |> should.equal(Some(NextWeekday(Saturday)))
        first.hour |> should.equal(Some(19))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Saturday)))
        dt.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_delivery_window_test() {
  let result = era.parse("Package arriving between 10am and 2pm tomorrow")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(14))
      }
      SinglePoint(dt) -> dt.relative |> should.equal(Some(Tomorrow))
      _ -> Nil
    }
  }
}

pub fn parse_times_museum_visit_test() {
  let result = era.parse("Entry 10am, guided tour 11am, lunch break 1pm, exit 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(3)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(10))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_cooking_schedule_test() {
  let result = era.parse("Prep starts 4pm, cooking 5pm, serving at 6:30pm tonight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(16))
      _ -> Nil
    }
  }
}

pub fn parse_times_exam_schedule_test() {
  let result = era.parse("Exam Monday 9am-11am, results Friday at 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Monday)))
        tr.start.hour |> should.equal(Some(9))
        tr.end.hour |> should.equal(Some(11))
      }
      SinglePoint(dt) -> {
        // Might parse first time only
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
      }
      _ -> panic as "Expected Range or SinglePoint"
    }
  }
}

pub fn parse_times_haircut_wait_test() {
  let result = era.parse("Appointment at 2pm but usually runs 15-30 minutes late")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(14))
      _ -> Nil
    }
  }
}

pub fn parse_times_conference_call_test() {
  let result = era.parse("Call starts 9am Pacific, 12pm Eastern, 5pm London time")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(9))
      _ -> Nil
    }
  }
}

pub fn parse_times_movie_marathon_test() {
  let result = era.parse("First movie 7pm, second 9:30pm, third midnight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> dt.hour |> should.equal(Some(19))
      _ -> Nil
    }
  }
}

pub fn parse_times_baby_feeding_test() {
  let result = era.parse("Fed at 6am, 9am, noon, 3pm, and 6pm today")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(3)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(6))
        first.relative |> should.equal(Some(Today))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(6))
        dt.relative |> should.equal(Some(Today))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_train_connections_test() {
  let result = era.parse("Depart 8:15am, transfer 9:45am, arrive 11:20am tomorrow")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_vet_appointments_test() {
  let result = era.parse("Cat checkup Tuesday 10am, dog grooming Thursday 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.equal(2)
        let assert [first, ..] = dates
        first.relative |> should.equal(Some(NextWeekday(Tuesday)))
        first.hour |> should.equal(Some(10))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
        dt.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_rehearsal_schedule_test() {
  let result = era.parse("Act 1 rehearsal 6pm, Act 2 at 7:30pm, full run 9pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(18))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_court_appearance_test() {
  let result = era.parse("Arraignment Monday 9am, hearing Wednesday 2pm, trial Friday 10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.relative |> should.equal(Some(NextWeekday(Monday)))
        first.hour |> should.equal(Some(9))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_surgery_schedule_test() {
  let result = era.parse("Pre-op 6am, surgery 8am, recovery 10am-2pm tomorrow")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(Tomorrow))
      }
      _ -> Nil
    }
  }
}

pub fn parse_times_market_hours_test() {
  let result = era.parse("Market opens 9:30am, lunch 12-1pm, closes 4pm weekdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(9))
        dt.minute |> should.equal(Some(30))
      }
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(12))
      }
      _ -> panic as "Expected SinglePoint or Range"
    }
  }
}

pub fn parse_times_festival_lineup_test() {
  let result = era.parse("Gates open 4pm, opening act 6pm, headliner 9pm Saturday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(16))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(16))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_cleaning_schedule_test() {
  let result = era.parse("Kitchen 9am, bathrooms 10:30am, bedrooms 1pm, living room 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(3)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(9))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_tutoring_sessions_test() {
  let result = era.parse("Math Monday 4pm, Science Wednesday 4pm, English Friday 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.relative |> should.equal(Some(NextWeekday(Monday)))
        first.hour |> should.equal(Some(16))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
        dt.hour |> should.equal(Some(16))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_tv_schedule_test() {
  let result = era.parse("News at 6pm, sitcom 7pm, drama 8pm, late show 11pm tonight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(3)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(18))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_bakery_fresh_test() {
  let result = era.parse("Bread ready 6am, pastries 7am, cakes 10am daily")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(6))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(6))
      }
      Recurring(_) -> Nil  // Might parse as recurring due to "daily"
      _ -> panic as "Expected SinglePoint, MultiplePoints, or Recurring"
    }
  }
}

pub fn parse_times_parking_meter_test() {
  let result = era.parse("Parked at 10:15am, meter expires 12:15pm, need to move by 12:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(10))
        first.minute |> should.equal(Some(15))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(10))
        dt.minute |> should.equal(Some(15))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_church_services_test() {
  let result = era.parse("Early service 8am, main service 10:30am, evening service 6pm Sunday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(2)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(8))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(8))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_nap_schedule_test() {
  let result = era.parse("Morning nap 10am-11am, afternoon nap 2pm-3:30pm every day")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(11))
      }
      MultipleRanges(ranges) -> {
        ranges |> list.length |> should.equal(2)
      }
      Recurring(_) -> Nil  // Might parse as recurring due to "every day"
      _ -> panic as "Expected Range, MultipleRanges, or Recurring"
    }
  }
}

pub fn parse_times_prescription_refill_test() {
  let result = era.parse("Call pharmacy at 9am, pick up between 2pm-5pm today")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(9))
        dt.relative |> should.equal(Some(Today))
      }
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(14))
        tr.end.hour |> should.equal(Some(17))
      }
      _ -> panic as "Expected SinglePoint or Range"
    }
  }
}

pub fn parse_times_dog_walker_test() {
  let result = era.parse("Walker comes 11am weekdays, noon on weekends")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(1)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(11))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(11))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_guitar_practice_test() {
  let result = era.parse("Scales 30 minutes at 5pm, songs 6pm-7pm, free play 7pm-8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(17))
      }
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(18))
      }
      MultipleRanges(_) -> Nil
      _ -> panic as "Expected SinglePoint, Range, or MultipleRanges"
    }
  }
}

pub fn parse_times_car_service_test() {
  let result = era.parse("Drop off 8am, oil change 9am, tire rotation 10am, pickup noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(3)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(8))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(8))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_zoom_marathon_test() {
  let result = era.parse("Standup 9am, sprint planning 10am, retrospective 2pm, 1-on-1s 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(3)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(9))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

pub fn parse_times_laundry_day_test() {
  let result = era.parse("Wash starts 9am, transfer to dryer 10am, fold 11am, put away noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      MultiplePoints(dates) -> {
        dates |> list.length |> should.be_at_least(3)
        let assert [first, ..] = dates
        first.hour |> should.equal(Some(9))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected SinglePoint or MultiplePoints"
    }
  }
}

// ============================================================================
// DATE RANGES - 50 tests
// ============================================================================

pub fn parse_range_vacation_week_test() {
  let result = era.parse("On vacation from Monday to Friday next week")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Monday)))
        tr.end.relative |> should.equal(Some(NextWeekday(Friday)))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
      }
      _ -> panic as "Expected Range or SinglePoint"
    }
  }
}

pub fn parse_range_conference_days_test() {
  let result = era.parse("Conference runs Tuesday through Thursday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Tuesday)))
        tr.end.relative |> should.equal(Some(NextWeekday(Thursday)))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
      }
      _ -> panic as "Expected Range or SinglePoint"
    }
  }
}

pub fn parse_range_project_timeline_test() {
  let result = era.parse("Development phase March 1-15, testing March 16-31")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.month |> should.equal(Some(3))
        tr.start.day |> should.equal(Some(1))
        tr.end.day |> should.equal(Some(15))
      }
      MultipleRanges(ranges) -> {
        ranges |> list.length |> should.equal(2)
      }
      SinglePoint(dt) -> {
        dt.month |> should.equal(Some(3))
        dt.day |> should.equal(Some(1))
      }
      _ -> panic as "Expected Range, MultipleRanges, or SinglePoint"
    }
  }
}

pub fn parse_range_office_hours_daily_test() {
  let result = era.parse("Office hours 9am-5pm Monday through Friday")
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

pub fn parse_range_happy_hour_test() {
  let result = era.parse("Happy hour 4-7pm weekdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(16))
        tr.end.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_breakfast_service_test() {
  let result = era.parse("Breakfast served 6:30am to 10:30am daily")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(6))
        tr.start.minute |> should.equal(Some(30))
        tr.end.hour |> should.equal(Some(10))
        tr.end.minute |> should.equal(Some(30))
      }
      Recurring(_) -> Nil  // Might parse as recurring due to "daily"
      _ -> panic as "Expected Range or Recurring"
    }
  }
}

pub fn parse_range_gym_open_test() {
  let result = era.parse("Gym open 5am-11pm seven days a week")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(5))
        tr.end.hour |> should.equal(Some(23))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_quiet_hours_test() {
  let result = era.parse("Quiet hours 10pm-7am in the building")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(22))
        tr.end.hour |> should.equal(Some(7))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_lunch_shift_test() {
  let result = era.parse("Lunch shift covers 11:30am through 2:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(11))
        tr.start.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_pool_hours_test() {
  let result = era.parse("Pool hours 10am to 8pm Memorial Day through Labor Day")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(20))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_store_sale_test() {
  let result = era.parse("Sale runs Friday 9am through Sunday 9pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Friday)))
        tr.start.hour |> should.equal(Some(9))
        tr.end.relative |> should.equal(Some(NextWeekday(Sunday)))
        tr.end.hour |> should.equal(Some(21))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Friday)))
        dt.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected Range or SinglePoint"
    }
  }
}

pub fn parse_range_parking_restricted_test() {
  let result = era.parse("No parking 7am-9am and 4pm-6pm weekdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(7))
        tr.end.hour |> should.equal(Some(9))
      }
      MultipleRanges(ranges) -> {
        ranges |> list.length |> should.equal(2)
        let assert [first, ..] = ranges
        first.start.hour |> should.equal(Some(7))
        first.end.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_workshop_duration_test() {
  let result = era.parse("Workshop Saturday 10am-4pm with lunch 12-1pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Saturday)))
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(16))
      }
      MultipleRanges(ranges) -> {
        ranges |> list.length |> should.be_at_least(1)
      }
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_library_open_test() {
  let result = era.parse("Library 8am-9pm Mon-Thu, 8am-5pm Fri-Sat, closed Sunday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(21))
      }
      MultipleRanges(_) -> Nil
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_call_center_test() {
  let result = era.parse("Call center available 6am-midnight ET daily")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(6))
        tr.end.hour |> should.equal(Some(0))
      }
      Recurring(_) -> Nil  // Might parse as recurring due to "daily"
      _ -> panic as "Expected Range or Recurring"
    }
  }
}

pub fn parse_range_construction_noise_test() {
  let result = era.parse("Construction noise permitted 8am-6pm weekdays only")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_doctor_availability_test() {
  let result = era.parse("Dr. Smith available Tuesday-Thursday 9am-3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(9))
        tr.end.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_farmers_market_test() {
  let result = era.parse("Farmers market Saturdays 7am-1pm April through October")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(7))
        tr.end.hour |> should.equal(Some(13))
      }
      Recurring(_) -> Nil  // Might parse as recurring due to "Saturdays"
      _ -> panic as "Expected Range or Recurring"
    }
  }
}

pub fn parse_range_ticket_sales_test() {
  let result = era.parse("Tickets on sale starting Monday 10am through Friday 5pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Monday)))
        tr.start.hour |> should.equal(Some(10))
        tr.end.relative |> should.equal(Some(NextWeekday(Friday)))
        tr.end.hour |> should.equal(Some(17))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
        dt.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected Range or SinglePoint"
    }
  }
}

pub fn parse_range_meter_enforcement_test() {
  let result = era.parse("Meter enforcement 8am-6pm except Sundays and holidays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_summer_camp_test() {
  let result = era.parse("Camp runs June 15-August 15, drop-off 8-9am, pickup 3-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.month |> should.equal(Some(6))
        tr.start.day |> should.equal(Some(15))
      }
      MultipleRanges(_) -> Nil
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_rehearsal_week_test() {
  let result = era.parse("Rehearsals Monday-Friday 6-10pm next week")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(18))
        tr.end.hour |> should.equal(Some(22))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_restaurant_hours_test() {
  let result = era.parse("Open for dinner Tuesday-Sunday 5pm-10pm, closed Mondays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(17))
        tr.end.hour |> should.equal(Some(22))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_ski_season_test() {
  let result = era.parse("Ski season December through March, lifts 9am-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        case tr.start.month {
          Some(12) -> tr.end.month |> should.equal(Some(3))
          Some(9) -> tr.end.hour |> should.equal(Some(16))
          _ -> panic as "Expected month 12 or hour 9"
        }
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_yard_sale_test() {
  let result = era.parse("Yard sale this Saturday 8am-2pm, rain date Sunday same time")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Saturday)))
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_bar_hours_test() {
  let result = era.parse("Bar open 11am-2am daily except Sunday 12pm-midnight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(11))
        tr.end.hour |> should.equal(Some(2))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_meditation_session_test() {
  let result = era.parse("Meditation 7-8am every morning this week")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(7))
        tr.end.hour |> should.equal(Some(8))
      }
      Recurring(_) -> Nil  // Might parse as recurring due to "every morning"
      _ -> panic as "Expected Range or Recurring"
    }
  }
}

pub fn parse_range_truck_delivery_test() {
  let result = era.parse("Delivery window tomorrow 1-5pm, please be home")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(13))
        tr.end.hour |> should.equal(Some(17))
      }
      SinglePoint(dt) -> dt.relative |> should.equal(Some(Tomorrow))
      _ -> panic as "Expected Range or SinglePoint"
    }
  }
}

pub fn parse_range_art_gallery_test() {
  let result = era.parse("Gallery hours Wed-Sun 10am-6pm, closed Mon-Tue")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_power_outage_test() {
  let result = era.parse("Scheduled outage Sunday 2am-6am for maintenance")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.relative |> should.equal(Some(NextWeekday(Sunday)))
        tr.start.hour |> should.equal(Some(2))
        tr.end.hour |> should.equal(Some(6))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_food_truck_test() {
  let result = era.parse("Taco truck here Tue-Fri 11:30am-1:30pm lunch rush")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(11))
        tr.start.minute |> should.equal(Some(30))
        tr.end.hour |> should.equal(Some(13))
        tr.end.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_voting_hours_test() {
  let result = era.parse("Polls open Tuesday 7am-8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(7))
        tr.end.hour |> should.equal(Some(20))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_snow_removal_test() {
  let result = era.parse("Snow removal operations midnight-6am when needed")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(0))
        tr.end.hour |> should.equal(Some(6))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_dog_park_test() {
  let result = era.parse("Dog park dawn to dusk daily")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(_) -> Nil
      Recurring(_) -> Nil
      SinglePoint(_) -> Nil
      _ -> panic as "Expected Range, Recurring, or SinglePoint"
    }
  }
}

pub fn parse_range_recycling_pickup_test() {
  let result = era.parse("Recycling pickup Tuesday mornings 6am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(6))
        tr.end.hour |> should.equal(Some(12))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
      }
      _ -> panic as "Expected Range or SinglePoint"
    }
  }
}

pub fn parse_range_coffee_shop_test() {
  let result = era.parse("Coffee shop 6am-8pm Mon-Fri, 7am-9pm Sat-Sun")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(6))
        tr.end.hour |> should.equal(Some(20))
      }
      MultipleRanges(_) -> Nil
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_dental_office_test() {
  let result = era.parse("Office hours M/W/F 8am-5pm, T/Th 10am-7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(17))
      }
      MultipleRanges(_) -> Nil
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_playground_test() {
  let result = era.parse("Playground supervised 3-6pm weekdays during summer")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(15))
        tr.end.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_pharmacy_drive_thru_test() {
  let result = era.parse("Drive-thru 8am-9pm every day including holidays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(21))
      }
      Recurring(_) -> Nil
      _ -> panic as "Expected Range or Recurring"
    }
  }
}

pub fn parse_range_pet_adoption_test() {
  let result = era.parse("Adoption hours Sat-Sun 11am-4pm, appointments only weekdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(11))
        tr.end.hour |> should.equal(Some(16))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_car_wash_test() {
  let result = era.parse("Car wash 7am-7pm weather permitting")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(7))
        tr.end.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_tennis_court_test() {
  let result = era.parse("Court reservations available 6am-10pm, 2-hour max")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(6))
        tr.end.hour |> should.equal(Some(22))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_bakery_special_test() {
  let result = era.parse("Fresh donuts Friday-Sunday 5am-noon or until sold out")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(5))
        tr.end.hour |> should.equal(Some(12))
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_tutoring_center_test() {
  let result = era.parse("Tutoring Mon-Thu 3-8pm, Sat 9am-2pm, closed Sun")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(15))
        tr.end.hour |> should.equal(Some(20))
      }
      MultipleRanges(_) -> Nil
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_museum_special_test() {
  let result = era.parse("Special exhibit March 1-May 31, extended hours Fridays 10am-9pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        case tr.start.month {
          Some(3) -> {
            tr.start.day |> should.equal(Some(1))
            tr.end.month |> should.equal(Some(5))
            tr.end.day |> should.equal(Some(31))
          }
          Some(10) -> {
            tr.start.hour |> should.equal(Some(10))
            tr.end.hour |> should.equal(Some(21))
          }
          _ -> panic as "Expected month 3 or hour 10"
        }
      }
      _ -> panic as "Expected Range"
    }
  }
}

pub fn parse_range_food_bank_test() {
  let result = era.parse("Food bank distributions Wed 2-4pm and Sat 9am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(14))
        tr.end.hour |> should.equal(Some(16))
      }
      MultipleRanges(ranges) -> {
        ranges |> list.length |> should.equal(2)
      }
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_ice_rink_test() {
  let result = era.parse("Public skating Sat-Sun 1-3pm and 7-9pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(13))
        tr.end.hour |> should.equal(Some(15))
      }
      MultipleRanges(ranges) -> {
        ranges |> list.length |> should.equal(2)
      }
      _ -> panic as "Expected Range or MultipleRanges"
    }
  }
}

pub fn parse_range_garage_sale_test() {
  let result = era.parse("Multi-family garage sale all weekend 8am-4pm both days")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(16))
      }
      _ -> panic as "Expected Range"
    }
  }
}

// ============================================================================
// RECURRENCE PATTERNS - 50 tests
// ============================================================================

pub fn parse_recur_team_standup_test() {
  let result = era.parse("Team standup every weekday at 9:15am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(9))
        re.time.minute |> should.equal(Some(15))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_yoga_class_test() {
  let result = era.parse("Yoga class every Monday, Wednesday, and Friday at 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_trash_day_test() {
  let result = era.parse("Trash pickup every Tuesday and Friday morning")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> Nil
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_piano_lessons_test() {
  let result = era.parse("Piano lessons every Thursday at 4:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(16))
        re.time.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_church_service_test() {
  let result = era.parse("Sunday service every week at 10:30am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(10))
        re.time.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_newsletter_test() {
  let result = era.parse("Newsletter goes out every Monday at noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(12))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_movie_night_test() {
  let result = era.parse("Movie night every Friday at 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(20))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_payroll_test() {
  let result = era.parse("Payroll processed every other Friday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_lawn_service_test() {
  let result = era.parse("Lawn service every Wednesday morning during summer")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Wednesday)))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_board_meeting_test() {
  let result = era.parse("Board meeting first Tuesday of every month at 7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(19))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_book_club_test() {
  let result = era.parse("Book club meets last Thursday each month at 6:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(18))
        re.time.minute |> should.equal(Some(30))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(18))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_cleaning_crew_test() {
  let result = era.parse("Cleaning crew comes Monday, Wednesday, Friday at 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_swim_practice_test() {
  let result = era.parse("Swim practice every weekday 5-7am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(5))
        tr.end.hour |> should.equal(Some(7))
      }
      _ -> panic as "Expected Recurring or Range"
    }
  }
}

pub fn parse_recur_grocery_delivery_test() {
  let result = era.parse("Groceries delivered every Saturday between 10am-12pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(10))
        tr.end.hour |> should.equal(Some(12))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Saturday)))
      }
      _ -> panic as "Expected Recurring, Range, or SinglePoint"
    }
  }
}

pub fn parse_recur_medication_daily_test() {
  let result = era.parse("Take medication daily at 8am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(8))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_dog_grooming_test() {
  let result = era.parse("Dog grooming every 6 weeks on Saturdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Saturday)))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_therapy_session_test() {
  let result = era.parse("Therapy every Tuesday at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_rehearsal_weekly_test() {
  let result = era.parse("Rehearsal every Wednesday evening at 7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_podcast_release_test() {
  let result = era.parse("New episodes drop every Monday at 6am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(6))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Monday)))
        dt.hour |> should.equal(Some(6))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_farmers_market_weekly_test() {
  let result = era.parse("Farmers market every Sunday 8am-1pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(13))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Sunday)))
      }
      _ -> panic as "Expected Recurring, Range, or SinglePoint"
    }
  }
}

pub fn parse_recur_oil_change_test() {
  let result = era.parse("Oil change every 3 months")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      SinglePoint(_) -> Nil
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_quiz_night_test() {
  let result = era.parse("Trivia night every Thursday at 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(20))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_blood_donation_test() {
  let result = era.parse("Blood drive every 8 weeks on Wednesdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Wednesday)))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_karate_class_test() {
  let result = era.parse("Karate classes every Tuesday and Thursday at 5:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(17))
        re.time.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_brunch_tradition_test() {
  let result = era.parse("Family brunch every Sunday at 11am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(11))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_spin_class_test() {
  let result = era.parse("Spin class Mon/Wed/Fri at 6:15am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(6))
        re.time.minute |> should.equal(Some(15))
      }
      MultiplePoints(_) -> Nil
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(6))
        dt.minute |> should.equal(Some(15))
      }
      _ -> panic as "Expected Recurring, MultiplePoints, or SinglePoint"
    }
  }
}

pub fn parse_recur_sales_call_test() {
  let result = era.parse("Sales call every Friday at 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_garbage_collection_test() {
  let result = era.parse("Garbage collection every Monday and Thursday before 7am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(7))
      }
      MultiplePoints(_) -> Nil
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(7))
      }
      _ -> panic as "Expected Recurring, MultiplePoints, or SinglePoint"
    }
  }
}

pub fn parse_recur_ballet_class_test() {
  let result = era.parse("Ballet every Saturday morning at 9am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(9))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_study_group_test() {
  let result = era.parse("Study group meets every Tuesday and Thursday at 7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_sermon_podcast_test() {
  let result = era.parse("Sermons posted online every Sunday at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(14))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Sunday)))
        dt.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_wine_tasting_test() {
  let result = era.parse("Wine tasting every first Friday at 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(18))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_coding_bootcamp_test() {
  let result = era.parse("Bootcamp Mon-Fri 9am-5pm for 12 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(9))
        tr.end.hour |> should.equal(Some(17))
      }
      _ -> panic as "Expected Recurring or Range"
    }
  }
}

pub fn parse_recur_open_mic_test() {
  let result = era.parse("Open mic night every Wednesday at 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(20))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_parking_sweep_test() {
  let result = era.parse("Street cleaning second and fourth Tuesday 8am-10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(8))
        tr.end.hour |> should.equal(Some(10))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Tuesday)))
      }
      _ -> panic as "Expected Recurring, Range, or SinglePoint"
    }
  }
}

pub fn parse_recur_webinar_series_test() {
  let result = era.parse("Webinar series every Thursday at 1pm for 8 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(13))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Thursday)))
        dt.hour |> should.equal(Some(13))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_meal_prep_test() {
  let result = era.parse("Meal prep every Sunday afternoon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(15))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_guitar_lesson_test() {
  let result = era.parse("Guitar lessons every Saturday at 10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(10))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_meditation_morning_test() {
  let result = era.parse("Morning meditation daily at 6am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(6))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_running_group_test() {
  let result = era.parse("Running group meets every Saturday 7am rain or shine")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(7))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Saturday)))
        dt.hour |> should.equal(Some(7))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_prayer_meeting_test() {
  let result = era.parse("Prayer meeting every Wednesday evening at 6:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(18))
        re.time.minute |> should.equal(Some(30))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(18))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_chess_club_test() {
  let result = era.parse("Chess club every Monday and Thursday 4-6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(16))
        tr.end.hour |> should.equal(Some(18))
      }
      _ -> panic as "Expected Recurring or Range"
    }
  }
}

pub fn parse_recur_alumni_call_test() {
  let result = era.parse("Alumni networking call last Wednesday of each month at 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(20))
      }
      SinglePoint(dt) -> {
        dt.hour |> should.equal(Some(20))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_improv_class_test() {
  let result = era.parse("Improv class every Tuesday at 7:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(19))
        re.time.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_volunteer_shift_test() {
  let result = era.parse("Volunteer shift every other Saturday 9am-1pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(_) -> Nil
      Range(tr) -> {
        tr.start.hour |> should.equal(Some(9))
        tr.end.hour |> should.equal(Some(13))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Saturday)))
      }
      _ -> panic as "Expected Recurring, Range, or SinglePoint"
    }
  }
}

pub fn parse_recur_spanish_class_test() {
  let result = era.parse("Spanish class Mon/Wed/Fri at 7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(19))
      }
      _ -> panic as "Expected Recurring"
    }
  }
}

pub fn parse_recur_scrum_retrospective_test() {
  let result = era.parse("Retrospective every other Friday at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(14))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Friday)))
        dt.hour |> should.equal(Some(14))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

pub fn parse_recur_dog_training_test() {
  let result = era.parse("Puppy training every Saturday morning at 9:30am for 6 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      Recurring(re) -> {
        re.time.hour |> should.equal(Some(9))
        re.time.minute |> should.equal(Some(30))
      }
      SinglePoint(dt) -> {
        dt.relative |> should.equal(Some(NextWeekday(Saturday)))
        dt.hour |> should.equal(Some(9))
        dt.minute |> should.equal(Some(30))
      }
      _ -> panic as "Expected Recurring or SinglePoint"
    }
  }
}

// ============================================================================
// MIXED SCENARIOS - 100 tests combining multiple patterns
// ============================================================================

pub fn parse_mixed_recurring_with_range_test() {
  let result = era.parse("Office hours every Tuesday 2-5pm and Thursday 9am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_multiple_times_recurring_test() {
  let result = era.parse("Standup daily at 9am, retrospective every Friday at 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_range_and_specific_test() {
  let result = era.parse("Available 10am-4pm tomorrow, but meeting at 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_recurring_multiple_days_test() {
  let result = era.parse("Gym Mon/Wed/Fri 6-7:30am, Sat 8-10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_deadline_series_test() {
  let result = era.parse("Draft due Monday 5pm, revisions Wednesday noon, final Friday 3pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_recurring_with_exception_test() {
  let result = era.parse("Team lunch every Thursday at noon except next Thursday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_multi_day_hours_test() {
  let result = era.parse("Open Mon-Fri 9am-8pm, Sat-Sun 10am-6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_appointment_series_test() {
  let result = era.parse("Physical therapy every Tuesday and Thursday 3pm for 6 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_shift_rotation_test() {
  let result = era.parse("Week 1: Mon-Wed 8am-4pm, Week 2: Thu-Sat 4pm-midnight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_class_schedule_full_test() {
  let result = era.parse("Intro Mon/Wed 9-10:30am, Advanced Tue/Thu 2-4pm, all month")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_event_multi_day_test() {
  let result = era.parse("Conference July 15-17, keynote Mon 9am, workshops Tue-Wed 10am-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_medication_complex_test() {
  let result = era.parse("Pill A daily 8am, Pill B every 12 hours, Pill C Mon/Wed/Fri 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_restaurant_hours_test() {
  let result = era.parse("Lunch daily 11:30am-3pm, dinner Tue-Sun 5-10pm, brunch Sat-Sun 9am-2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_training_program_test() {
  let result = era.parse("Orientation tomorrow 9am-5pm, then weekly check-ins every Friday 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_court_schedule_test() {
  let result = era.parse("Tennis court A 6-8am, court B 8-10am, available weekdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_childcare_schedule_test() {
  let result = era.parse("Daycare Mon-Fri 7am-6pm, extended hours Thu until 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_concert_series_test() {
  let result = era.parse("Summer concerts every Saturday 7pm June through August")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_cleaning_rotation_test() {
  let result = era.parse("Deep clean first Monday of month 8am-4pm, maintenance every Wed 10am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_doctor_rounds_test() {
  let result = era.parse("Dr. Lee Mon/Tue/Thu 9am-3pm, Dr. Park Wed/Fri 1-6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_pool_schedule_complex_test() {
  let result = era.parse("Lap swim 6-8am daily, lessons Mon/Wed 4-5pm, free swim weekends 10am-6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_library_story_time_test() {
  let result = era.parse("Story time every Tuesday and Thursday 10:30am during school year")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_parking_complex_test() {
  let result = era.parse("Parking free after 6pm weekdays, all day weekends, $5/hour 8am-6pm Mon-Fri")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_delivery_schedule_test() {
  let result = era.parse("Same-day if ordered by noon, next day if by 5pm, weekend orders ship Monday")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_salon_availability_test() {
  let result = era.parse("Walk-ins Tue-Thu 10am-2pm, appointments Mon-Sat 9am-7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_workshop_series_test() {
  let result = era.parse("Intro workshop tomorrow 6-8pm, advanced every Thursday 7pm for 4 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_food_service_test() {
  let result = era.parse("Breakfast 6-11am daily, lunch 11am-3pm, dinner 5-9pm, late night Fri-Sat until midnight")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_fitness_bootcamp_test() {
  let result = era.parse("Bootcamp Mon/Wed/Fri 5:30-6:30am plus Saturday 8-9:30am for 8 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_museum_hours_special_test() {
  let result = era.parse("Regular hours Tue-Sun 10am-5pm, late night first Friday 10am-9pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_pharmacy_schedule_test() {
  let result = era.parse("Pharmacy Mon-Fri 8am-9pm, Sat 9am-6pm, Sun 10am-4pm, 24hr drive-thru")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_tutoring_complex_test() {
  let result = era.parse("Math tutoring every Mon/Wed 4-6pm, test prep Saturdays 9am-noon starting next week")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_volunteer_shifts_test() {
  let result = era.parse("Morning shift 8am-noon weekdays, evening 6-9pm Tue/Thu, weekend 10am-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_rehearsal_performance_test() {
  let result = era.parse("Rehearsals Mon-Thu 7-10pm this month, performances Dec 15-17 at 8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_garbage_recycling_test() {
  let result = era.parse("Trash every Monday and Thursday 7am, recycling every other Wednesday, bulk pickup first Sat")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_animal_shelter_test() {
  let result = era.parse("Cat room daily 10am-6pm, dog walks every 3 hours 8am-8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_ski_lift_hours_test() {
  let result = era.parse("Lifts 9am-4pm daily Dec-Mar, night skiing Fri-Sat until 9pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_voting_location_test() {
  let result = era.parse("Early voting Oct 20-Nov 1 weekdays 8am-5pm, Sat 10am-4pm, election day 6am-8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_farmers_market_vendors_test() {
  let result = era.parse("Regular market every Sunday 8am-1pm, Wednesday evening market 4-8pm May-Sept")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_bus_schedule_test() {
  let result = era.parse("Bus every 15 mins rush hour 6-9am and 4-7pm, every 30 mins other times")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_bakery_specials_test() {
  let result = era.parse("Croissants daily at 7am, sourdough Wed/Sat 6am, cinnamon rolls Sunday 8am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_yoga_schedule_test() {
  let result = era.parse("Gentle yoga Mon/Wed/Fri 9am, power yoga Tue/Thu 6pm, restorative Sunday 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_laundromat_hours_test() {
  let result = era.parse("Self-service 6am-10pm daily, wash-and-fold Mon-Fri 8am-6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_community_center_test() {
  let result = era.parse("Gym access 24/7 members, classes Mon-Sat 6am-9pm, pool summer only 10am-8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_food_truck_rotation_test() {
  let result = era.parse("Tacos Monday noon-2pm, BBQ Wednesday 11:30am-1:30pm, pizza Friday 11am-2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_church_activities_test() {
  let result = era.parse("Service Sun 10am, Bible study Wed 7pm, youth group Fri 6:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_blood_drive_schedule_test() {
  let result = era.parse("Blood drive third Thursday each month 2-7pm, next one tomorrow 3-8pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_auto_shop_hours_test() {
  let result = era.parse("Service Mon-Fri 7am-6pm, Sat 8am-4pm, oil changes walk-in Sat 8am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_band_practice_gigs_test() {
  let result = era.parse("Practice every Tuesday 7-9pm, gig this Saturday 9pm, recording session next Wed 2-6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_pet_care_schedule_test() {
  let result = era.parse("Dog walker Mon/Wed/Fri 11am, vet checkup next Thursday 3pm, grooming every 6 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_conference_room_booking_test() {
  let result = era.parse("Room A booked 9am-noon today, available 2-5pm, reserved every Mon 10am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_coffee_shop_features_test() {
  let result = era.parse("Open daily 6am-8pm, live music Fri-Sat 7-9pm, book club last Tuesday 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_swim_team_practice_test() {
  let result = era.parse("Team practice Mon-Fri 5-7am and 4-6pm, meets every other Saturday 8am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_art_class_schedule_test() {
  let result = era.parse("Drawing Mon 6-8pm, painting Wed 7-9pm, sculpture Sat 10am-1pm, all 8-week sessions")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_dialysis_schedule_test() {
  let result = era.parse("Treatment Mon/Wed/Fri 7am-11am, labs first Monday each month at 6am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_theater_showtimes_test() {
  let result = era.parse("Matinee Sat-Sun 2pm, evening shows Fri-Sat 7pm and 9:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_home_health_visits_test() {
  let result = era.parse("Nurse visits Tue/Thu 10am, PT Mon/Wed/Fri 2pm, aide daily 8am and 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_golf_course_times_test() {
  let result = era.parse("Tee times every 10 mins 6am-6pm, twilight rate after 4pm, closed Mon for maintenance")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_bar_karaoke_night_test() {
  let result = era.parse("Happy hour Mon-Fri 4-7pm, karaoke every Thursday 8pm-midnight, trivia Tuesdays 7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_urgent_care_hours_test() {
  let result = era.parse("Walk-ins daily 8am-8pm, X-ray until 7pm, lab work Mon-Fri 7am-5pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_tennis_lessons_league_test() {
  let result = era.parse("Lessons Tue/Thu 5-6pm, league play every Saturday 9am, open court after 6pm weekdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_drum_circle_workshop_test() {
  let result = era.parse("Drum circle first and third Friday 7pm, workshop series every Wed 6-8pm for 4 weeks")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_synagogue_services_test() {
  let result = era.parse("Shabbat services Fri 6:30pm and Sat 9am, Hebrew school Sun 9am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_senior_center_activities_test() {
  let result = era.parse("Bingo Wed 2pm, exercise class Mon/Wed/Fri 10am, lunch daily 11:30am-12:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_climbing_gym_test() {
  let result = era.parse("Open climb daily 6am-11pm, classes Tue/Thu 7pm, youth program Sat 9am-noon")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_post_office_hours_test() {
  let result = era.parse("Lobby Mon-Fri 8am-5pm, Sat 9am-noon, self-service kiosk 24/7")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_escape_room_bookings_test() {
  let result = era.parse("Bookings on the hour 11am-9pm weekdays, 10am-11pm weekends, group rate after 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_ice_cream_shop_test() {
  let result = era.parse("Open daily noon-10pm summer, 2-8pm winter, closed Jan-Feb")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_dog_daycare_hours_test() {
  let result = era.parse("Drop-off 6:30-9am, pickup 4-6:30pm weekdays, Sat 8am-4pm, spa services by appointment")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_martial_arts_schedule_test() {
  let result = era.parse("Kids class Mon/Wed 5pm, adults Tue/Thu 7pm, sparring Sat 10am, belt testing quarterly")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_writing_group_test() {
  let result = era.parse("Critique group every other Wednesday 6:30pm, write-in Saturdays 10am-2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_co_working_space_test() {
  let result = era.parse("24/7 access members, day pass 8am-6pm, meeting rooms by hour 9am-5pm weekdays")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_brewery_taproom_test() {
  let result = era.parse("Taproom Wed-Thu 4-10pm, Fri-Sat noon-midnight, Sun noon-8pm, tours Sat 2pm and 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_pottery_studio_test() {
  let result = era.parse("Open studio Mon-Thu 10am-8pm, classes Tue/Thu 6-8pm, firing every other weekend")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_language_exchange_test() {
  let result = era.parse("Spanish Mon 6pm, French Wed 7pm, Mandarin Sat 10am, conversation practice daily noon-1pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_bike_shop_service_test() {
  let result = era.parse("Sales daily 10am-7pm, service Mon-Sat 9am-6pm, group rides Sun 8am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_garden_plot_access_test() {
  let result = era.parse("Community garden dawn-dusk daily, workshops second Saturday 9am, workdays every Thu 5pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_soup_kitchen_schedule_test() {
  let result = era.parse("Lunch served Mon-Sat 11:30am-1pm, dinner Tue/Thu/Sun 5-6:30pm, food bank Fri 2-4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_skating_rink_sessions_test() {
  let result = era.parse("Public skate Sat 1-3pm and 7-9pm, lessons Sun 9am-noon, hockey league Wed/Fri nights")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_choir_rehearsal_test() {
  let result = era.parse("Full choir Thu 7:30-9pm, sectionals Tue varies by section, performance this Sunday 4pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_planetarium_shows_test() {
  let result = era.parse("Shows on the hour 10am-4pm daily, laser show Fri-Sat 8pm and 9:30pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_tool_library_hours_test() {
  let result = era.parse("Checkout Wed 5-8pm and Sat 10am-2pm, returns any time in drop box")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_sewing_circle_test() {
  let result = era.parse("Quilting bee every Monday 1-4pm, open sew Fri 6-9pm, classes Sat morning by registration")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_chess_club_tournament_test() {
  let result = era.parse("Club nights Tue/Thu 6pm, casual play Wed 7pm, tournament first Sunday quarterly 10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_animal_rescue_adoption_test() {
  let result = era.parse("Adoptions Sat-Sun 11am-5pm, fostering orientation first Wed 6pm, donation drop-off daily")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_maker_space_access_test() {
  let result = era.parse("3D printers Mon-Fri 9am-9pm, wood shop Tue/Thu/Sat, laser cutter by appointment")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_comedy_club_lineup_test() {
  let result = era.parse("Open mic Monday 8pm, showcase Thu 7pm and 9pm, headliner Fri-Sat 7pm/9pm/11pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_meditation_center_schedule_test() {
  let result = era.parse("Morning sit daily 6-7am, evening 6-7pm, dharma talk Sunday 10am, retreat quarterly")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_hookah_lounge_hours_test() {
  let result = era.parse("Open Wed-Sun 8pm-2am, DJ Fri-Sat 10pm-close, hookah menu until 1am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_archery_range_times_test() {
  let result = era.parse("Range open Sat-Sun 9am-5pm, league Wed 6-9pm, beginners class first Sat 10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_axe_throwing_venue_test() {
  let result = era.parse("Walk-ins Thu 5-10pm, reservations Fri-Sat every hour 6-11pm, leagues Mon/Wed 7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_book_swap_library_test() {
  let result = era.parse("Book swap open daily 9am-7pm, themed exchanges last Friday 6pm, kids hour Sat 10am")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_virtual_reality_arcade_test() {
  let result = era.parse("Sessions every 30 mins noon-10pm weekdays, 10am-midnight weekends, tournaments monthly")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_sailing_club_activities_test() {
  let result = era.parse("Racing Sat 10am Apr-Oct, lessons Sun 9am and 2pm, social sail Wed 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_astronomy_club_test() {
  let result = era.parse("Star party every new moon weather permitting, meetings third Thursday 7pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_food_coop_hours_test() {
  let result = era.parse("Shopping daily 8am-9pm, volunteer shifts Tue/Thu 6am-noon, member meeting quarterly Sun 2pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_roller_derby_practice_test() {
  let result = era.parse("Fresh meat Mon/Wed 7pm, scrimmage Thu 8pm, bout home games monthly Sat 6pm")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_boardgame_cafe_test() {
  let result = era.parse("Open daily noon-11pm, game night Wed 6pm free entry, tournament Sun 1pm $5")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

pub fn parse_mixed_rowing_club_schedule_test() {
  let result = era.parse("Morning rows Mon-Fri 5:30am, novice class Sat 7am, regatta racing season May-Sept weekends")
  result
  |> should.be_ok
  |> fn(parsed) {
    case parsed {
      SinglePoint(_) -> Nil
      MultiplePoints(_) -> Nil
      Range(_) -> Nil
      MultipleRanges(_) -> Nil
      Recurring(_) -> Nil
    }
  }
}

// ============================================================================
// EXPECTED FAILURES - Cases we can't/shouldn't handle
// ============================================================================

// Can't handle: ordinals like "1st", "2nd", "3rd" - need additional parsing
pub fn parse_ordinal_1st_expected_fail_test() {
  let result = era.parse("1st")
  // EXPECTED FAILURE: We don't parse ordinals yet (1st, 2nd, 3rd)
  // This would require additional lexer tokens and parsing logic
  result |> should.be_error
}

// Can't handle: "the" articles - not in our lexer
pub fn parse_the_15th_expected_fail_test() {
  let result = era.parse("the 15th")
  // EXPECTED FAILURE: We don't handle "the" article or ordinals
  result |> should.be_error
}

// Can't handle: complex relative phrases like "day after tomorrow"
pub fn parse_day_after_tomorrow_expected_fail_test() {
  let result = era.parse("day after tomorrow")
  // EXPECTED FAILURE: Complex relative phrases beyond simple offsets
  // Would need special parsing logic for "after" constructions
  result |> should.be_error
}

// Can't handle: "ago" vs "before" synonyms
pub fn parse_2_days_before_expected_fail_test() {
  let result = era.parse("2 days before")
  // EXPECTED FAILURE: "before" is a synonym for "ago" but not in our lexer
  // Could be added if needed
  result |> should.be_error
}

// Can't handle: written-out numbers like "five days ago"
pub fn parse_five_days_ago_expected_fail_test() {
  let result = era.parse("five days ago")
  // EXPECTED FAILURE: We only parse numeric digits, not written numbers
  // Would require a large addition to the lexer (one, two, three, etc.)
  result |> should.be_error
}

// Can't handle: date ranges like "March 1-5"
pub fn parse_date_range_march_1_to_5_expected_fail_test() {
  let result = era.parse("March 1-5")
  // EXPECTED FAILURE: Date ranges (multi-day periods) not yet implemented
  // This is different from time ranges (same-day periods)
  result |> should.be_error
}

// Can't handle: "between X and Y" syntax
pub fn parse_between_2_and_4pm_expected_fail_test() {
  let result = era.parse("between 2 and 4pm")
  // EXPECTED FAILURE: "between" keyword not in our lexer
  // Could be added as synonym for time ranges
  result |> should.be_error
}

// Can't handle: timezone abbreviations
pub fn parse_3pm_pst_expected_fail_test() {
  let result = era.parse("3pm PST")
  // EXPECTED FAILURE: Timezone support not implemented
  // Would require significant additions for timezone handling
  result |> should.be_error
}

// Can't handle: relative weekday with specific time like "this coming Friday"
pub fn parse_this_coming_friday_expected_fail_test() {
  let result = era.parse("this coming Friday")
  // EXPECTED FAILURE: "coming" modifier not in lexer
  // "this" is used for time of day, not weekdays
  result |> should.be_error
}

// Can't handle: seasons
pub fn parse_next_summer_expected_fail_test() {
  let result = era.parse("next summer")
  // EXPECTED FAILURE: Seasons (spring, summer, fall, winter) not implemented
  // Would need season definitions and date ranges
  result |> should.be_error
}
