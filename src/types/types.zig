const std = @import("std");
pub const Constants = @import("constants.zig");
pub const Helpers = @import("../utils/helpers.zig");
const AssetManager = @import("../render/asset_manager.zig").AssetManager;
const c = @import("../utils/cimport.zig");

pub const Asset_Names = enum {
    GOLDFISH,
    CLOWNFISH,
    CRAB,
    GUPPY,
    SHARK,
    BASS,
    SALMON,
    LOBSTER,
    NAUTILUS,
    OCTOPUS,
    PIKE,
    SQUID,
    SUNFISH,
    TANG,
    TILAPIA,

    DEADGOLDFISH,
    GLASS,
    COIN,
};

pub const Collections = enum {
    FISHES,
    FISHFOODS,
    CORPSES,
    COINS,
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

pub const Pair = struct {
    x: i32,
    y: i32,

    pub fn equals(self: *const Pair, other: *const Pair) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn distance(self: *const Pair, other: *const Pair) f32 {
        return @sqrt(@as(f32, @floatFromInt(self.x - other.x)) * @as(f32, @floatFromInt(self.x - other.x)) + @as(f32, @floatFromInt(self.y - other.y)) * @as(f32, @floatFromInt(self.y - other.y)));
    }
};

pub const Rect = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

    pub fn contains(self: *const Rect, point: Pair) bool {
        return point.x >= self.x and
            point.x < self.x + self.w and
            point.y >= self.y and
            point.y < self.y + self.h;
    }

    pub fn fromPositionAndSize(pos: Pair, size: Pair) Rect {
        return Rect{
            .x = pos.x,
            .y = pos.y,
            .w = size.x,
            .h = size.y,
        };
    }
};

pub const FishFood = struct {
    currentPosition: Pair,
    foodType: FoodType,
    markForRemoval: bool,

    pub fn new(coords: Pair, foodType: FoodType) FishFood {
        return FishFood{ .currentPosition = coords, .foodType = foodType, .markForRemoval = false };
    }

    pub fn sink(self: *FishFood) void {
        self.currentPosition.y += 1;
        if (self.currentPosition.y > Constants.WINDOW_HEIGHT + 25) {
            self.markForRemoval = true;
        }
    }
};

