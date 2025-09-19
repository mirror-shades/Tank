const std = @import("std");
const Types = @import("../types/types.zig");
const c = @import("../utils/cimport.zig");
const Helpers = @import("../utils/helpers.zig");

pub const AssetManager = struct {
    textures: std.hash_map.AutoHashMap(Types.Species, c.Texture2D),
    asset_paths: std.hash_map.AutoHashMap(Types.Species, []const u8),

    pub fn init(allocator: std.mem.Allocator) AssetManager {
        var self = AssetManager{
            .textures = std.hash_map.AutoHashMap(Types.Species, c.Texture2D).init(allocator),
            .asset_paths = std.hash_map.AutoHashMap(Types.Species, []const u8).init(allocator),
        };

        self.asset_paths.put(Types.Species.GOLDFISH, "assets/fish/goldfish.png") catch {};

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

    pub fn loadTexture(self: *AssetManager, species: Types.Species) !c.Texture2D {
        if (self.textures.get(species)) |texture| return texture;

        const path = self.asset_paths.get(species) orelse return error.AssetNotFound;
        var image = c.LoadImage(path.ptr);
        c.ImageResize(&image, @intCast(Helpers.getFishSize(species).x), @intCast(Helpers.getFishSize(species).y));
        const texture = c.LoadTextureFromImage(image);
        c.UnloadImage(image);

        try self.textures.put(species, texture);
        return texture;
    }

    pub fn getTexture(self: *AssetManager, species: Types.Species) ?c.Texture2D {
        return self.textures.get(species);
    }
};
