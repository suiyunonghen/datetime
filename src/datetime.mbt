///|
///  日期时间类型,1899-12-30 00:00:00作为0时间
///  日期规则为到1899-12-30号的天数+当前的毫秒数/一天的总共毫秒数集合
pub(all) type DateTime Double

///|
pub(all) struct TimeZone {
  offset_hours : Int
  offset_minutes : Int
}

///|
pub fn TimeZone::new_timezone(
  offset_hours : Int,
  offset_minutes : Int
) -> TimeZone {
  { offset_hours, offset_minutes }
}

///|
pub fn TimeZone::offset_in_minutes(self : TimeZone) -> Int {
  self.offset_hours * 60 + self.offset_minutes
}

///|
pub fn DateTime::to_timezone(self : DateTime, timezone : TimeZone) -> DateTime {
  let timezone_offset = timezone.offset_in_minutes() * 60_000
  self.inc_milliseconds(timezone_offset.to_int64())
}

///|
pub fn DateTime::from_timezone(
  self : DateTime,
  timezone : TimeZone
) -> DateTime {
  let timezone_offset = timezone.offset_in_minutes() * 60_000
  self.inc_milliseconds(-timezone_offset.to_int64())
}

///|
pub fn TimeZone::difference(self : TimeZone, other : TimeZone) -> Int {
  self.offset_in_minutes() - other.offset_in_minutes()
}

//一些常量

// let utc : TimeZone = TimeZone::new_timezone(0, 0)

// let cst : TimeZone = TimeZone::new_timezone(8, 0) // 中国标准时间

// let est : TimeZone = TimeZone::new_timezone(-5, 0) // 美国东部标准时间

// let pst : TimeZone = TimeZone::new_timezone(-8, 0) // 美国太平洋标准时间

// let ist : TimeZone = TimeZone::new_timezone(5, 30) // 印度标准时间

///|
pub(all) struct SystemDate {
  dayofweek : Int
  year : Int
  month : Int
  day : Int
}

///|
pub fn SystemDate::to_datetime(self : SystemDate) -> DateTime {
  DateTime::new(self.year, self.month, self.day, 0, 0, 0, 0).unwrap()
}

///|
pub fn SystemDate::inc_month(
  self : SystemDate,
  numMonth : Int
) -> (SystemDate, Array[Int]) {
  let sign = if numMonth >= 0 { 1 } else { -1 }
  let mut year = self.year + numMonth / 12
  let numMonth = numMonth % 12
  let mut month = self.month + numMonth
  if ((month - 1) & 0xFFFF) > 11 {
    year += sign
    month = month - 12 * sign
  }
  let dayTable = if is_leap_year(year) {
    monthDayTables1
  } else {
    monthDayTables0
  }
  if self.day > dayTable[month - 1] {
    ({ year, month, day: dayTable[month - 1], dayofweek: 0 }, dayTable)
  } else {
    ({ year, month, day: self.day, dayofweek: 0 }, dayTable)
  }
}

///|
pub impl Show for SystemDate with output(self, l : &Logger) -> Unit {
  l.write_string("\{self.year}-\{self.month}-\{self.day}")
}

///|
pub(all) struct SystemTime {
  hour : Int
  minute : Int
  second : Int
  milliseconds : Int
}

///|
pub fn SystemTime::to_datetime(self : SystemTime) -> DateTime {
  DateTime::new(0, 0, 0, self.hour, self.minute, self.second, self.milliseconds).unwrap()
}

///|
pub impl Show for SystemTime with output(self, l : &Logger) -> Unit {
  l.write_string(
    "\{self.hour}:\{self.minute}:\{self.second}.\{self.milliseconds}",
  )
}

///|
pub(all) struct SystemDateTime {
  date : SystemDate
  time : SystemTime
}

///|
pub fn SystemDateTime::to_datetime(self : SystemDateTime) -> DateTime {
  DateTime::new(
    self.date.year,
    self.date.month,
    self.date.day,
    self.time.hour,
    self.time.minute,
    self.time.second,
    self.time.milliseconds,
  ).unwrap()
}

///|
pub impl Show for SystemDateTime with output(self, l : &Logger) -> Unit {
  l.write_string(
    "\{self.date.year}-\{self.date.month}-\{self.date.day} \{self.time.hour}:\{self.time.minute}:\{self.time.second}.\{self.time.milliseconds}",
  )
}

