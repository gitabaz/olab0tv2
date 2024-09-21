const std = @import("std");
const tls = @import("tls");
const twitch_client = @import("twitch_client.zig");
const irc = @import("irc.zig");
const ma = @import("miniaudio.zig");

//https://static-cdn.jtvnw.net/emoticons/v1/1000/1.0
//https://xkcd.com/info.0.json

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.testing.expect(gpa.deinit() == .ok) catch @panic("MEMORY LEAK!");

    const nick = "olab0t";
    const caps = "twitch.tv/membership twitch.tv/tags twitch.tv/commands";
    const channel_list = "olabaz";

    const user_access_token = std.process.getEnvVarOwned(allocator, "OLAB0T_USER_ACCESS_TOKEN") catch {
        std.debug.print("Error: could not find {s}\n", .{"OLAB0T_USER_ACCESS_TOKEN"});
        return;
    };
    defer allocator.free(user_access_token);

    var tc = twitch_client.TwitchClient(.{
        .nick = nick,
        .caps = caps,
        .utc = -4,
        .play_msg_sound = true,
    }){};

    tc.setUserAccessToken(user_access_token);

    var engine = ma.Engine(.{
        .new_msg_sound_path = "./assets/new_msg.mp3",
    }){};

    engine.init(allocator) catch std.debug.print("Failed to initialize audio engine.\n", .{});
    defer engine.deinit(allocator);

    try tc.connect(allocator);
    defer tc.close();
    try tc.requestCaps(allocator);
    try tc.authenticate(allocator);
    try tc.joinChannel(allocator, channel_list);

    std.debug.print("Entering Loop...\n", .{});
    var res: []const u8 = undefined;
    while (true) {
        if (tc.conn) |*conn| {
            res = try conn.reader().readUntilDelimiterAlloc(allocator, '\n', 4096);
            defer allocator.free(res);

            const msg = try irc.parseMessage(res);
            try tc.handleMessage(allocator, msg, &engine);
            // try std.io.getStdOut().writer().print("{s}\n", .{res});
        }
    }
}

test "tests" {
    std.testing.refAllDecls(@This());
}
