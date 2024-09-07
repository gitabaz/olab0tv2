const std = @import("std");

//@badge-info=;badges=;color=;display-name=olab0t;emote-sets=0,300374282;user-id=559947421;user-type= :tmi.twitch.tv GLOBALUSERSTATE

pub const Msg = union(MsgType) {
    ping: bool,
    other: bool,
    privmsg: *PrivMsg,
    //user_state: UserStateMsg,
};

pub const MsgType = enum {
    ping,
    other,
    privmsg,
    //user_state,
};

const UserStateMsg = struct {
    badge_info: []const u8,
    badges: []const u8,
    color: []const u8,
    display_name: []const u8,
    emote_sets: []const u8,
    turbo: bool,
    user_id: []const u8,
    user_type: []const u8,
};

pub fn isPing(tags: []const u8) bool {
    if (std.mem.eql(u8, tags, "PING ")) {
        std.debug.print("GOT A PINGGGG\n", .{});
        return true;
    }

    return false;
}

const Command = enum {
    CLEARCHAT,
    CLEARMSG,
    GLOBALUSERSTATE,
    NOTICE,
    PART,
    PING,
    PRIVMSG,
    RECONNECT,
    ROOMSTATE,
    USERNOTICE,
    USERSTATE,
    OTHER,
};

pub fn parseCommand(msg: []const u8) Command {
    var it = std.mem.splitAny(u8, msg, " ");

    const host = it.first();
    _ = host;

    const command = it.next().?;

    if (std.mem.eql(u8, command, @tagName(Command.PRIVMSG))) {
        std.debug.print("\nPRIVMSG message\n", .{});
        return Command.PRIVMSG;
    }

    return Command.OTHER;
}

const PrivMsg = struct {
    channel: []const u8,
    user: []const u8,
    msg: []const u8,
    color: ?[]const u8 = null,
};

pub fn parsePrivMsg(allocator: std.mem.Allocator, msg: []const u8) !*PrivMsg {
    //olabaz!olabaz@olabaz.tmi.twitch.tv PRIVMSG #olabaz :hi there
    var it = std.mem.splitAny(u8, msg, "!");
    const user = it.first();

    var rest = it.rest();
    it = std.mem.splitAny(u8, rest, "#");
    _ = it.first();
    rest = it.rest();

    it = std.mem.splitAny(u8, rest, ":");

    const channel = it.first();
    const user_msg = it.rest();

    var priv_msg = try allocator.create(PrivMsg);

    priv_msg.channel = try std.fmt.allocPrint(allocator, "{s}", .{channel});
    priv_msg.user = try std.fmt.allocPrint(allocator, "{s}", .{user});
    priv_msg.msg = try std.fmt.allocPrint(allocator, "{s}", .{user_msg});

    return priv_msg;
}

pub fn parseMessage(allocator: std.mem.Allocator, msg: []const u8) !Msg {
    var it = std.mem.splitAny(u8, msg, ":");
    const tags = it.first();
    const rest = it.rest();

    std.debug.print("\n==TAGS==\n{s}\n========\n", .{tags});
    std.debug.print("\n==REST==\n{s}\n========\n", .{rest});

    if (!std.mem.eql(u8, "", tags)) {
        if (isPing(tags)) {
            return Msg{ .ping = true };
        } else {
            const command = parseCommand(rest);
            switch (command) {
                .PRIVMSG => {
                    const priv_msg = try parsePrivMsg(allocator, rest);
                    return Msg{ .privmsg = priv_msg };
                },
                else => {},
            }
        }
    }

    return Msg{ .other = true };

    //parseMessage();
    //if (msg[0] == '@') {
    //    var it = std.mem.splitAny(u8, msg, ";=:");

    //    const start_tok = it.first();
    //    if (std.mem.eql(u8, start_tok, "@badge-info")) {
    //        var priv_msg = try allocator.create(PrivMsg);
    //        try priv_msg.parsePrivMsg(allocator, &it);
    //        std.debug.print("{?s}", .{priv_msg.color});
    //    } else if (std.mem.eql(u8, start_tok, "@emote-only")) {
    //        var room_state = try allocator.create(RoomState);
    //        room_state.parseRoomState(&it);
    //        std.debug.print("{?}", .{room_state});
    //    } else if (std.mem.eql(u8, start_tok, "PING ")) {
    //        std.debug.print("GOT A PING", .{});
    //    }
    //    std.debug.print("start: {s}\n", .{start_tok});
    //    while (it.next()) |s| {
    //        std.debug.print("xx: {s}\n", .{s});
    //    }
    //}
}

