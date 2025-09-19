const std = @import("std");
const Types = @import("../types/types.zig");
const AssetManager = @import("asset_manager.zig").AssetManager;

pub fn initImages(asset_manager: *AssetManager) !void {
    _ = asset_manager.loadTexture(Types.Species.GOLDFISH) catch |err| {
        std.log.err("Failed to load goldfish texture: {}", .{err});
        return err;
    };
}
