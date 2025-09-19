const std = @import("std");
const Types = @import("../types/types.zig");
const c = @import("../utils/cimport.zig");
const Helpers = @import("../utils/helpers.zig");

pub const AssetManager = struct {
    textures: std.hash_map.AutoHashMap(Types.Asset_Names, c.Texture2D),
    asset_paths: std.hash_map.AutoHashMap(Types.Asset_Names, []const u8),

    pub fn init(allocator: std.mem.Allocator) AssetManager {
        var self = AssetManager{
            .textures = std.hash_map.AutoHashMap(Types.Asset_Names, c.Texture2D).init(allocator),
            .asset_paths = std.hash_map.AutoHashMap(Types.Asset_Names, []const u8).init(allocator),
        };

        self.asset_paths.put(Types.Asset_Names.GOLDFISH, "assets/fish/goldfish.png") catch {};
        self.asset_paths.put(Types.Asset_Names.DEADGOLDFISH, "assets/fish/dead_goldfish.png") catch {};
        self.asset_paths.put(Types.Asset_Names.GLASS, "assets/tank/glass.png") catch {};

        return self;
    }

    pub fn deinit(self: *AssetManager) void {
        var iter = self.textures.iterator();
        while (iter.next()) |entry| {
            c.UnloadTexture(entry.value_ptr.*);
        }
        self.textures.deinit();
        self.asset_paths.deinit();
    }

    pub fn loadTexture(self: *AssetManager, asset_name: Types.Asset_Names) !c.Texture2D {
        if (self.textures.get(asset_name)) |texture| return texture;

        const path = self.asset_paths.get(asset_name) orelse return error.AssetNotFound;
        var image = c.LoadImage(path.ptr);
        c.ImageResize(&image, @intCast(Helpers.getImageSize(asset_name).x), @intCast(Helpers.getImageSize(asset_name).y));
        const texture = c.LoadTextureFromImage(image);
        c.UnloadImage(image);

        try self.textures.put(asset_name, texture);
        return texture;
    }

    pub fn getTexture(self: *AssetManager, asset_name: Types.Asset_Names) ?c.Texture2D {
        return self.textures.get(asset_name);
    }
};
