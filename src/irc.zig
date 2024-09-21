const std = @import("std");

pub const Msg = union(MsgType) {
    ping: PingMsg,
    privmsg: PrivMsg,
    user_state: UserStateMsg,
    other: bool,
};

pub const MsgType = enum {
    ping,
    privmsg,
    user_state,
    other,
};

pub const PingMsg = struct {
    token: []const u8,

    const Self = @This();
};

pub fn msgFromMsgParts(msg_parts: MsgParts) Msg {
    var msg: Msg = undefined;

    if (std.mem.eql(u8, msg_parts.command, "PING")) {
        const ping_msg = PingMsg{ .token = msg_parts.parameters };
        msg = Msg{ .ping = ping_msg };
    } else if (std.mem.eql(u8, msg_parts.command, "GLOBALUSERSTATE")) {
        // global user state
        var user_state_msg: UserStateMsg = .{};
        user_state_msg.fromMsgParts(msg_parts);
        msg = Msg{ .user_state = user_state_msg };
    } else if (std.mem.startsWith(u8, msg_parts.command, "PRIVMSG")) {
        var priv_msg = PrivMsg{};
        priv_msg.fromMsgParts(msg_parts);
        msg = Msg{ .privmsg = priv_msg };
    } else {
        msg = Msg{ .other = true };
    }
    return msg;
}

pub const MsgParts = struct {
    tags: ?[]const u8 = null,
    source: ?[]const u8 = null,
    command: []const u8 = undefined,
    parameters: []const u8 = undefined,

    const Self = @This();

    pub fn grabMsgParts(self: *Self, msg: []const u8) !void {
        var cur_msg: []const u8 = msg;

        if (cur_msg[0] == '@') {
            // Message has tags so we should pull them out
            var tag_it = std.mem.splitAny(u8, msg[1..], " ");
            try self.grabTags(tag_it.first());

            // Set cur_msg to everything after the tags so it is ready for the
            // next check
            cur_msg = tag_it.rest();
        }
        if (cur_msg[0] == ':') {
            // Message has a source so we should pull it out
            var source_it = std.mem.splitAny(u8, cur_msg[1..], " ");
            try self.grabSource(source_it.first());

            // Set cur_msg to everything after the source so it is ready for
            // the next check
            cur_msg = source_it.rest();
        }

        try self.grabCommand(cur_msg);
    }

    pub fn grabTags(self: *Self, msg: []const u8) !void {
        self.tags = msg;
    }

    pub fn grabSource(self: *Self, msg: []const u8) !void {
        // std.debug.print("PARSING SOURCE:\n{s}|\n", .{msg});
        // std.debug.print("source: {s}|\n", .{msg});
        self.source = msg;
    }

    pub fn grabCommand(self: *Self, msg: []const u8) !void {
        var it = std.mem.splitAny(u8, msg, ":");

        // std.debug.print("Parsing COMMANDS:\n{s}|\n", .{msg});

        const command = std.mem.trim(u8, it.first(), " ");
        self.command = command;
        // std.debug.print("command: {s}|\n", .{command});

        const params = it.rest();
        self.parameters = params;
        // std.debug.print("params: {s}|\n", .{params});
    }
};

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

const Color = packed struct {
    // Fields remain in the order declared, least to most significant.
    b: u8,
    g: u8,
    r: u8,
};