pub const Coin = struct {
    currentPosition: Pair,
    markForRemoval: bool,

    pub fn new(coords: Pair) Coin {
        return Coin{ .currentPosition = coords, .markForRemoval = false };
    }

    pub fn sink(self: *Coin) void {
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
    coinIdCounter: u32,
    currentTime: f64,
    maxFood: u8,
    xp: u32,
    level: u8,
    gold: u32,
    coins: std.hash_map.AutoHashMap(u32, Coin),
    fishes: std.hash_map.AutoHashMap(u32, Fish),
    fishFoods: std.hash_map.AutoHashMap(u32, FishFood),
    corpses: std.hash_map.AutoHashMap(u32, Corpse),
    assetManager: AssetManager,

    pub fn init(allocator: std.mem.Allocator) !GameState {
        const initialFrameCounter = 0;
        var assetManager = AssetManager.init(allocator);
        assetManager.initImages();
        const fishes = std.hash_map.AutoHashMap(u32, Fish).init(allocator);
        const fishFoods = std.hash_map.AutoHashMap(u32, FishFood).init(allocator);
        const corpses = std.hash_map.AutoHashMap(u32, Corpse).init(allocator);
        const coins = std.hash_map.AutoHashMap(u32, Coin).init(allocator);
        return GameState{ .frameCounter = initialFrameCounter, .maxFood = 1, .fishIdCounter = 1, .fishFoodIdCounter = 0, .coinIdCounter = 0, .currentTime = 0, .xp = 0, .level = 1, .gold = 100, .fishes = fishes, .fishFoods = fishFoods, .assetManager = assetManager, .corpses = corpses, .coins = coins };
    }

    pub fn deinit(self: *GameState) void {
        self.fishes.deinit();
        self.fishFoods.deinit();
        self.assetManager.deinit();
        self.corpses.deinit();
    }

    pub fn addFish(self: *GameState, species: Species, x: i32, y: i32) void {
        var _x = x;
        var _y = y;
        if (x < 0 and y < 0) {
            const rand = std.crypto.random;
            _x = rand.intRangeAtMost(i32, 0, Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x);
            _y = rand.intRangeAtMost(i32, 0, Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y);
        }
        self.fishIdCounter += 1;
        self.fishes.put(self.fishIdCounter, Fish.new(species, self.frameCounter, _x, _y)) catch {
            std.log.err("Failed to add fish", .{});
        };
    }

    pub fn addFishFood(self: *GameState, coords: Pair, foodType: FoodType) void {
        self.fishFoodIdCounter += 1;
        self.fishFoods.put(self.fishFoodIdCounter, FishFood.new(coords, foodType)) catch {
            std.log.err("Failed to add fish food", .{});
        };
    }

    pub fn addCoin(self: *GameState, coords: Pair) void {
        self.coinIdCounter += 1;
        self.coins.put(self.coinIdCounter, Coin.new(coords)) catch {
            std.log.err("Failed to add coin", .{});
        };
    }

    pub fn isInCoin(self: *GameState, coords: Pair) ?u32 {
        var coinIterator = self.coins.iterator();
        while (coinIterator.next()) |coinEntry| {
            const coinRect = Rect.fromPositionAndSize(coinEntry.value_ptr.currentPosition, Helpers.getImageSize(Asset_Names.COIN));
            if (coinRect.contains(coords)) {
                return coinEntry.key_ptr.*;
            }
        }
        return null;
    }

    pub fn foodExists(self: *GameState) bool {
        return self.fishFoods.count() > 0;
    }

    pub fn getCollectionCount(self: *GameState, collection: Collections) u32 {
        switch (collection) {
            Collections.FISHES => return self.fishes.count(),
            Collections.FISHFOODS => return self.fishFoods.count(),
            Collections.CORPSES => return self.corpses.count(),
            Collections.COINS => return self.coins.count(),
        }
    }
};

pub const Corpse = struct {
    currentPosition: Pair,
    species: Species,
    markForRemoval: bool,

    pub fn new(coords: Pair, species: Species) Corpse {
        return Corpse{ .currentPosition = coords, .species = species, .markForRemoval = false };
    }

    pub fn float(self: *Corpse) void {
        self.currentPosition.y -= 1;
        if (self.currentPosition.y < -250) {
            self.markForRemoval = true;
        }
    }
};

pub const Fish = struct {
    current_position: Pair,
    next_position: Pair,

    species: Species,
    lastAte: u64,
    gaveBirth: u64,
    droppedCoin: u64,
    hunger: Hunger,
    dead: bool,
    birthtime: u64,

    pub fn new(_species: Species, frameCounter: u64, x: i32, y: i32) Fish {
        const _x = x;
        const _y = y;
        return Fish{
            .current_position = Pair{ .x = _x, .y = _y },
            .next_position = Pair{ .x = _x, .y = _y },
            .species = _species,
            .lastAte = frameCounter,
            .gaveBirth = frameCounter,
            .droppedCoin = frameCounter,
            .hunger = Hunger.FULL,
            .dead = false,
            .birthtime = frameCounter,
        };
    }

    pub fn updateHunger(self: *Fish, gameState: *GameState) void {
        if (gameState.frameCounter - self.lastAte > 1500) {
            self.dead = true;
        } else if (gameState.frameCounter - self.lastAte > 1000) {
            self.hunger = Hunger.STARVING;
        } else if (gameState.frameCounter - self.lastAte > 500) {
            self.hunger = Hunger.HUNGRY;
        } else {
            self.hunger = Hunger.FULL;
        }
    }

    pub fn dropCoin(self: *Fish, gameState: *GameState) void {
        gameState.addCoin(self.current_position);
    }

    fn pickRandomPosition() Pair {
        const rand = std.crypto.random;
        return Pair{ .x = rand.intRangeAtMost(i32, 0, Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x), .y = rand.intRangeAtMost(i32, 0, Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y) };
    }

    fn findClosestFood(self: *Fish, gameState: *GameState) ?u32 {
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
        return closestFoodKey;
    }

    fn clampToWindowBounds(new_coords: Pair) Pair {
        var newX = new_coords.x;
        var newY = new_coords.y;
        if (newX < 0) {
            newX = 0;
        }
        if (newX > Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x) {
            newX = Constants.WINDOW_WIDTH - Helpers.getImageSize(Asset_Names.GOLDFISH).x;
        }
        if (newY < 0) {
            newY = 0;
        }
        if (newY > Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y) {
            newY = Constants.WINDOW_HEIGHT - Helpers.getImageSize(Asset_Names.GOLDFISH).y;
        }
        return Pair{ .x = newX, .y = newY };
    }

    pub fn getBounds(self: *Fish) Rect {
        const size = Helpers.getImageSize(Helpers.speciesToAsset(self.species));
        return Rect.fromPositionAndSize(self.current_position, size);
    }

    pub fn isPointInFish(self: *Fish, point: Pair) bool {
        return Helpers.pairInRect(point, self.getBounds());
    }

    pub fn move(self: *Fish, gameState: *GameState, new_coords: Pair) void {
        var speed: i32 = 1;
        if (self.current_position.equals(&new_coords)) {
            const random_coords = pickRandomPosition();
            var newX = random_coords.x;
            const newY = random_coords.y;

            const x_delta = @as(i32, newX) - @as(i32, self.current_position.x);
            const y_delta = @as(i32, newY) - @as(i32, self.current_position.y);

            var x_mod: i32 = 1;
            if (x_delta < 0) {
                x_mod = -1;
            }

            if (y_delta != 0 and @abs(x_delta) <= @abs(y_delta)) {
                const abs_y_delta: i32 = @intCast(@abs(y_delta));
                newX = @intCast(@as(i32, self.current_position.x) + x_mod * abs_y_delta);

                // this helps prevent little gitchy looking movements
                if (x_delta < 25) { // move too small
                    // don't run into the wall
                    if (newX < Constants.WINDOW_WIDTH - 50) {
                        newX -= 50;
                    } else {
                        newX += 50;
                    }
                }

                // Clamp to window bounds
                const newPair = Pair{ .x = newX, .y = self.current_position.y };
                newX = clampToWindowBounds(newPair).x;
            }
            self.next_position = Pair{ .x = newX, .y = newY };
        } else {
            if (self.hunger != Hunger.FULL and gameState.foodExists()) {
                const closestFoodKey = self.findClosestFood(gameState);
                const closestFoodPos = gameState.fishFoods.get(closestFoodKey.?).?.currentPosition;

                if (closestFoodKey != null) {
                    const fishSize = Helpers.getImageSize(Asset_Names.GOLDFISH);
                    const targetX = closestFoodPos.x - @divTrunc(fishSize.x, 2);
                    const targetY = closestFoodPos.y - @divTrunc(fishSize.y, 2);

                    // Clamp target position to keep fish within screen bounds
                    const targetPos = Pair{ .x = targetX, .y = targetY };
                    const ClampedTargetPos = clampToWindowBounds(targetPos);

                    // Move toward the target position
                    self.next_position = ClampedTargetPos;
                    speed = 2;

                    if (self.isPointInFish(closestFoodPos)) {
                        self.lastAte = gameState.frameCounter;
                        _ = gameState.fishFoods.remove(closestFoodKey.?);
                    }
                } else {
                    // Food was removed by something else, reset to random position
                    const random_coords = pickRandomPosition();
                    const newX = random_coords.x;
                    const newY = random_coords.y;
                    self.next_position = Pair{ .x = newX, .y = newY };
                }
            }

            // Always move toward the target (whether it's food or random position)
            // Use smooth diagonal movement for both cases
            const x_delta = self.next_position.x - self.current_position.x;
            const y_delta = self.next_position.y - self.current_position.y;

            // Move smoothly toward target
            if (x_delta != 0) {
                self.current_position.x += if (x_delta > 0) speed else -@as(i32, speed);
            }
            if (y_delta != 0) {
                self.current_position.y += if (y_delta > 0) speed else -@as(i32, speed);
            }

            // Clamp to window bounds
            self.current_position = clampToWindowBounds(self.current_position);
        }
    }
};
