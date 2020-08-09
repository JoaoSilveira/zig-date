const std = @import("std");
const root = @import("root");

pub const DateTimeOptions = struct {
    months_short_cap: [12][]const u8,
    months_short_low: [12][]const u8,
    months_cap: [12][]const u8,
    months_low: [12][]const u8,
    am_low: []const u8,
    pm_low: []const u8,
    am_up: []const u8,
    pm_up: []const u8,
    weekdays_short_cap: [7][]const u8,
    weekdays_short_low: [7][]const u8,
    weekdays_cap: [7][]const u8,
    weekdays_low: [7][]const u8,
};

const default_options = DateTimeOptions{
    .months_short_cap = [_][]const u8{
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
    },
    .months_short_low = [_][]const u8{
        "jan",
        "feb",
        "mar",
        "apr",
        "may",
        "jun",
        "jul",
        "aug",
        "sep",
        "oct",
        "nov",
        "dec",
    },
    .months_cap = [_][]const u8{
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
    },
    .months_low = [_][]const u8{
        "january",
        "february",
        "march",
        "april",
        "may",
        "june",
        "july",
        "august",
        "september",
        "october",
        "november",
        "december",
    },
    .am_low = "am",
    .pm_low = "pm",
    .am_up = "AM",
    .pm_up = "PM",
    .weekdays_short_cap = [_][]const u8{
        "Sun",
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
    },
    .weekdays_short_low = [_][]const u8{
        "sun",
        "mon",
        "tue",
        "wed",
        "thu",
        "fri",
        "sat",
    },
    .weekdays_cap = [_][]const u8{
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    },
    .weekdays_low = [_][]const u8{
        "sunday",
        "monday",
        "tuesday",
        "wednesday",
        "thursday",
        "friday",
        "saturday",
    },
};

const date_time_options: DateTimeOptions = if (@hasDecl(root, "date_time_options")) root.date_time_options else default_options;

