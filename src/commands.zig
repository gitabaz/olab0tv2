const std = @import("std");
const tls = @import("tls");
const irc = @import("irc.zig");

pub fn handleCommand(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    var it = std.mem.tokenizeAny(u8, msg.msg, " \r\n");
    const cmd = it.next().?;
    const rest = it.rest();
    _ = rest;

    if (std.mem.eql(u8, cmd, "!github")) {
        const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
            msg.user,
            "https://github.com/gitabaz",
        });
        defer allocator.free(full_msg);

        try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
    } else if (std.mem.eql(u8, cmd, "!olab0t")) {
        const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
            msg.user,
            "https://github.com/gitabaz/olab0tv2",
        });
        defer allocator.free(full_msg);

        try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
    }
}