///|
const MSecondsPerMinute = 60_000

///|
const MSecondsPerDay : Int64 = 86400_000

///|
const UnixDateDeltaDays = 25569 //1899-12-30到1970-1-1天数

///|
const DateDelta = 693594 //0000-1-1到1899-12-30天数

///|
const ApproxDaysPerYear = 365.2425

///|
const ApproxDaysPerMonth = 30.436875

///|
const MSecondsPerYear : Int64 = 31_556_952_000 //365.2425*86400_000

///|
const MSecondsPerMonth : Int64 = 2_629_746_000 //30.436875*86400_000

///|
priv struct TimeStamp {
  mut time : Int //剩下的毫秒
  mut date : Int //到0001-1-1的天数
}

///|
fn TimeStamp::mseconds(self : TimeStamp) -> Int64 {
  self.date.to_int64() * MSecondsPerDay + self.time.to_int64()
}

///|
fn TimeStamp::addmseconds(self : TimeStamp, mseconds : Int64) -> Unit {
  let curms = self.date.to_int64() * MSecondsPerDay +
    self.time.to_int64() +
    mseconds
  self.date = (curms / MSecondsPerDay).to_int()
  self.time = (curms % MSecondsPerDay).to_int()
}

///|
fn TimeStamp::datetime(self : TimeStamp) -> DateTime {
  ((self.date - DateDelta).to_int64() * MSecondsPerDay + self.time.to_int64()).to_double() /
  MSecondsPerDay.to_double()
}

///|
fn DateTime::timestamp(self : DateTime) -> TimeStamp {
  let date = self._.to_int()
  {
    date: date + DateDelta,
    time: ((self._ - date.to_double()) * MSecondsPerDay.to_double()).to_int(),
  }
}

///|
pub fn DateTime::inc_milliseconds(
  self : DateTime,
  milliseconds : Int64
) -> DateTime {
  let ts = self.timestamp()
  ts.addmseconds(milliseconds)
  ts.datetime()
}

///|
pub fn DateTime::inc_seconds(self : DateTime, seconds : Int64) -> DateTime {
  self.inc_milliseconds(seconds * 1000)
}

///|
pub fn DateTime::inc_minutes(self : DateTime, minutes : Int64) -> DateTime {
  self.inc_milliseconds(minutes * 60_000)
}

///|
pub fn DateTime::inc_hour(self : DateTime, hour : Int64) -> DateTime {
  self.inc_milliseconds(hour * 3600_000)
}

///|
pub fn DateTime::milliseconds(self : DateTime) -> Int64 {
  self.timestamp().mseconds()
}

///|
pub fn DateTime::unix_millseconds(self : DateTime) -> Int64 {
  ((self._ - UnixDateDeltaDays.to_double()) * MSecondsPerDay.to_double()).to_int64()
}

///|
pub fn DateTime::unix_seconds(self : DateTime) -> Int64 {
  ((self._ - UnixDateDeltaDays.to_double()) * 86400).to_int64()
}

