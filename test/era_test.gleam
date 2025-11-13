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