const RoomState = struct {
    emote_only: bool = false,
    followers_only: i64 = -1,
    r9k: bool = false,
    room_id: usize,
    slow: usize = 0,
    subs_only: bool = false,

    const Self = @This();

    pub fn parseRoomState(self: *Self, it: *std.mem.SplitIterator(u8, .any)) void {
        if (it.next()) |tok_val| {
            const temp = std.fmt.parseInt(u1, tok_val, 10) catch 0;
            self.emote_only = 0 != temp;
        }

        while (it.next()) |tok| {
            if (std.mem.eql(u8, tok, "followers-only")) {
                if (it.next()) |tok_val| {
                    self.followers_only = std.fmt.parseInt(i64, tok_val, 10) catch 0;
                }
            } else if (std.mem.eql(u8, tok, "r9k")) {
                if (it.next()) |tok_val| {
                    const temp = std.fmt.parseInt(u1, tok_val, 10) catch 0;
                    self.r9k = 0 != temp;
                }
            } else if (std.mem.eql(u8, tok, "room-id")) {
                if (it.next()) |tok_val| {
                    self.room_id = std.fmt.parseInt(usize, tok_val, 10) catch 0;
                }
            } else if (std.mem.eql(u8, tok, "slow")) {
                if (it.next()) |tok_val| {
                    self.slow = std.fmt.parseInt(usize, tok_val, 10) catch 0;
                }
            } else if (std.mem.eql(u8, tok, "subs-only")) {
                if (it.next()) |tok_val| {
                    const temp = std.fmt.parseInt(u1, tok_val, 10) catch 0;
                    self.subs_only = 0 != temp;
                }
            }
        }
    }
};

const Channel = struct {
    channel_name: []const u8,
    room_state: RoomState,
};

const Badge = enum {
    admin,
    bits,
    broadcaster,
    moderator,
    subscriber,
    staff,
    turbo,
};

const UserType = enum {
    admin,
    global_mod,
    staff,
    normal,
};

//const PrivMsg = struct {
//    badge_info: ?[]const u8 = null,
//    badges: ?[]Badge = null,
//    client_nonce: ?[]const u8 = null,
//    color: ?[]const u8 = null,
//    display_name: ?[]const u8 = null,
//    emotes: ?[]const u8 = null,
//    first_msg: bool = false,
//    flags: ?[]const u8 = null,
//    id: ?[]const u8 = null,
//    mod: bool = false,
//    reply_parent_msg_id: ?[]const u8,
//    reply_parent_user_id: ?usize,
//    reply_parent_user_login: ?[]const u8,
//    reply_thread_parent_display_name: ?[]const u8,
//    reply_parent_msg_body: ?[]const u8,
//    reply_thread_parent_msg_id: ?[]const u8,
//    reply_thread_parent_user_login: ?[]const u8,
//    returning_chatter: bool = false,
//    room_id: usize,
//    subscriber: bool = false,
//    tmi_sent_ts: usize,
//    turbo: bool = false,
//    reply_parent_display_name: ?[]const u8,
//    reply_thread_parent_user_id: ?usize,
//    user_id: usize,
//    user_type: UserType = .Normal,
//    channel: ?[]const u8 = null,
//    vip: bool = false,
//
//    const Self = @This();
//
//    pub fn parsePrivMsg(self: *Self, allocator: std.mem.Allocator, it: *std.mem.SplitIterator(u8, .any)) !void {
//        if (it.next()) |tok_val| {
//            self.badge_info = try std.fmt.allocPrint(allocator, "{s}", .{tok_val});
//        }
//
//        while (it.next()) |tok| {
//            if (std.mem.eql(u8, tok, "client-nonce")) {
//                if (it.next()) |tok_val| {
//                    self.client_nonce = try std.fmt.allocPrint(allocator, "{s}", .{tok_val});
//                }
//            } else if (std.mem.eql(u8, tok, "color")) {
//                if (it.next()) |tok_val| {
//                    self.color = try std.fmt.allocPrint(allocator, "{s}", .{tok_val});
//                }
//            }
//        }
//    }
//};

//@badge-info=;badges=moderator/1;color=;display-name=olab0t;emote-sets=0,300374282;mod=1;subscriber=0;user-type=mod :tmi.twitch.tv USERSTATE #olabaz
//badge-info: @badge-info=
//xx: badges=broadcaster/1
//xx: client-nonce=278bccb0265860d548ea96e0120c484a
//xx: color=#FF4500
//xx: display-name=olabaz
//xx: emotes=
//xx: first-msg=0
//xx: flags=
//xx: id=890f183f-adfd-4d21-892d-e03a0e0e7e9f
//xx: mod=0
//xx: returning-chatter=0
//xx: room-id=23126828
//xx: subscriber=0
//xx: tmi-sent-ts=1725476389154
//xx: turbo=0
//xx: user-id=23126828
//xx: user-type= :olabaz!olabaz@olabaz.tmi.twitch.tv PRIVMSG #olabaz :ok
