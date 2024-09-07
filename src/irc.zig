const std = @import("std");

const MsgType = enum {
    TwitchMsg,
};

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
    Admin,
    Bits,
    Broadcaster,
    Moderator,
    Subscriber,
    Staff,
    Turbo,
};

const UserType = enum {
    Admin,
    Global_mod,
    Staff,
    Normal,
};

const PrivMsg = struct {
    badge_info: ?[]const u8 = null,
    badges: ?[]Badge = null,
    client_nonce: ?[]const u8 = null,
    color: ?[]const u8 = null,
    display_name: ?[]const u8 = null,
    emotes: ?[]const u8 = null,
    first_msg: bool = false,
    flags: ?[]const u8 = null,
    id: ?[]const u8 = null,
    mod: bool = false,
    reply_parent_msg_id: ?[]const u8,
    reply_parent_user_id: ?usize,
    reply_parent_user_login: ?[]const u8,
    reply_thread_parent_display_name: ?[]const u8,
    reply_parent_msg_body: ?[]const u8,
    reply_thread_parent_msg_id: ?[]const u8,
    reply_thread_parent_user_login: ?[]const u8,
    returning_chatter: bool = false,
    room_id: usize,
    subscriber: bool = false,
    tmi_sent_ts: usize,
    turbo: bool = false,
    reply_parent_display_name: ?[]const u8,
    reply_thread_parent_user_id: ?usize,
    user_id: usize,
    user_type: UserType = .Normal,
    channel: ?[]const u8 = null,
    vip: bool = false,

    const Self = @This();

    pub fn parsePrivMsg(self: *Self, allocator: std.mem.Allocator, it: *std.mem.SplitIterator(u8, .any)) !void {
        if (it.next()) |tok_val| {
            self.badge_info = try std.fmt.allocPrint(allocator, "{s}", .{tok_val});
        }

        while (it.next()) |tok| {
            if (std.mem.eql(u8, tok, "client-nonce")) {
                if (it.next()) |tok_val| {
                    self.client_nonce = try std.fmt.allocPrint(allocator, "{s}", .{tok_val});
                }
            } else if (std.mem.eql(u8, tok, "color")) {
                if (it.next()) |tok_val| {
                    self.color = try std.fmt.allocPrint(allocator, "{s}", .{tok_val});
                }
            }
        }
    }
};

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

pub fn parseMessage(allocator: std.mem.Allocator, msg: []const u8) !void {
    if (msg[0] == '@') {
        var it = std.mem.splitAny(u8, msg, ";=:");

        const start_tok = it.first();
        if (std.mem.eql(u8, start_tok, "@badge-info")) {
            var priv_msg = try allocator.create(PrivMsg);
            try priv_msg.parsePrivMsg(allocator, &it);
            std.debug.print("{?s}", .{priv_msg.color});
        } else if (std.mem.eql(u8, start_tok, "@emote-only")) {
            var room_state = try allocator.create(RoomState);
            room_state.parseRoomState(&it);
            std.debug.print("{?}", .{room_state});
        }
        std.debug.print("start: {s}\n", .{start_tok});
        while (it.next()) |s| {
            std.debug.print("xx: {s}\n", .{s});
        }
    }
}
