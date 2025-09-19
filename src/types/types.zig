const std = @import("std");
pub const Constants = @import("constants.zig");
pub const Helpers = @import("../utils/helpers.zig");
const AssetManager = @import("../render/asset_manager.zig").AssetManager;
const initImages = @import("../render/init_images.zig").initImages;

pub const Asset_Names = enum {
    GOLDFISH,
    DEADGOLDFISH,
    GLASS,
};

pub const Hunger = enum {
    FULL,
    HUNGRY,
    STARVING,
};

pub const Species = enum {
    GOLDFISH,
};

pub const FoodType = enum {
    PELLET,
};

pub const pair = struct {
    x: i32,
    y: i32,

    pub fn equals(self: *const pair, other: *const pair) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn distance(self: *const pair, other: *const pair) f32 {
        return @sqrt(@as(f32, @floatFromInt(self.x - other.x)) * @as(f32, @floatFromInt(self.x - other.x)) + @as(f32, @floatFromInt(self.y - other.y)) * @as(f32, @floatFromInt(self.y - other.y)));
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
    lastTime: f64,
    fishes: std.hash_map.AutoHashMap(u32, Fish),
    fishFoods: std.hash_map.AutoHashMap(u32, FishFood),
    corpses: std.hash_map.AutoHashMap(u32, Corpse),
    assetManager: AssetManager,

    pub fn init(allocator: std.mem.Allocator) !GameState {
        var assetManager = AssetManager.init(allocator);
        try initImages(&assetManager);
        var fishes = std.hash_map.AutoHashMap(u32, Fish).init(allocator);
        try fishes.put(0, Fish.new(Species.GOLDFISH));
        const fishFoods = std.hash_map.AutoHashMap(u32, FishFood).init(allocator);
        const corpses = std.hash_map.AutoHashMap(u32, Corpse).init(allocator);
        return GameState{ .frameCounter = 0, .fishIdCounter = 0, .fishFoodIdCounter = 0, .lastTime = 0, .fishes = fishes, .fishFoods = fishFoods, .assetManager = assetManager, .corpses = corpses };
    }

    pub fn deinit(self: *GameState) void {
        self.fishes.deinit();
        self.fishFoods.deinit();
        self.assetManager.deinit();
        self.corpses.deinit();
    }

    pub fn addFish(self: *GameState) void {
        self.fishIdCounter += 1;
        self.fishes.put(self.fishIdCounter, Fish.new(Species.GOLDFISH)) catch {
            std.log.err("Failed to add fish", .{});
        };
    }

    pub fn addFishFood(self: *GameState, coords: pair, foodType: FoodType) void {
        self.fishFoodIdCounter += 1;
        self.fishFoods.put(self.fishFoodIdCounter, FishFood.new(coords, foodType)) catch {
            std.log.err("Failed to add fish food", .{});
        };
    }

    pub fn foodExists(self: *GameState) bool {
        return self.fishFoods.count() > 0;
    }
};

pub const Corpse = struct {
    currentPosition: pair,
    species: Species,
    markForRemoval: bool,

    pub fn new(coords: pair, species: Species) Corpse {
        return Corpse{ .currentPosition = coords, .species = species, .markForRemoval = false };
    }

    pub fn float(self: *Corpse) void {
        self.currentPosition.y -= 1;
        if (self.currentPosition.y < -25) {
            self.markForRemoval = true;
        }
    }
};

pub const Fish = struct {
    current_position: pair,
    next_position: pair,

    species: Species,
    lastAte: u64,
    hunger: Hunger,
    dead: bool,

    pub fn new(_species: Species) Fish {
        const rand = std.crypto.random;
        const _x = rand.intRangeAtMost(i32, 0, Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x);
        const _y = rand.intRangeAtMost(i32, 0, Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y);
        return Fish{
            .current_position = pair{ .x = _x, .y = _y },
            .next_position = pair{ .x = _x, .y = _y },
            .species = _species,
            .lastAte = 0,
            .hunger = Hunger.FULL,
            .dead = false,
        };
    }

    pub fn updateHunger(self: *Fish, gameState: *GameState) void {
        if (self.hunger == Hunger.FULL and gameState.frameCounter - self.lastAte > 500) {
            self.hunger = Hunger.HUNGRY;
        }
        if (self.hunger == Hunger.HUNGRY and gameState.frameCounter - self.lastAte > 1000) {
            self.hunger = Hunger.STARVING;
        }
        if (self.hunger == Hunger.STARVING and gameState.frameCounter - self.lastAte > 1500) {
            self.dead = true;
        }
    }

    pub fn move(self: *Fish, gameState: *GameState, new_coords: pair) void {
        var speed: i32 = 1;
        if (self.current_position.equals(&new_coords)) {
            const rand = std.crypto.random;
            var newX = rand.intRangeAtMost(i32, 0, Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x);
            const newY = rand.intRangeAtMost(i32, 0, Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y);

            const x_delta = @as(i32, newX) - @as(i32, self.current_position.x);
            const y_delta = @as(i32, newY) - @as(i32, self.current_position.y);

            var x_mod: i32 = 1;
            if (x_delta < 0) {
                x_mod = -1;
            }

            if (y_delta != 0 and @abs(x_delta) <= @abs(y_delta)) {
                const abs_y_delta: i32 = @intCast(@abs(y_delta));
                newX = @intCast(@as(i32, self.current_position.x) + x_mod * abs_y_delta);

                // Clamp to window bounds
                if (newX > Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x) {
                    newX = Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x;
                }
            }
            self.next_position = pair{ .x = newX, .y = newY };
        } else {
            if (self.hunger != Hunger.FULL and gameState.foodExists()) {
                var fishFoodIterator = gameState.fishFoods.iterator();
                var closestFoodKey: ?u32 = null;
                var closestDistance: f32 = std.math.inf(f32);

                while (fishFoodIterator.next()) |fishFoodEntry| {
                    const distance = fishFoodEntry.value_ptr.currentPosition.distance(&self.current_position);
                    if (distance < closestDistance) {
                        closestFoodKey = fishFoodEntry.key_ptr.*;
                        closestDistance = distance;
                    }
                }

                if (closestFoodKey != null) {
                    // Get the food and calculate the offset target position
                    if (gameState.fishFoods.get(closestFoodKey.?)) |food| {
                        const fishSize = Helpers.getImageSize(Asset_Names.GOLDFISH);
                        const targetX = food.currentPosition.x - @divTrunc(fishSize.x, 2);
                        const targetY = food.currentPosition.y - @divTrunc(fishSize.y, 2);
                        const targetPos = pair{ .x = targetX, .y = targetY };
                        const distanceToTarget = targetPos.distance(&self.current_position);

                        // Check if fish is close enough to the TARGET position to eat the food
                        if (distanceToTarget < 50) {
                            // Remove the food immediately using the key
                            _ = gameState.fishFoods.remove(closestFoodKey.?);

                            self.hunger = Hunger.FULL; // Fish is no longer hungry
                            self.lastAte = gameState.frameCounter;

                            // Reset to a new random position after eating
                            const rand = std.crypto.random;
                            const newX = rand.intRangeAtMost(i32, 0, Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x);
                            const newY = rand.intRangeAtMost(i32, 0, Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y);
                            self.next_position = pair{ .x = newX, .y = newY };
                        } else {
                            // Move toward the target position
                            self.next_position = targetPos;
                            speed = 2;
                        }
                    } else {
                        // Food was removed by something else, reset to random position
                        const rand = std.crypto.random;
                        const newX = rand.intRangeAtMost(i32, 0, Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x);
                        const newY = rand.intRangeAtMost(i32, 0, Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y);
                        self.next_position = pair{ .x = newX, .y = newY };
                    }
                }
            }

            // Always move toward the target (whether it's food or random position)
            const x_delta = new_coords.x - self.current_position.x;
            const y_delta = new_coords.y - self.current_position.y;

            if (x_delta != 0 or y_delta != 0) {
                const abs_x = @abs(x_delta);
                const abs_y = @abs(y_delta);

                if (abs_x > abs_y) {
                    // Move more in x direction
                    self.current_position.x += if (x_delta > 0) speed else -@as(i32, speed);
                    if (abs_y > 0 and @rem(abs_x, abs_y) == 0) {
                        self.current_position.y += if (y_delta > 0) speed else -@as(i32, speed);
                    }
                } else if (abs_y > abs_x) {
                    // Move more in y direction
                    self.current_position.y += if (y_delta > 0) speed else -@as(i32, speed);
                    if (abs_x > 0 and @rem(abs_y, abs_x) == 0) {
                        self.current_position.x += if (x_delta > 0) speed else -@as(i32, speed);
                    }
                } else {
                    // Equal movement in both directions
                    self.current_position.x += if (x_delta > 0) speed else -@as(i32, speed);
                    self.current_position.y += if (y_delta > 0) speed else -@as(i32, speed);
                }
            }
        }
    }
};
