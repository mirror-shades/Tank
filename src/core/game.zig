const std = @import("std");
const Types = @import("../types/types.zig");
const c = @import("../utils/cimport.zig");
const Constants = @import("../types/constants.zig");
const Helpers = @import("../utils/helpers.zig");

pub fn updateGameState(gameState: *Types.GameState) bool {
    const newCurrentTime = c.GetTime();
    const deltaTime = newCurrentTime - gameState.currentTime;
    var should_render = false;
    if (deltaTime > 0.016) {
        gameState.frameCounter += 1;

        var fishIterator = gameState.fishes.iterator();
        while (fishIterator.next()) |fishEntry| {
            fishEntry.value_ptr.updateHunger(gameState);
            if (fishEntry.value_ptr.dead) {
                gameState.corpses.put(fishEntry.key_ptr.*, Types.Corpse.new(fishEntry.value_ptr.current_position, fishEntry.value_ptr.species)) catch {
                    std.log.err("Failed to add corpse", .{});
                };
                _ = gameState.fishes.remove(fishEntry.key_ptr.*);
                continue;
            }
            fishEntry.value_ptr.move(gameState, fishEntry.value_ptr.next_position);
            if (fishEntry.value_ptr.species == Types.Species.GOLDFISH) {
                if (fishEntry.value_ptr.droppedCoin + 400 < gameState.frameCounter) {
                    std.log.info("Dropping coin\n", .{});
                    fishEntry.value_ptr.droppedCoin = gameState.frameCounter;
                    gameState.addCoin(fishEntry.value_ptr.current_position);
                }
            }
        }

        var corpseIterator = gameState.corpses.iterator();
        while (corpseIterator.next()) |corpseEntry| {
            corpseEntry.value_ptr.float();
            if (corpseEntry.value_ptr.markForRemoval) {
                _ = gameState.corpses.remove(corpseEntry.key_ptr.*);
            }
        }

        var coinIterator = gameState.coins.iterator();
        while (coinIterator.next()) |coinEntry| {
            coinEntry.value_ptr.sink();
            if (coinEntry.value_ptr.markForRemoval) {
                _ = gameState.coins.remove(coinEntry.key_ptr.*);
            }
        }

        var fishFoodIterator = gameState.fishFoods.iterator();
        while (fishFoodIterator.next()) |fishFoodEntry| {
            fishFoodEntry.value_ptr.sink();
            if (fishFoodEntry.value_ptr.markForRemoval) {
                _ = gameState.fishFoods.remove(fishFoodEntry.key_ptr.*);
            }
        }

        gameState.currentTime = newCurrentTime;
        should_render = true;
    }
    return should_render;
}
