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
            hours_utc -= 12;
        }

        return Clock{
            .hr = @intCast(hours_utc),
            .min = minutes,
            .sec = seconds,
        };
    }
};
