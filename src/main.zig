const std = @import("std");
const tls = @import("tls");
const twitch_client = @import("twitch_client.zig");
const irc = @import("irc.zig");

const c = @cImport({
    @cInclude("miniaudio.h");
});

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
    }){};

    tc.setUserAccessToken(user_access_token);

    var result: c.ma_result = undefined;
    var engine: c.ma_engine = undefined;

    result = c.ma_engine_init(null, &engine);
    defer c.ma_engine_uninit(&engine);

    if (result != c.MA_SUCCESS) {
        std.debug.print("Failed to initialize audio engine.", .{});
    }
    const loc = "./assets/new_msg.mp3";
    result = c.ma_engine_play_sound(&engine, loc, null);
    //var sound: c.ma_sound = undefined;
    //result = c.ma_sound_init_from_file(&engine, loc, 0, null, null, &sound);

    try tc.connect(allocator);
    defer tc.close();
    try tc.requestCaps(allocator);
    try tc.authenticate(allocator);
    try tc.joinChannel(allocator, channel_list);

    var res: []const u8 = undefined;
    while (true) {
        if (tc.conn) |*conn| {
            res = try conn.reader().readUntilDelimiterAlloc(allocator, '\n', 4096);
            try irc.parseMessage(allocator, res);
            defer allocator.free(res);
            try std.io.getStdOut().writer().print("{s}\n", .{res});
        }
    }
}