pub const PrivMsg = struct {
    channel: []const u8 = undefined,
    user: []const u8 = undefined,
    msg: []const u8 = undefined,
    color: Color = .{ .r = 0, .g = 0xFF, .b = 0 },
    timestamp: usize = undefined,

    const Self = @This();

    pub fn fromMsgParts(self: *Self, msg_parts: MsgParts) void {
        self.parseMsg(msg_parts.parameters);
        self.parseChannel(msg_parts.command);
        if (msg_parts.tags) |tags| self.parseTags(tags);
    }

    fn parseMsg(self: *Self, parameters: []const u8) void {
        // parameters contains the message
        self.msg = parameters;
    }

    fn parseChannel(self: *Self, command: []const u8) void {
        // command is of the form: PRIVMSG #<channel>
        var it = std.mem.splitAny(u8, command, "#");
        _ = it.first();
        self.channel = it.rest();
    }

    fn parseTags(self: *Self, tags: []const u8) void {
        var it = std.mem.splitAny(u8, tags, ";");

        while (it.next()) |tag_pair| {
            var pair_it = std.mem.splitAny(u8, tag_pair, "=");
            const tag_name = pair_it.first();
            const tag_value = pair_it.rest();
            if (std.mem.eql(u8, tag_name, "display-name")) {
                self.user = tag_value;
            } else if (std.mem.eql(u8, tag_name, "color")) {
                if (tag_value.len > 1) {
                    if (std.fmt.parseInt(u24, tag_value[1..], 16)) |color| {
                        self.color = @bitCast(color);
                    } else |err| { // TODO: Handle this in a nicer way.
                        switch (err) {
                            else => {},
                        }
                    }
                }
            } else if (std.mem.eql(u8, tag_name, "tmi-sent-ts")) {
                // Twitch gives time in ms
                const timestamp_ms = std.fmt.parseInt(usize, tag_value, 10) catch 0;
                self.timestamp = timestamp_ms / 1000;
            }
            //std.debug.print("tag-name: {s}|\ntag-value: {s}|\n", .{ tag_name, tag_value });
        }
    }
};

const UserStateMsg = struct {
    badge_info: []const u8 = undefined,
    badges: []const u8 = undefined,
    color: []const u8 = undefined,
    display_name: []const u8 = undefined,
    emote_sets: []const u8 = undefined,
    turbo: []const u8 = undefined,
    user_id: usize = undefined,
    user_type: []const u8 = undefined,

    const Self = @This();

    pub fn fromMsgParts(self: *Self, msg_parts: MsgParts) void {
        if (msg_parts.tags) |tags| self.parseTags(tags);
    }

    fn parseTags(self: *Self, tags: []const u8) void {
        var it = std.mem.splitAny(u8, tags, ";");

        while (it.next()) |tag_pair| {
            var pair_it = std.mem.splitAny(u8, tag_pair, "=");
            const tag_name = pair_it.first();
            const tag_value = pair_it.rest();
            if (std.mem.eql(u8, tag_name, "badge-info")) {
                self.badge_info = tag_value;
            } else if (std.mem.eql(u8, tag_name, "badges")) {
                self.badges = tag_value;
            } else if (std.mem.eql(u8, tag_name, "color")) {
                self.color = tag_value;
            } else if (std.mem.eql(u8, tag_name, "display-name")) {
                self.display_name = tag_value;
            } else if (std.mem.eql(u8, tag_name, "emote-sets")) {
                self.emote_sets = tag_value;
            } else if (std.mem.eql(u8, tag_name, "turbo")) {
                self.turbo = tag_value;
            } else if (std.mem.eql(u8, tag_name, "user-id")) {
                self.user_id = std.fmt.parseInt(usize, tag_value, 10) catch 0;
            } else if (std.mem.eql(u8, tag_name, "user-type")) {
                self.user_type = tag_value;
            }
            //std.debug.print("tag-name: {s}|\ntag-value: {s}|\n", .{ tag_name, tag_value });
        }
    }
};

