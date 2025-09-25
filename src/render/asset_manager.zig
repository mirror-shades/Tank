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
        self.asset_paths.put(Types.Asset_Names.CLOWNFISH, "assets/fish/clownfish.png") catch {};
        self.asset_paths.put(Types.Asset_Names.CRAB, "assets/fish/crab.png") catch {};
        self.asset_paths.put(Types.Asset_Names.GUPPY, "assets/fish/guppy.png") catch {};
        self.asset_paths.put(Types.Asset_Names.SHARK, "assets/fish/shark.png") catch {};
        self.asset_paths.put(Types.Asset_Names.BASS, "assets/fish/bass.png") catch {};
        self.asset_paths.put(Types.Asset_Names.SALMON, "assets/fish/salmon.png") catch {};
        self.asset_paths.put(Types.Asset_Names.LOBSTER, "assets/fish/lobster.png") catch {};
        self.asset_paths.put(Types.Asset_Names.NAUTILUS, "assets/fish/nautilus.png") catch {};
        self.asset_paths.put(Types.Asset_Names.OCTOPUS, "assets/fish/octopus.png") catch {};
        self.asset_paths.put(Types.Asset_Names.PIKE, "assets/fish/pike.png") catch {};
        self.asset_paths.put(Types.Asset_Names.SQUID, "assets/fish/squid.png") catch {};
        self.asset_paths.put(Types.Asset_Names.SUNFISH, "assets/fish/sunfish.png") catch {};
        self.asset_paths.put(Types.Asset_Names.TANG, "assets/fish/tang.png") catch {};
        self.asset_paths.put(Types.Asset_Names.TILAPIA, "assets/fish/tilapia.png") catch {};

        self.asset_paths.put(Types.Asset_Names.DEADGOLDFISH, "assets/fish/dead_fish.png") catch {};
        self.asset_paths.put(Types.Asset_Names.COIN, "assets/objects/coin.png") catch {};
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

    pub fn loadTexture(self: *AssetManager, asset_name: Types.Asset_Names) void {
        if (self.textures.get(asset_name)) |_| return;

        const path = self.asset_paths.get(asset_name) orelse {
            std.log.err("Asset not found: {}", .{asset_name});
            return;
        };
        var image = c.LoadImage(path.ptr);
        c.ImageResize(&image, @intCast(Helpers.getImageSize(asset_name).x), @intCast(Helpers.getImageSize(asset_name).y));
        const texture = c.LoadTextureFromImage(image);
        c.UnloadImage(image);

        self.textures.put(asset_name, texture) catch {
            std.log.err("Failed to load texture: {}", .{asset_name});
            return;
        };
    }

    pub fn getTexture(self: *AssetManager, asset_name: Types.Asset_Names) ?c.Texture2D {
        return self.textures.get(asset_name);
    }

    pub fn initImages(self: *AssetManager) void {
        self.loadTexture(Types.Asset_Names.GOLDFISH);
        self.loadTexture(Types.Asset_Names.DEADGOLDFISH);
        self.loadTexture(Types.Asset_Names.GLASS);
        self.loadTexture(Types.Asset_Names.COIN);
        self.loadTexture(Types.Asset_Names.CLOWNFISH);
        self.loadTexture(Types.Asset_Names.CRAB);
        self.loadTexture(Types.Asset_Names.GUPPY);
        self.loadTexture(Types.Asset_Names.SHARK);
        self.loadTexture(Types.Asset_Names.BASS);
        self.loadTexture(Types.Asset_Names.SALMON);
        self.loadTexture(Types.Asset_Names.LOBSTER);
        self.loadTexture(Types.Asset_Names.NAUTILUS);
        self.loadTexture(Types.Asset_Names.OCTOPUS);
        self.loadTexture(Types.Asset_Names.PIKE);
        self.loadTexture(Types.Asset_Names.SQUID);
        self.loadTexture(Types.Asset_Names.SUNFISH);
        self.loadTexture(Types.Asset_Names.TANG);
        self.loadTexture(Types.Asset_Names.TILAPIA);
    }
};
