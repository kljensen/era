# era

Era is a [gleam](https://gleam.run/) library for parsing natural dates like "next Tuesday at 4pm". It can return three kinds of dates

* Points in time, like "next Tuesday at 4pm"
* Time ranges, like "next Tuesday 4-5pm"
* Recurrances of either of those "every Tuesday 4-5pm until March"

As much as possible, the library uses parser combinators from [nibble](https://github.com/hayleigh-dot-dev/nibble). The library has extensive tests lifted from related projects (see below).

## Hex

[![Package Version](https://img.shields.io/hexpm/v/era)](https://hex.pm/packages/era)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/era/)


Further documentation can be found at <https://hexdocs.pm/era>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Related projects


### Go
- **[kronos](https://github.com/kljensen/kronos)** 
- **[when](https://github.com/olebedev/when)** - Natural language date/time parser with pluggable rules and merge strategies. Supports multiple languages (EN, RU, PT_BR, ZH, NL). Parses expressions like "next wednesday at 2:25 p.m" and "tomorrow at noon".
- **[go-dateparser](https://github.com/markusmobius/go-dateparser)** - Port of Python's dateparser library supporting 200+ language locales. Handles relative dates like "1 min ago", "2 weeks ago", "in 2 days", "tomorrow".
- **[go-naturaldate](https://github.com/tj/go-naturaldate)** - Natural date/time parsing for human-friendly relative date/time ranges. Defaults to past direction for ambiguous expressions.
- **[go-anytime](https://github.com/ijt/go-anytime)** - Parse natural and standardized dates/times and ranges without knowing the format in advance.
- **[dateparse](https://github.com/araddon/dateparse)** - Parse many date strings without knowing format in advance. While not strictly "natural language," it's very flexible for parsing various date formats automatically.

### JavaScript/TypeScript
- **[chrono](https://github.com/wanasit/chrono)** - The original JavaScript library that inspired Kronos. Supports multiple languages (en, ja, fr, nl, ru, uk, and partial support for de, es, pt, zh.hant). Available as `chrono-node` on npm.

### Python
- **[dateparser](https://github.com/scrapinghub/dateparser)** - Comprehensive Python library supporting 200+ language locales. Parses specific dates ('5:47pm 29th of December, 2015') and relative imes ('10 minutes ago'). Built on top of dateutil.parser with enhanced natural language support.
- **[parsedatetime](https://github.com/bear/parsedatetime)** - Parses natural language dates with strong support for relative dates like 'tomorrow'. Supports multiple locales but requires manual specification.
- **[timefhuman](https://github.com/alvinwan/timefhuman)** - Extracts datetimes and durations from natural language text. Supports ranges, lists, and more complex expressions.

### Ruby
- **[chronic](https://github.com/mojombo/chronic)** - Pure Ruby natural language date parser. Handles a huge variety of date/time formats with case-insensitive parsing and common abbreviation/misspelling support.

### Java
- **[Natty](https://github.com/joestelmach/natty)** - Natural language date parser applying standard language recognition and translation techniques. Handles complex patterns like "2 wednesdays from now".
- **[PrettyTime::NLP](https://www.ocpsoft.org/prettytime/nlp/)** - Wraps Natty for parsing natural language date/time expressions with integration into the PrettyTime formatting library.

### C# / .NET
- **[Microsoft.Recognizers.Text](https://github.com/microsoft/Recognizers-Text)** - Microsoft's comprehensive recognizer for dates, times, numbers, and more from natural language text.
- **[Chronic .NET](https://github.com/mojombo/chronic/wiki/.NET-Ports)** - .NET port of the Ruby Chronic library for natural language date parsing.

### PHP
- **[Carbon](https://github.com/briannesbitt/Carbon)** - Popular PHP API extension for DateTime with natural language parsing support ('tomorrow', 'next wednesday', '1 year ago'). Supports 200+ languages and 500+ regional variants.

### Rust
- **[dateparser](https://crates.io/crates/dateparser)** - Parses date strings in commonly used formats, returning chrono DateTime objects. Supports unix timestamps, RFC formats, and various common date formats.
- **[temps-chrono](https://lib.rs/crates/temps-chrono)** - Parses human-readable time expressions in multiple languages (English, German). Handles "in 2 hours", "tomorrow at 2:00 pm", "next tuesday".

### Swift / iOS
- **[NSDataDetector](https://developer.apple.com/documentation/foundation/nsdatadetector)** - Apple's Foundation framework class for detecting dates, times, addresses, and other data types in natural language text. Limited natural language support (works for specific dates but not relative expressions like "last week").
- **[SoulverCore](https://github.com/soulverteam/SoulverDateFromString)** - Advanced natural language date input library for Mac and iOS apps.

### Kotlin / Android
- **[Natty](http://natty.joestelmach.com/)** - Same Java library usable in Kotlin/Android projects for natural language date parsing.
- **[Hawking](https://github.com/zoho/hawking)** - Natural Language Date Time Parser that extracts date/time from text with context.

### Perl
- **[DateTime::Format::Natural](https://metacpan.org/pod/DateTime::Format::Natural)** - Parses informal natural language date/time strings into DateTime objects. Handles "tomorrow", "next Tuesday", "1 hour ago".
- **[Date::Manip](https://metacpan.org/pod/Date::Manip)** - Powerful date manipulation and parsing module for human-formatted dates. Most comprehensive but also largest and slowest Perl date module.

### Elixir
- **[Timex](https://github.com/bitwalker/timex)** - Complete date/time library for Elixir with timezone support. Primarily handles structured formats (ISO 8601, RFC 1123, custom format strings) with limited natural language support.

### Scala
- **[nscala-time](https://github.com/nscala-time/nscala-time)** - Scala wrapper around Joda-Time with more idiomatic Scala syntax. Focused on improving expressiveness rather than advanced natural language parsing.

### C++
- **[Howard Hinnant's date library](https://github.com/HowardHinnant/date)** - Comprehensive date/time library based on C++11/14/17 `<chrono>`. Includes IANA timezone database parser. Focuses on format-based parsing rather than natural language.
