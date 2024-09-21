const std = @import("std");
const tls = @import("tls");
const irc = @import("irc.zig");

pub fn handleCommand(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    var it = std.mem.tokenizeAny(u8, msg.msg, " \r\n");
    const cmd = it.next().?;

    if (std.mem.eql(u8, cmd, "!help")) {
        try cmdHelp(allocator, twitch_client, msg);
    } else if (std.mem.eql(u8, cmd, "!github")) {
        try cmdGithub(allocator, twitch_client, msg);
    } else if (std.mem.eql(u8, cmd, "!olab0t")) {
        try cmdOlab0t(allocator, twitch_client, msg);
    } else if (std.mem.eql(u8, cmd, "!playlist")) {
        try cmdPlaylist(allocator, twitch_client, msg);
    } else if (std.mem.eql(u8, cmd, "!motd")) {
        try cmdMOTD(allocator, twitch_client, msg);
    } else if (std.mem.eql(u8, cmd, "!set")) {
        // TODO: handle checking that user is mod using badges
        if (msg.mod or std.mem.eql(u8, msg.user, "olabaz")) {
            if (it.next()) |key| {
                if (std.mem.eql(u8, key, "playlist")) {
                    if (it.peek()) |value| {
                        _ = value;
                        try cmdSetPlaylist(allocator, twitch_client, it.rest());
                    }
                } else if (std.mem.eql(u8, key, "motd")) {
                    if (it.peek()) |value| {
                        _ = value;
                        try cmdSetMOTD(allocator, twitch_client, it.rest());
                    }
                }
            }
        }
    }
}

fn cmdHelp(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
        msg.user,
        "available commands: !help, !github, !olab0t, !playlist, !motd",
    });
    defer allocator.free(full_msg);

    try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
}

fn cmdGithub(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
        msg.user,
        "https://github.com/gitabaz",
    });
    defer allocator.free(full_msg);

    try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
}

fn cmdOlab0t(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
        msg.user,
        "https://github.com/gitabaz/olab0tv2",
    });
    defer allocator.free(full_msg);

    try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
}

fn cmdPlaylist(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    if (twitch_client.state.playlist) |playlist| {
        const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
            msg.user,
            playlist,
        });
        defer allocator.free(full_msg);

        try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
    } else {
        const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
            msg.user,
            "playlist is not currently set",
        });
        defer allocator.free(full_msg);

        try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
    }
}

fn cmdMOTD(allocator: std.mem.Allocator, twitch_client: anytype, msg: irc.PrivMsg) !void {
    if (twitch_client.state.motd) |motd| {
        const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
            msg.user,
            motd,
        });
        defer allocator.free(full_msg);

        try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
    } else {
        const full_msg = try std.fmt.allocPrint(allocator, "@{s}: {s}", .{
            msg.user,
            "motd is not currently set",
        });
        defer allocator.free(full_msg);

        try twitch_client.sendPRIVMSG(allocator, msg.channel, full_msg);
    }
}

fn cmdSetPlaylist(allocator: std.mem.Allocator, twitch_client: anytype, value: []const u8) !void {
    if (twitch_client.state.playlist) |old_playlist| {
        allocator.free(old_playlist);
    }
    // TODO: might want to free this at the end
    const new_playlist = try std.fmt.allocPrint(allocator, "{s}", .{value});
    twitch_client.state.playlist = new_playlist;
}

fn cmdSetMOTD(allocator: std.mem.Allocator, twitch_client: anytype, value: []const u8) !void {
    if (twitch_client.state.motd) |old_motd| {
        allocator.free(old_motd);
    }
    // TODO: might want to free this at the end
    const new_motd = try std.fmt.allocPrint(allocator, "{s}", .{value});
    twitch_client.state.motd = new_motd;
}