///|
pub fn is_leap_year(year : Int) -> Bool {
  year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

///|
const D1 = 365

///|
const D4 = 1461 //D1 * 4 + 1;

///|
const D100 = 36524 //D4 * 25 - 1;

///|
const D400 = 146097 //D100 * 4 + 1;

///|
let monthDayTables0 : Array[Int] = [
  31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
]

///|
let monthDayTables1 : Array[Int] = [
  31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
]

///|
pub impl Show for DateTime with output(self, l : &Logger) -> Unit {
  if self._ < 1 && self._ != 0 {
    let time = self.decode_time()
    l.write_string(
      "\{time.hour}:\{time.minute}:\{time.second}.\{time.milliseconds}",
    )
  } else {
    let date = self.decode_date()
    let time = self.decode_time()
    l.write_string(
      "\{date.year}-\{date.month}-\{date.day} \{time.hour}:\{time.minute}:\{time.second}.\{time.milliseconds}",
    )
  }
}

///|
pub fn DateTime::decode_date(self : DateTime) -> SystemDate {
  let mut date = self._.to_int() + DateDelta
  if date < 0 {
    { year: 0, month: 0, day: 0, dayofweek: 0 }
  } else {
    let dow = date % 7 + 1
    date -= 1
    let mut year = 1
    while date >= D400 {
      date -= D400
      year += 400
    }
    let mut i = date / D100
    let mut d = date % D100
    if i == 4 {
      i -= 1
      d += D100
    }
    year += i * 100
    i = d / D4
    d = d % D4
    year += i * 4
    i = d / D1
    d = d % D1
    if i == 4 {
      i -= 1
      d += D1
    }
    year += i
    let dayTable = if is_leap_year(year) {
      monthDayTables1
    } else {
      monthDayTables0
    }
    let mut m = 0
    while true {
      i = dayTable[m]
      if d < i {
        break
      }
      d -= i
      m += 1
    }
    { year, month: m + 1, day: d + 1, dayofweek: dow - 1 }
  }
}

///|
pub fn DateTime::decode_time(self : DateTime) -> SystemTime {
  let time = ((self._ - self._.to_int().to_double()) *
  MSecondsPerDay.to_double()).to_int()
  let minCount = time / MSecondsPerMinute
  let msecCount = time % MSecondsPerMinute
  {
    hour: minCount / 60,
    minute: minCount % 60,
    second: msecCount / 1000,
    milliseconds: msecCount % 1000,
  }
}

///|
pub fn DateTime::decode(self : DateTime) -> SystemDateTime {
  { date: self.decode_date(), time: self.decode_time() }
}

///|
pub fn DateTime::from_unix_seconds(seconds : Int64) -> DateTime {
  DateTime(UnixDateDeltaDays.to_double()).inc_milliseconds(seconds * 1000)
}

///|
pub fn DateTime::from_unix_mseconds(seconds : Int64) -> DateTime {
  DateTime(UnixDateDeltaDays.to_double()).inc_milliseconds(seconds)
}

///|
pub fn DateTime::new_date(year : Int, month : Int, day : Int) -> DateTime? {
  let dayTable = if is_leap_year(year) {
    monthDayTables1
  } else {
    monthDayTables0
  }
  if year >= 1 &&
    year <= 9999 &&
    month >= 1 &&
    month <= 12 &&
    day >= 1 &&
    day <= dayTable[month - 1] {
    let mut day = day
    for i in 0..<(month - 1) {
      day += dayTable[i]
    }
    let i = year - 1
    Some(
      DateTime(
        (i * 365 + i / 4 - i / 100 + i / 400 + day - DateDelta).to_double(),
      ),
    )
  } else {
    None
  }
}

///|
pub fn DateTime::new_time(
  hour : Int,
  minute : Int,
  seconds : Int,
  milliseconds : Int
) -> DateTime? {
  if hour < 24 && minute < 60 && seconds < 60 && milliseconds < 1000 {
    Some(
      (hour * 3600_000 + minute * 60_000 + seconds * 1000 + milliseconds).to_double() /
      MSecondsPerDay.to_double(),
    )
  } else {
    None
  }
}

///|
pub fn DateTime::new(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  seconds : Int,
  milliseconds : Int
) -> DateTime? {
  let dayTable = if is_leap_year(year) {
    monthDayTables1
  } else {
    monthDayTables0
  }
  if year >= 1 &&
    year <= 9999 &&
    month >= 1 &&
    month <= 12 &&
    day >= 1 &&
    day <= dayTable[month - 1] &&
    hour < 24 &&
    minute < 60 &&
    seconds < 60 &&
    milliseconds < 1000 {
    let mut day = day
    for i in 0..<(month - 1) {
      day += dayTable[i]
    }
    let i = year - 1
    let dayms_percent = (hour * 3600_000 +
      minute * 60_000 +
      seconds * 1000 +
      milliseconds).to_double() /
      MSecondsPerDay.to_double()
    Some(
      (i * 365 + i / 4 - i / 100 + i / 400 + day - DateDelta).to_double() +
      dayms_percent,
    )
  } else {
    None
  }
}

//difference in days
///|
pub impl Sub for DateTime with op_sub(self : DateTime, other : DateTime) -> DateTime {
  self._ - other._
}

//number of days between time intervals
///|
pub fn DateTime::day_span(self : DateTime, then : DateTime) -> Double {
  if self._ < then._ {
    then._ - self._
  } else {
    self._ - then._
  }
}

///|
pub fn DateTime::year_span(self : DateTime, then : DateTime) -> Double {
  self.day_span(then) / ApproxDaysPerYear
}

///|
pub fn DateTime::month_span(self : DateTime, then : DateTime) -> Double {
  self.day_span(then) / ApproxDaysPerMonth
}

///|
pub fn DateTime::week_span(self : DateTime, then : DateTime) -> Double {
  self.day_span(then) / 7
}

///|
pub fn DateTime::hours_between(self : DateTime, then : DateTime) -> Int64 {
  let delta = self.milliseconds() - then.milliseconds()
  if delta < 0 {
    -delta / 3600_000
  } else {
    delta / 3600_000
  }
}

///|
pub fn DateTime::minutes_between(self : DateTime, then : DateTime) -> Int64 {
  let delta = self.milliseconds() - then.milliseconds()
  let delta_abs = if delta < 0 { -delta } else { delta }
  delta_abs / 60_000
}

///|
pub fn DateTime::seconds_between(self : DateTime, then : DateTime) -> Int64 {
  let delta = self.milliseconds() - then.milliseconds()
  if delta < 0 {
    -delta / 1000
  } else {
    delta / 1000
  }
}

///|
pub fn DateTime::milliseconds_between(
  self : DateTime,
  then : DateTime
) -> Int64 {
  let delta = self.milliseconds() - then.milliseconds()
  if delta < 0 {
    -delta
  } else {
    delta
  }
}

///|
pub fn DateTime::years_between(self : DateTime, then : DateTime) -> Int {
  let delta = self.milliseconds() - then.milliseconds()
  if delta < 0 {
    (-delta / MSecondsPerYear).to_int()
  } else {
    (delta / MSecondsPerYear).to_int()
  }
}

///|
pub fn DateTime::months_between(self : DateTime, then : DateTime) -> Int {
  let delta = self.milliseconds() - then.milliseconds()
  if delta < 0 {
    (-delta / MSecondsPerMonth).to_int()
  } else {
    (delta / MSecondsPerMonth).to_int()
  }
}

///|
pub fn DateTime::days_between(self : DateTime, then : DateTime) -> Int {
  let delta = self.milliseconds() - then.milliseconds()
  if delta < 0 {
    (-delta / MSecondsPerDay).to_int()
  } else {
    (delta / MSecondsPerDay).to_int()
  }
}

///|
pub fn DateTime::inc_month(self : DateTime, monthNum : Int) -> DateTime {
  let date = self.decode_date()
  let time = self._ - self._.to_int().to_double()
  let (date, dayTable) = date.inc_month(monthNum)
  let mut day = date.day
  for i in 0..<(date.month - 1) {
    day += dayTable[i]
  }
  let i = date.year - 1
  (i * 365 + i / 4 - i / 100 + i / 400 + day - DateDelta).to_double() + time
}

///|
pub fn DateTime::inc_year(self : DateTime, yearNum : Int) -> DateTime {
  self.inc_month(yearNum * 12)
}

///|
pub fn DateTime::inc_day(self : DateTime, days : Int) -> DateTime {
  self.inc_milliseconds(MSecondsPerDay * days.to_int64())
}

///|
fn index_of_char(str : String, ch : Int, from~ : Int = 0) -> Int {
  let l = str.length()
  for i in from..<l {
    if str.charcode_at(i) == ch {
      return i
    }
  }
  -1
}

///|
fn index_of_char_ex(str : String, f : (Int) -> Bool, from~ : Int = 0) -> Int {
  let l = str.length()
  for i in from..<l {
    if f(str.charcode_at(i)) {
      return i
    }
  }
  -1
}

///|
/// datetime formats
/// YYYY-MM-DD HH:MM:SS.zzz(+hh:mm)
/// YYYY-MM-DDTHH:MM:SS.zzz(-hh::mm)
/// YYYY-MM-DD
/// YY-MM-DD
/// HH:MM:SS.zzz(+hh:mm)
/// HH:MM:SS(-hh:mm)
pub fn DateTime::parse_datetime(str : String) -> DateTime!@strconv.StrConvError {
  let mut year = 0
  let mut month = 0
  let mut day = 0
  let timeIndex = loop index_of_char(str, '-'), 0, 0 {
    index, seg_index, start => {
      match seg_index {
        0 => {
          if index < 0 {
            break 0
          }
          //year
          let l = index - start
          if l != 2 && l != 4 {
            raise @strconv.StrConvError("invalid year syntax")
          }
          let year_str = str.substring(start~, end=index)
          match @strconv.parse_int?(year_str) {
            Ok(y) => year = if l == 4 { y } else { y + 2000 }
            _ => raise @strconv.StrConvError("invalid year syntax")
          }
        }
        1 => {
          if index < 0 {
            raise @strconv.StrConvError("invalid month syntax")
          }
          //month
          let mut l = index - start
          if l != 1 && l != 2 {
            raise @strconv.StrConvError("invalid month syntax")
          }
          let month_str = str.substring(start~, end=index)
          match @strconv.parse_int?(month_str) {
            Ok(m) => {
              if m < 1 || m > 12 {
                raise @strconv.StrConvError("invalid month syntax")
              }
              month = m
            }
            _ => raise @strconv.StrConvError("invalid month syntax")
          }
          let day_start = index + 1
          //找day
          let next = index_of_char_ex(
            str,
            fn(ch) { ch == ' ' || ch == 'T' || ch == 't' },
            from=day_start,
          )
          l = if next == -1 {
            //没有时间
            str.length() - day_start
          } else {
            next - day_start
          }
          if l != 1 && l != 2 {
            raise @strconv.StrConvError("invalid day syntax")
          }
          let day_str = str.substring(start=day_start, end=day_start + l)
          match @strconv.parse_int?(day_str) {
            Ok(d) => {
              if d < 1 || d > 31 {
                raise @strconv.StrConvError("invalid day syntax")
              }
              let dayTable = if is_leap_year(year) {
                monthDayTables1
              } else {
                monthDayTables0
              }
              if d > dayTable[month - 1] {
                raise @strconv.StrConvError("invalid day syntax")
              }
              day = d
              if next >= 0 {
                break next + 1
              }
              break -1
            }
            _ => raise @strconv.StrConvError("invalid day syntax")
          }
        }
        _ => break 0
      }
      continue index_of_char(str, '-', from=index + 1), seg_index + 1, index + 1
    }
  }
  if timeIndex == -1 {
    return DateTime::new(year, month, day, 0, 0, 0, 0).unwrap()
  }
  let mut hour = 0
  let mut minute = 0
  let mut second = 0
  let mut millisecond = 0
  let mut timezone_index = -1
  loop index_of_char(str, ':', from=timeIndex), 0, timeIndex {
    index, seg_index, start => {
      match seg_index {
        0 => {
          //hour
          if index < 0 {
            raise @strconv.StrConvError("invalid hour syntax")
          }
          let l = index - start
          if l != 2 && l != 4 {
            raise @strconv.StrConvError("invalid hour syntax")
          }
          let hour_str = str.substring(start~, end=index)
          match @strconv.parse_int?(hour_str) {
            Ok(h) => {
              if h > 23 {
                raise @strconv.StrConvError("invalid hour syntax")
              }
              hour = h
            }
            _ => raise @strconv.StrConvError("invalid hour syntax")
          }
        }
        1 => {
          //minute
          if index < 0 {
            raise @strconv.StrConvError("invalid hour syntax")
          }
          let mut l = index - start
          if l != 1 && l != 2 {
            raise @strconv.StrConvError("invalid hour syntax")
          }
          let minute_str = str.substring(start~, end=index)
          match @strconv.parse_int?(minute_str) {
            Ok(m) => {
              if m < 0 || m > 59 {
                raise @strconv.StrConvError("invalid minute syntax")
              }
              minute = m
            }
            _ => raise @strconv.StrConvError("invalid minute syntax")
          }
          let sec_start = index + 1
          let mut next = index_of_char(str, '.', from=sec_start)
          if next == -1 {
            next = index_of_char(str, '+', from=sec_start)
            if next == -1 {
              next = index_of_char(str, '-', from=sec_start)
            }
            timezone_index = next
          }
          l = if next == -1 {
            str.length() - sec_start
          } else {
            next - sec_start
          }
          if l != 1 && l != 2 {
            raise @strconv.StrConvError("invalid seconds syntax")
          }
          match
            @strconv.parse_int?(
              str.substring(start=sec_start, end=sec_start + l),
            ) {
            Ok(sec) => {
              if sec > 59 {
                raise @strconv.StrConvError("invalid seconds syntax")
              }
              second = sec
              if timezone_index != -1 {
                break
              }
              if next == -1 {
                return DateTime::new(year, month, day, hour, minute, second, 0).unwrap()
              }
              let mut ms_end = str.length()
              l = ms_end - next - 1
              if l > 3 {
                //timezone                
                timezone_index = index_of_char(from=index + 1, str, '+')
                if timezone_index == -1 {
                  timezone_index = index_of_char(from=index + 1, str, '-')
                }
                if timezone_index == -1 {
                  raise @strconv.StrConvError("invalid timezone syntax")
                }
                ms_end = timezone_index
                l = timezone_index - next - 1
                if l > 3 {
                  raise @strconv.StrConvError("invalid millseconds syntax")
                }
              }
              match
                @strconv.parse_int?(str.substring(start=next + 1, end=ms_end)) {
                Ok(ms) => {
                  if timezone_index == -1 {
                    return DateTime::new(
                      year, month, day, hour, minute, second, ms,
                    ).unwrap()
                  }
                  millisecond = ms
                  break
                }
                _ => raise @strconv.StrConvError("invalid millseconds syntax")
              }
            }
            _ => raise @strconv.StrConvError("invalid seconds syntax")
          }
        }
        _ => raise @strconv.StrConvError("invalid syntax")
      }
      continue index_of_char(str, ':', from=index + 1), seg_index + 1, index + 1
    }
  }

  // 解析时区部分
  let sign = if str.charcode_at(timezone_index) == '+' { 1 } else { -1 }
  let timezone_start = timezone_index + 1
  let next = index_of_char(str, ':', from=timezone_start)
  if next == -1 {
    raise @strconv.StrConvError("invalid timezone syntax")
  }
  let offset_hours_str = str.substring(start=timezone_start, end=next)
  let offset_minutes_str = str.substring(start=next + 1)
  match @strconv.parse_int?(offset_hours_str) {
    Ok(offset_hours) =>
      match @strconv.parse_int?(offset_minutes_str) {
        Ok(offset_minutes) => {
          let offset_hours = offset_hours * sign
          let offset_minutes = offset_minutes * sign
          let timezone = TimeZone::new_timezone(offset_hours, offset_minutes)
          let datetime = DateTime::new(
            year, month, day, hour, minute, second, millisecond,
          ).unwrap()
          let timezone_offset = timezone.offset_in_minutes() * 60_000
          datetime.inc_milliseconds(-timezone_offset.to_int64())
        }
        _ => raise @strconv.StrConvError("invalid timezone syntax")
      }
    _ => raise @strconv.StrConvError("invalid timezone syntax")
  }
}

///|
pub impl @strconv.FromStr for DateTime with from_string(str) {
  DateTime::parse_datetime!(str)
}

///|
test "parse datetime" {
  match DateTime::parse_datetime?("2024-12-03 12:32:33.33+19:00") {
    Ok(v) => println(v)
    _ => println("err")
  }
}

///|
test "new datetime" {
  let t = DateTime(0)
  println(t)
  let date1 = DateTime::new(2024, 11, 18, 18, 23, 43, 199).unwrap()
  let date = date1.decode_date()
  let week = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
  ]
  println("\{date.year}-\{date.month}-\{date.day} \{week[date.dayofweek-1]}")
  let time = date1.decode_time()
  println("\{time.hour}:\{time.minute}:\{time.second}.\{time.milliseconds}")
  assert_eq!(Show::to_string(date1), "2024-11-18 18:23:43.199")
  assert_eq!(Show::to_string(date1.inc_month(-13)), "2023-10-18 18:23:43.199")
  assert_eq!(Show::to_string(date1.inc_hour(24)), "2024-11-19 18:23:43.199")
  let date2 = DateTime::from_unix_seconds(1731934794)
  assert_eq!(Show::to_string(date2), "2024-11-18 12:59:54.0")
  println(date2.unix_seconds())
}