pub const DateTime = struct {
    const Self = @This();

    year: i32,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
    millisecond: u16,
    day_of_the_year: u16,
    is_leap_year: bool,
    weekday: u8,

    const FormatState = enum {
        Year,
        Year2,
        Year3,
        Year4,
        Month,
        Month2,
        MonthShortCapitalized,
        MonthShortLower,
        MonthCapitalized,
        MonthLower,
        Day,
        Day2,
        WeekdayShortLower,
        WeekdayShortCapitalized,
        WeekdayLower,
        WeekdayCapitalized,
        Hour12,
        Hour24,
        Hour12_2,
        Hour24_2,
        AmPmLower,
        AmPmUpper,
        Minute,
        Minute2,
        Second,
        Second2,
        Millisecond,
        Millisecond1,
        Millisecond2,
        Millisecond3,
        Literal,
    };

    /// Formats date and time values
    ///
    /// - `y`: year
    /// - `yy`: zero-filled 2 digit year
    /// - `yyy`: zero-filled 3 digit year
    /// - `yyyy`: zero-filled 4 digit year, will grow if year has more digits
    /// - `M`: month
    /// - `MM`: zero-filled 2 digit month
    /// - `MMM`: short month name capitalized
    /// - `MMm`: short month name lower case
    /// - `MMmm`: month name lower case
    /// - `d`: day
    /// - `dd`: zero-filled 2 digit day
    /// - `w`: short week day name lower case
    /// - `W`: short week day name Capitalized
    /// - `ww`: week day name lower case
    /// - `WW`: week day name Capitalized
    /// - `H`: hours in 24 hours style
    /// - `HH`: zero-filled 2 digit hours in 24 hours style
    /// - `h`: hours in 12 hours style
    /// - `hh`: zero-filled 2 digit hours in 12 hours style
    /// - `a`: am/pm lower case
    /// - `A`: AM/PM upper case
    /// - `m`: minute
    /// - `mm`: zero-filled 2 digit minute
    /// - `s`: second
    /// - `ss`: zero-filled 2 digit second
    /// - `N`: millisecond
    /// - `n`: most significant digit of millisecond *2*71
    /// - `nn`: zero-filled 2 digit millisecond *03*1
    /// - `nnn`: zero-filled 3 digit millisecond
    /// - *else*: character is escaped
    pub fn format(self: Self, comptime fmt: []const u8, writer: anytype) !void {
        if (fmt.len == 0) return format(self, "yyyy-MM-ddThh:mm:ss.nnnZ", writer);

        comptime var start: usize = 0;
        comptime var state = FormatState.Literal;
        comptime var new_state = FormatState.Literal;

        const StateMachineResult = struct {
            print: bool = false,
            state: FormatState,

            fn from(s: FormatState) @This() {
                return .{
                    .state = s,
                };
            }
        };

        const aux = struct {
            fn stateFromChar(char: u8) FormatState {
                return switch (char) {
                    'y' => .Year,
                    'M' => .Month,
                    'd' => .Day,
                    'h' => .Hour12,
                    'H' => .Hour24,
                    'm' => .Minute,
                    's' => .Second,
                    'N' => .Millisecond,
                    'n' => .Millisecond1,
                    'a' => .AmPmLower,
                    'A' => .AmPmUpper,
                    else => .Literal,
                };
            }

            fn formatInt(int_value: anytype, options: std.fmt.FormatOptions, w: anytype) !void {
                if (!@TypeOf(int_value).is_signed) {
                    return std.fmt.formatInt(int_value, 10, false, options, w);
                }

                if (int_value < 0) {
                    try w.writeByte('-');
                    const new_value = std.math.absCast(int_value);
                    return std.fmt.formatInt(new_value, 10, false, options, w);
                }

                const IntType = std.meta.Int(false, @typeInfo(@TypeOf(int_value)).Int.bits);
                return std.fmt.formatInt(@intCast(IntType, int_value), 10, false, options, w);
            }

            fn stateMachine(comptime c: u8) StateMachineResult {
                switch (state) {
                    .Year => {
                        if (c == 'y') return StateMachineResult.from(.Year2);
                    },
                    .Year2 => {
                        if (c == 'y') return StateMachineResult.from(.Year3);
                    },
                    .Year3 => {
                        if (c == 'y') return StateMachineResult.from(.Year4);
                    },
                    .Month => {
                        if (c == 'M') return StateMachineResult.from(.Month2);
                    },
                    .Month2 => {
                        switch (c) {
                            'm' => return StateMachineResult.from(.MonthShortLower),
                            'M' => return StateMachineResult.from(.MonthShortCapitalized),
                            else => {},
                        }
                    },
                    .MonthShortLower => {
                        if (c == 'm') return StateMachineResult.from(.MonthLower);
                    },
                    .MonthShortCapitalized => {
                        if (c == 'M') return StateMachineResult.from(.MonthCapitalized);
                    },
                    .Day => {
                        if (c == 'd') return StateMachineResult.from(.Day2);
                    },
                    .WeekdayShortLower => {
                        if (c == 'w') return StateMachineResult.from(.WeekdayLower);
                    },
                    .WeekdayShortCapitalized => {
                        if (c == 'W') return StateMachineResult.from(.WeekdayCapitalized);
                    },
                    .Hour24 => {
                        if (c == 'H') return StateMachineResult.from(.Hour24_2);
                    },
                    .Hour12 => {
                        if (c == 'h') return StateMachineResult.from(.Hour12_2);
                    },
                    .Minute => {
                        if (c == 'm') return StateMachineResult.from(.Minute2);
                    },
                    .Second => {
                        if (c == 's') return StateMachineResult.from(.Second2);
                    },
                    .Millisecond1 => {
                        if (c == 'n') return StateMachineResult.from(.Millisecond2);
                    },
                    .Millisecond2 => {
                        if (c == 'n') return StateMachineResult.from(.Millisecond3);
                    },
                    .Literal => {
                        // accumulates literals to print all once
                        if (new_state == .Literal) return StateMachineResult.from(.Literal);
                    },
                    else => {},
                }

                return .{
                    .state = new_state,
                    .print = true,
                };
            }

            fn printState(v: DateTime, w: anytype, comptime f: []const u8, comptime end: usize) !void {
                switch (state) {
                    .Year => {
                        try formatInt(v.year, .{}, w);
                    },
                    .Year2 => {
                        try formatInt(
                            @rem(v.year, 100),
                            .{ .width = 2, .fill = '0' },
                            w,
                        );
                    },
                    .Year3 => {
                        try formatInt(
                            @rem(v.year, 1000),
                            .{ .width = 3, .fill = '0' },
                            w,
                        );
                    },
                    .Year4 => {
                        try formatInt(
                            v.year,
                            .{ .width = 4, .fill = '0' },
                            w,
                        );
                    },
                    .Month => {
                        try formatInt(v.month, .{}, w);
                    },
                    .Month2 => {
                        try formatInt(
                            v.month,
                            .{ .width = 2, .fill = '0' },
                            w,
                        );
                    },
                    .MonthShortLower => {
                        try w.writeAll(date_time_options.months_short_low[v.month - 1]);
                    },
                    .MonthShortCapitalized => {
                        try w.writeAll(date_time_options.months_short_cap[v.month - 1]);
                    },
                    .MonthLower => {
                        try w.writeAll(date_time_options.months_low[v.month - 1]);
                    },
                    .MonthCapitalized => {
                        try w.writeAll(date_time_options.months_cap[v.month - 1]);
                    },
                    .Day => {
                        try formatInt(v.day, .{}, w);
                    },
                    .Day2 => {
                        try formatInt(
                            v.day,
                            .{ .width = 2, .fill = '0' },
                            w,
                        );
                    },
                    .WeekdayShortLower => {
                        try w.writeAll(date_time_options.weekdays_short_low[v.weekday]);
                    },
                    .WeekdayShortCapitalized => {
                        try w.writeAll(date_time_options.weekdays_short_cap[v.weekday]);
                    },
                    .WeekdayLower => {
                        try w.writeAll(date_time_options.weekdays_low[v.weekday]);
                    },
                    .WeekdayCapitalized => {
                        try w.writeAll(date_time_options.weekdays_cap[v.weekday]);
                    },
                    .Hour24 => {
                        try formatInt(v.hour, .{}, w);
                    },
                    .Hour12 => {
                        var hour = @mod(v.hour, 12);
                        if (hour == 0) hour = 12;
                        try formatInt(hour, .{}, w);
                    },
                    .Hour24_2 => {
                        try formatInt(v.hour, .{ .width = 2, .fill = '0' }, w);
                    },
                    .Hour12_2 => {
                        var hour = @mod(v.hour, 12);
                        if (hour == 0) hour = 12;
                        try formatInt(hour, .{ .width = 2, .fill = '0' }, w);
                    },
                    .AmPmLower => {
                        try w.writeAll(
                            if (v.hour >= 12) date_time_options.pm_low else date_time_options.am_low,
                        );
                    },
                    .AmPmUpper => {
                        try w.writeAll(
                            if (v.hour >= 12) date_time_options.pm_up else date_time_options.am_up,
                        );
                    },
                    .Minute => {
                        try formatInt(v.minute, .{}, w);
                    },
                    .Minute2 => {
                        try formatInt(v.minute, .{ .width = 2, .fill = '0' }, w);
                    },
                    .Second => {
                        try formatInt(v.second, .{}, w);
                    },
                    .Second2 => {
                        try formatInt(v.second, .{ .width = 2, .fill = '0' }, w);
                    },
                    .Millisecond => {
                        try formatInt(v.millisecond, .{}, w);
                    },
                    .Millisecond1 => {
                        try formatInt(v.millisecond / 100, .{}, w);
                    },
                    .Millisecond2 => {
                        try formatInt(v.millisecond / 10, .{ .width = 2, .fill = '0' }, w);
                    },
                    .Millisecond3 => {
                        try formatInt(v.millisecond, .{ .width = 3, .fill = '0' }, w);
                    },
                    .Literal => {
                        try w.writeAll(f[start..end]);
                    },
                }
            }
        };

        inline for (fmt) |c, i| {
            new_state = comptime aux.stateFromChar(c);

            if (start == i) {
                state = new_state;
                continue;
            }

            comptime const res = aux.stateMachine(c);

            if (res.print) {
                try aux.printState(self, writer, fmt, i);
                start = i;
            }
            state = res.state;
        }

        return aux.printState(self, writer, fmt, fmt.len);
    }
};

