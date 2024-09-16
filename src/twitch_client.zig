const std = @import("std");
const tls = @import("tls");
const irc = @import("irc.zig");
const ma = @import("miniaudio.zig");

pub const TwitchClientConfig = struct {
    nick: []const u8 = "olab0t",
    user_access_token: ?[]const u8 = null,
    caps: []const u8 = "twitch.tv/membership twitch.tv/tags twitch.tv/commands",
    host: []const u8 = "irc.chat.twitch.tv",
    port: u16 = 6697,
    play_msg_sound: bool = true,
};

pub fn TwitchClient(config: TwitchClientConfig) type {
    return struct {
        nick: []const u8 = config.nick,
        user_access_token: ?[]const u8 = config.user_access_token,
        caps: []const u8 = config.caps,
        host: []const u8 = config.host,
        port: u16 = config.port,
        conn: ?tls.Connection(std.net.Stream) = null,
        play_msg_sound: bool = config.play_msg_sound,

        const Self = @This();

        pub fn connect(self: *Self, allocator: std.mem.Allocator) !void {
            const tcp_conn = try std.net.tcpConnectToHost(allocator, self.host, self.port);

            var root_ca = try tls.CertBundle.fromSystem(allocator);
            defer root_ca.deinit(allocator);

            self.conn = try tls.client(tcp_conn, .{
                .host = self.host,
                .root_ca = root_ca,
            });
        }

        pub fn close(self: *Self) void {
            if (self.conn) |*conn| {
                conn.stream.close();
            }
        }

        pub fn setUserAccessToken(self: *Self, user_access_token: []const u8) void {
            self.user_access_token = user_access_token;
        }

        pub fn requestCaps(self: *Self, allocator: std.mem.Allocator) !void {
            if (self.conn) |*conn| {
                const cap_msg = try std.fmt.allocPrint(allocator, "CAP REQ :{s}\r\n", .{self.caps});
                defer allocator.free(cap_msg);

                try conn.writeAll(cap_msg);

                const res = try conn.reader().readUntilDelimiterAlloc(allocator, '\n', 4096);
                defer allocator.free(res);

                const cap_success_msg = ":tmi.twitch.tv CAP * ACK :twitch.tv/membership twitch.tv/tags twitch.tv/commands\r";

                if (std.mem.eql(u8, res, cap_success_msg)) {
                    try std.io.getStdOut().writer().print("{s}\n", .{res});
                } else {
                    try std.io.getStdOut().writer().print("{s}\n", .{res});
                    return error.CapabilityRequestFailed;
                }
            } else {
                return error.NotConnected;
            }
        }

        pub fn authenticate(self: *Self, allocator: std.mem.Allocator) !void {
            if (self.user_access_token) |uat| {
                const oauth_msg = try std.fmt.allocPrint(allocator, "PASS oauth:{s}\r\n", .{uat});
                defer allocator.free(oauth_msg);

                const nick_msg = try std.fmt.allocPrint(allocator, "NICK {s}\r\n", .{self.nick});
                defer allocator.free(nick_msg);

                if (self.conn) |*conn| {
                    try conn.writeAll(oauth_msg);
                    try conn.writeAll(nick_msg);

                    const res = try conn.reader().readUntilDelimiterAlloc(allocator, '\n', 4096);
                    defer allocator.free(res);

                    const login_success_msg = try std.fmt.allocPrint(
                        allocator,
                        ":tmi.twitch.tv 001 {s} :Welcome, GLHF!\r",
                        .{self.nick},
                    );
                    defer allocator.free(login_success_msg);

                    const login_fail_msg = ":tmi.twitch.tv NOTICE * :Login authentication failed\r";
                    const improper_auth_format_msg = ":tmi.twitch.tv NOTICE * :Improperly formatted auth\r";

                    if (std.mem.eql(u8, login_success_msg, res)) {
                        try std.io.getStdOut().writer().print("{s}\n", .{res});
                        try finishAuthMessages(self, allocator);
                        return;
                    } else if (std.mem.eql(u8, res, login_fail_msg)) {
                        return error.LoginFailed;
                    } else if (std.mem.eql(u8, res, improper_auth_format_msg)) {
                        return error.ImproperlyFormattedAuth;
                    } else {
                        std.debug.print("{s}\n", .{res});
                        return error.UnknownAuthenticationError;
                    }
                } else {
                    return error.NotConnected;
                }
            } else {
                return error.UserAccessTokenMissing;
            }
        }

        fn finishAuthMessages(self: *Self, allocator: std.mem.Allocator) !void {
            // Continue reading auth messages until we get to last auth message that starst with '@'
            // :tmi.twitch.tv 001 <user> :Welcome, GLHF!
            // :tmi.twitch.tv 002 <user> :Your host is tmi.twitch.tv
            // :tmi.twitch.tv 003 <user> :This server is rather new
            // :tmi.twitch.tv 004 <user> :-
            // :tmi.twitch.tv 375 <user> :-
            // :tmi.twitch.tv 372 <user> :You are in a maze of twisty passages.
            // :tmi.twitch.tv 376 <user> :>
            // @badge-info=;badges=;color=;display-name=<user>;emote-sets=0,300374282;user-id=12345678;user-type= :tmi.twitch.tv GLOBALUSERSTATE
            if (self.conn) |*conn| {
                var res: []const u8 = undefined;
                var finished: bool = false;
                while (!finished) {
                    res = try conn.reader().readUntilDelimiterAlloc(allocator, '\n', 4096);
                    defer allocator.free(res);
                    try std.io.getStdOut().writer().print("{s}\n", .{res});
                    if (res[0] == '@') {
                        finished = true;
                    }
                }
            }
        }

        pub fn joinChannel(self: *Self, allocator: std.mem.Allocator, channel_list: []const u8) !void {
            const join_channel_msg = try std.fmt.allocPrint(allocator, "JOIN #{s}\r\n", .{channel_list});
            defer allocator.free(join_channel_msg);

            if (self.conn) |*conn| {
                try conn.writeAll(join_channel_msg);
            }

            //:olab0t!olab0t@olab0t.tmi.twitch.tv JOIN #lec
            //:olab0t.tmi.twitch.tv 353 olab0t = #lec :olab0t
            //:olab0t.tmi.twitch.tv 366 olab0t #lec :End of /NAMES list

        }

        //fn finishJoinChannelMessages(self: *Self, allocator: std.mem.Allocator) !void {
        //    if (self.conn) |*conn| {
        //        var res: []const u8 = undefined;
        //        var finished: bool = false;
        //        while (!finished) {
        //            res = conn.reader().readUntilDelimiterAlloc(allocator, '\n', 4096);
        //            defer allocator.free(res);
        //        }
        //    }
        //}

        pub fn handleMessage(self: *Self, msg: irc.Msg, engine: anytype) !void {
            switch (msg) {
                .ping => try self.sendPONG(),
                .privmsg => {
                    // std.debug.print(
                    //     "==PRIVMSG==\nchannel:{s}\nuser:{s}\nmsg:{s}\ncolor:{}\n===========\n",
                    //     .{ msg.privmsg.channel, msg.privmsg.user, msg.privmsg.msg, msg.privmsg.color },
                    // );
                    std.debug.print(
                        "\x1b[38;2;{d};{d};{d}m{s}\x1b[0m: {s}\n",
                        .{ msg.privmsg.color.r, msg.privmsg.color.g, msg.privmsg.color.b, msg.privmsg.user, msg.privmsg.msg },
                    );
                    if (self.play_msg_sound) try engine.playNewMsgSound();
                },
                .user_state => return,
                .other => return,
            }
        }

        fn sendPONG(self: *Self) !void {
            const pong_msg = "PONG :tmi.twitch.tv\r\n";

            if (self.conn) |*conn| {
                try conn.writeAll(pong_msg);
                std.debug.print("SENT PONG\n", .{});
            }
        }
    };
}