pub fn parseMessage(msg: []const u8) !Msg {
    // Parse messages of the form:
    // message ::= ['@' <tags> SPACE] [':' <source> SPACE] <command> <parameters> <crlf>

    //std.debug.print("\n==MESSAGE==\n{s}|\n========\n", .{msg});
    var msg_parts: MsgParts = .{};
    try msg_parts.grabMsgParts(msg);

    const parsed_message: Msg = msgFromMsgParts(msg_parts);

    return parsed_message;
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

test "grabMsgParts SOURCE" {
    var src_msg: []const u8 = undefined;
    var res: MsgParts = .{};

    {
        src_msg = ":tmi.twitch.tv CAP * ACK :twitch.tv/membership twitch.tv/tags twitch.tv/commands";
        try res.grabMsgParts(src_msg);

        try std.testing.expect(null == res.tags);
        try std.testing.expectEqualSlices(u8, "tmi.twitch.tv", res.source.?);
        try std.testing.expectEqualSlices(u8, "CAP * ACK", res.command);
        try std.testing.expectEqualSlices(u8, "twitch.tv/membership twitch.tv/tags twitch.tv/commands", res.parameters);
    }

    {
        src_msg = ":tmi.twitch.tv 001 olab0t :Welcome, GLHF!";
        try res.grabMsgParts(src_msg);

        try std.testing.expect(null == res.tags);
        try std.testing.expectEqualSlices(u8, "tmi.twitch.tv", res.source.?);
        try std.testing.expectEqualSlices(u8, "001 olab0t", res.command);
        try std.testing.expectEqualSlices(u8, "Welcome, GLHF!", res.parameters);
    }
}

test "grabMsgParts PING" {
    const ping_msg = "PING :tmi.twitch.tv";

    var res: MsgParts = .{};
    try res.grabMsgParts(ping_msg);

    try std.testing.expect(null == res.tags);
    try std.testing.expect(null == res.source);
    try std.testing.expectEqualSlices(u8, "PING", res.command);
    try std.testing.expectEqualSlices(u8, "tmi.twitch.tv", res.parameters);
}

test "grabMsgParts PRIVMSG" {
    const priv_msg = "@badge-info=;badges=broadcaster/1;client-nonce=5686cc9a3bd17e62bc4e9de8d90dcc26;color=#FF4500;" ++
        "display-name=olabaz;emotes=1:9-10;first-msg=0;flags=;id=78f87122-c59e-4322-bc59-08c77c5afd61;mod=0;returning-chatter=0;" ++
        "room-id=23126828;subscriber=0;tmi-sent-ts=1726069317334;turbo=0;user-id=23126828;user-type= " ++
        ":olabaz!olabaz@olabaz.tmi.twitch.tv PRIVMSG #olabaz :hi there :)";

    const tags = "badge-info=;badges=broadcaster/1;client-nonce=5686cc9a3bd17e62bc4e9de8d90dcc26;color=#FF4500;" ++
        "display-name=olabaz;emotes=1:9-10;first-msg=0;flags=;id=78f87122-c59e-4322-bc59-08c77c5afd61;mod=0;returning-chatter=0;" ++
        "room-id=23126828;subscriber=0;tmi-sent-ts=1726069317334;turbo=0;user-id=23126828;user-type=";
    const source = "olabaz!olabaz@olabaz.tmi.twitch.tv";
    const command = "PRIVMSG #olabaz";
    const parameters = "hi there :)";

    var res: MsgParts = .{};
    try res.grabMsgParts(priv_msg);

    try std.testing.expectEqualSlices(u8, tags, res.tags.?);
    try std.testing.expectEqualSlices(u8, source, res.source.?);
    try std.testing.expectEqualSlices(u8, command, res.command);
    try std.testing.expectEqualSlices(u8, parameters, res.parameters);
}

test "grabMsgParts GLOBALUSERSTATE" {
    const gus_msg = "@badge-info=;badges=;color=;display-name=olab0t;emote-sets=0,300374282;user-id=559947421;user-type= " ++
        ":tmi.twitch.tv GLOBALUSERSTATE";

    const tags = "badge-info=;badges=;color=;display-name=olab0t;emote-sets=0,300374282;user-id=559947421;user-type=";
    const source = "tmi.twitch.tv";
    const command = "GLOBALUSERSTATE";

    var res: MsgParts = .{};
    try res.grabMsgParts(gus_msg);

    try std.testing.expectEqualSlices(u8, tags, res.tags.?);
    try std.testing.expectEqualSlices(u8, source, res.source.?);
    try std.testing.expectEqualSlices(u8, command, res.command);
}
