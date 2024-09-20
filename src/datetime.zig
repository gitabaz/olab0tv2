const std = @import("std");

pub const Clock = struct {
    hr: u8,
    min: u8,
    sec: u8,

    pub fn fromTimestamp(timestamp: usize, utc: i8) Clock {
        const leftover_secs = timestamp % (24 * 60 * 60);
        const hours: u8 = @truncate(leftover_secs / (60 * 60));
        const minutes: u8 = @truncate((leftover_secs % (60 * 60)) / 60);
        const seconds: u8 = @truncate(timestamp % 60);

        var hours_utc: i16 = @as(i16, hours) + utc;
        if (hours_utc < 0) {
            hours_utc += 12;
        } else if (hours_utc > 24) {
            hours_utc -= 24;
        }

        return Clock{
            .hr = @intCast(hours_utc),
            .min = minutes,
            .sec = seconds,
        };
    }
};

test "timestamp" {

    const ts:usize = 1726862295;

    var res = Clock.fromTimestamp(ts, 0);
    try std.testing.expectEqual(19, res.hr);
    try std.testing.expectEqual(58, res.min);
    try std.testing.expectEqual(15, res.sec);

    res = Clock.fromTimestamp(ts, -4);
    try std.testing.expectEqual(15, res.hr);

    res = Clock.fromTimestamp(ts, -11);
    try std.testing.expectEqual(8, res.hr);

    res = Clock.fromTimestamp(ts, 14);
    try std.testing.expectEqual(9, res.hr);
}
