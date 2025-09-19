const std = @import("std");
pub const Constants = @import("constants.zig");
pub const Helpers = @import("../utils/helpers.zig");
const AssetManager = @import("../render/asset_manager.zig").AssetManager;
const initImages = @import("../render/init_images.zig").initImages;

pub const Species = enum {
    GOLDFISH,
};

pub const FoodType = enum {
    PELLET,
};

pub const pair = struct {
    x: u16,
    y: u16,

    pub fn equals(self: *const pair, other: *const pair) bool {
        return self.x == other.x and self.y == other.y;
    }
};

pub const FishFood = struct {
    currentPosition: pair,
    foodType: FoodType,
    markForRemoval: bool,

    pub fn new(coords: pair, foodType: FoodType) FishFood {
        return FishFood{ .currentPosition = coords, .foodType = foodType, .markForRemoval = false };
    }

    pub fn sink(self: *FishFood) void {
        self.currentPosition.y += 1;
        if (self.currentPosition.y > Constants.WINDOW_HEIGHT + 25) {
            self.markForRemoval = true;
        }
    }
};

pub const GameState = struct {
    frameCounter: u64,
    fishIdCounter: u32,
    fishFoodIdCounter: u32,
    fishes: std.hash_map.AutoHashMap(u32, Fish),
    fishFoods: std.hash_map.AutoHashMap(u32, FishFood),
    asset_manager: AssetManager,

    pub fn init(allocator: std.mem.Allocator) !GameState {
        var asset_manager = AssetManager.init(allocator);
        try initImages(&asset_manager);
        var fishes = std.hash_map.AutoHashMap(u32, Fish).init(allocator);
        try fishes.put(0, Fish.new(Species.GOLDFISH));
        const fishFoods = std.hash_map.AutoHashMap(u32, FishFood).init(allocator);
        return GameState{ .frameCounter = 0, .fishIdCounter = 0, .fishFoodIdCounter = 0, .fishes = fishes, .fishFoods = fishFoods, .asset_manager = asset_manager };
    }

    pub fn deinit(self: *GameState) void {
        self.fishes.deinit();
        self.fishFoods.deinit();
        self.asset_manager.deinit();
    }

    pub fn addFish(self: *GameState) void {
        self.fishIdCounter += 1;
        self.fishes.put(self.fishIdCounter, Fish.new(Species.GOLDFISH)) catch {
            std.log.err("Failed to add fish", .{});
        };
    }

    pub fn addFishFood(self: *GameState) void {
        self.fishFoodIdCounter += 1;
        self.fishFoods.put(self.fishFoodIdCounter, FishFood.new(pair{ .x = 0, .y = 0 }, FoodType.PELLET)) catch {
            std.log.err("Failed to add fish food", .{});
        };
    }
};

pub const Fish = struct {
    current_position: pair,
    next_position: pair,

    species: Species,
    lastAte: u64,
    isHungry: bool,
    lastMoved: u64,

    pub fn new(_species: Species) Fish {
        const rand = std.crypto.random;
        const _x = rand.intRangeAtMost(u16, 0, Constants.WINDOW_WIDTH - Helpers.getFishSize(_species).x);
        const _y = rand.intRangeAtMost(u16, 0, Constants.WINDOW_HEIGHT - Helpers.getFishSize(_species).y);
        return Fish{
            .current_position = pair{ .x = _x, .y = _y },
            .next_position = pair{ .x = _x, .y = _y },
            .species = _species,
            .lastAte = 0,
            .isHungry = false,
            .lastMoved = 0,
        };
    }

    pub fn moveSlow(self: *Fish) void {
        self.move(self.next_position, 1);
    }

    pub fn moveFast(self: *Fish) void {
        self.move(self.next_position, 2);
    }

    fn move(self: *Fish, new_coords: pair, speed: u8) void {
        if (self.current_position.equals(&new_coords)) {
            const rand = std.crypto.random;
            const newX = rand.intRangeAtMost(u16, 0, Constants.WINDOW_WIDTH - Helpers.getFishSize(self.species).x);
            const newY = rand.intRangeAtMost(u16, 0, Constants.WINDOW_HEIGHT - Helpers.getFishSize(self.species).y);
            self.next_position = pair{ .x = newX, .y = newY };
        } else {
            if (new_coords.x < self.current_position.x) {
                self.current_position.x -= speed;
            } else if (new_coords.x > self.current_position.x) {
                self.current_position.x += speed;
            }

            if (new_coords.y < self.current_position.y) {
                self.current_position.y -= speed;
            } else if (new_coords.y > self.current_position.y) {
                self.current_position.y += speed;
            }
        }
    }
};