pub const GregorianDateTime = struct {
    const Self = @This();

    const days_in_year = 365;
    const days_in_four_years = days_in_year * 4 + 1; // + 1 leap day
    const days_in_century = days_in_four_years * 25 - 1; // every 100 years do not have a leap day
    const days_in_four_centuries = days_in_century * 4 + 1; // but 400 years do have

    const days_in_months = [12]u5{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    const acc_days_in_month = [13]u16{ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 };
    const millis_from_1970 = comptime millisFromDate(1970, 1, 1);

    timestamp: i64,

    /// initializes a from a date
    pub fn fromDate(year: u32, month: u4, day: u5) !Self {
        if (year == 0) return error.InvalidDate;
        if (month == 0 or month > 12) return error.InvalidDate;
        if (day == 0 or day > daysInMonth(month, isLeapYear(year))) return error.InvalidDate;

        return .{
            .timestamp = millisFromDate(year, month, day),
        };
    }

    /// initializes from a date and time
    pub fn fromDateTime(
        year: u32,
        month: u4,
        day: u5,
        hour: u5,
        minute: u6,
        second: u6,
        millisecond: u10,
    ) Self {
        if (year == 0) return error.InvalidDate;
        if (month == 0 or month > 12) return error.InvalidDate;
        if (day == 0 or day > daysInMonth(month, isLeapYear(year))) return error.InvalidDate;
        if (hour >= 24) return error.InvalidDate;
        if (minute >= 60) return error.InvalidDate;
        if (second >= 60) return error.InvalidDate;
        if (millisecond >= 1000) return error.InvalidDate;

        return .{
            .timestamp = millisFromDateTime(year, month, day, hour, minute, second, millisecond),
        };
    }

    /// Gets the actual date and time
    // horary not working, not sure why
    pub fn now() Self {
        return .{
            .timestamp = std.time.milliTimestamp() + @intCast(i64, millis_from_1970),
        };
    }

    /// Gets the actual date
    // apparently functionting
    pub fn today() Self {
        var timestamp = std.time.milliTimestamp();
        timestamp -= @mod(timestamp, std.time.ms_per_day);

        return .{
            .timestamp = timestamp + @intCast(i64, millis_from_1970),
        };
    }

    /// Tells the week day, 0 is Sunday and 6 is Saturday
    pub fn weekDay(self: Self) u3 {
        const abs = std.math.absCast(self.timestamp);
        const wk = @divTrunc(abs, std.time.ms_per_day) + 1;

        return @intCast(u3, @mod(wk, 7));
    }

    pub fn getDateTime(self: Self) DateTime {
        var days = @divTrunc(self.timestamp, std.time.ms_per_day);
        var horary = self.timestamp - days * std.time.ms_per_day;

        // four centuries in whole year interval
        const f_c = @divTrunc(days, days_in_four_centuries);
        days -= f_c * days_in_four_centuries; // days %= days_in_four_centuries;

        const c = brk: {
            var cent = @divTrunc(days, days_in_century); // centuries, [0, 3] in 400 years interval
            // if it's the last day of the four centuries period subtract one
            cent -= @as(i64, @boolToInt(cent == 4));
            break :brk cent;
        };
        days -= c * days_in_century; // days %= days_in_century

        // four years, [0, 24] in 100 years interval
        const f = @divTrunc(days, days_in_four_years);
        days -= f * days_in_four_years; // days %= days_in_four_years;

        const y = brk: {
            // a year, [0, 3] in 4 years interval
            var year = @divTrunc(days, days_in_year);
            // if it's the last day of the four year period subtract one
            year -= @as(i64, @boolToInt(year == 4));
            break :brk year;
        };
        days -= y * days_in_year; // days %= days_in_year

        var dt: DateTime = undefined;

        dt.day_of_the_year = @intCast(u16, days + 1);
        dt.year = @intCast(i32, f_c * 400 + c * 100 + f * 4 + y + 1);
        dt.is_leap_year = isLeapYear(@intCast(u32, dt.year));
        dt.month = monthFromDayOfTheYear(dt.day_of_the_year, dt.is_leap_year);
        dt.day = @intCast(u8, dt.day_of_the_year - acc_days_in_month[dt.month - 1] - @boolToInt(dt.is_leap_year and dt.day_of_the_year >= 60));
        dt.hour = @intCast(u8, @divTrunc(horary, std.time.ms_per_hour));
        horary -= @as(i64, dt.hour) * std.time.ms_per_hour;
        dt.minute = @intCast(u8, @divTrunc(horary, std.time.ms_per_min));
        horary -= @as(i64, dt.minute) * std.time.ms_per_min;
        dt.second = @intCast(u8, @divTrunc(horary, std.time.ms_per_s));
        dt.millisecond = @intCast(u16, horary - @as(i64, dt.second) * std.time.ms_per_s);

        return dt;
    }

    /// Calculates the total of milliseconds of the date
    fn millisFromDate(year: u32, month: u4, day: u5) u64 {
        return daysFromDate(year, month, day) * std.time.ms_per_day;
    }

    /// Calculates the total of days of the date
    fn daysFromDate(year: u32, month: u4, day: u5) u64 {
        var days: u64 = (year - 1) * 365;
        days += totalLeapDaysInYear(year - @boolToInt(month & 0xC != 0)); // month < 3
        days += acc_days_in_month[month - 1];
        days += day - 1;

        return days;
    }

    /// Calculates the total of milliseconds of the time
    fn millisFromTime(hour: u5, minute: u6, second: u6, millisecond: u10) u64 {
        var millis: u64 = hour * std.time.ms_per_hour;
        millis += minute * std.time.ms_per_min;
        millist += second * std.time.ms_per_s;
        millis += millisecond;

        return millis;
    }

    /// Tells the month by the day of the year
    fn monthFromDayOfTheYear(days: u16, is_leap: bool) u4 {
        // subtract one if feb 29 or later
        var d = days - @boolToInt(days >= 60 and is_leap);
        const index = @divTrunc(d - 1, 31);

        return @intCast(u4, index + 2 - @boolToInt(d <= acc_days_in_month[index + 1]));
    }

    /// Calculates the total of milliseconds of the date and time
    pub fn millisFromDateTime(
        year: u32,
        month: u4,
        day: u5,
        hour: u5,
        minute: u6,
        second: u6,
        millisecond: u10,
    ) u64 {
        return millisFromDate(year, month, day) + millisFromTime(hour, minute, second, millisecond);
    }

    /// Number of days in month
    pub fn daysInMonth(month: u4, is_leap: bool) u5 {
        return days_in_months[month - 1] + @boolToInt(is_leap and month == 2);
    }

    /// Tells whether year is a leap year or not
    pub fn isLeapYear(year: u32) bool {

        // (y divisible by 4 and not by 100) or y divisible by 400
        return (year & 0x3 == 0 and year % 100 != 0) or year % 400 == 0;
    }

    /// Get the sum of leap days until `year`, inclusive
    pub fn totalLeapDaysInYear(year: u32) u32 {
        const cent = year / 100; // centuries

        // year / 4 - year / 100 + year / 400
        return (year >> 2) - cent + (cent >> 2);
    }

    /// Tells the week day of a date, 0 is Sunday and 6 is Saturday
    pub fn weekDayOfDate(year: u32, month: u4, day: u5) u3 {
        // Tomohiko Sakamoto's algorithm
        const offset_from_jan = [12]u3{ 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 };

        year -= @boolToInt(m & 0xFC != 0); // month < 3
        const cent = @divTrunc(year, 100); // centuries

        return (year + (year >> 2) - cent + (cent >> 2) + offset_from_jan[month - 1] + day) % 7;
    }
};
