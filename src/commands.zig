const std = @import("std");
const tls = @import("tls");
const irc = @import("irc.zig");

pub fn handleCommand(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    var it = std.mem.tokenizeAny(u8, msg.msg, " \r\n");
    const cmd = it.next().?;

    const argv = [_][]const u8{
        "python3",
        "./commands/launch_command.py",
        msg.user,
        cmd,
        it.rest(),
    };

    const proc = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &argv,
    });
    defer allocator.free(proc.stdout);
    defer allocator.free(proc.stderr);

    const full_msg = try std.fmt.allocPrint(allocator, "{s}", .{proc.stdout});
    defer allocator.free(full_msg);

    try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
}
