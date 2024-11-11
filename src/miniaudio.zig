const std = @import("std");

const c = @cImport({
    @cInclude("miniaudio.h");
});

const MiniAudioError = error{
    EngineInitFail,
    PlaySoundFail,
};

const EngineConfig = struct {
    new_msg_sound_path: []const u8,
};

pub fn Engine(config: EngineConfig) type {
    return struct {
        engine: ?*c.ma_engine = null,
        new_msg_sound_path: []const u8 = config.new_msg_sound_path,
        const Self = @This();

        pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
            self.engine = try allocator.create(c.ma_engine);

            const result = c.ma_engine_init(null, self.engine);

            if (result != c.MA_SUCCESS) {
                return MiniAudioError.EngineInitFail;
            }
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            if (self.engine) |engine| {
                c.ma_engine_uninit(engine);
                allocator.destroy(engine);
            }
        }

        fn playSound(self: *Self, file_path: []const u8) !void {
            if (self.engine) |engine| {
                const result = c.ma_engine_play_sound(engine, file_path.ptr, null);

                if (result != c.MA_SUCCESS) {
                    return MiniAudioError.PlaySoundFail;
                }
            }
        }

        pub fn playNewMsgSound(self: *Self) !void {
            try self.playSound(self.new_msg_sound_path);
        }
    };
}
