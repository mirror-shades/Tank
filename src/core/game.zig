const std = @import("std");
const Types = @import("../types/types.zig");
const c = @import("../utils/cimport.zig");
const Constants = @import("../types/constants.zig");
const Helpers = @import("../utils/helpers.zig");

pub fn updateGameState(gameState: *Types.GameState) bool {
    const currentTime = c.GetTime();
    const deltaTime = currentTime - gameState.lastTime;
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
        }

        var corpseIterator = gameState.corpses.iterator();
        while (corpseIterator.next()) |corpseEntry| {
            corpseEntry.value_ptr.float();
            if (corpseEntry.value_ptr.markForRemoval) {
                _ = gameState.corpses.remove(corpseEntry.key_ptr.*);
            }
        }

        // Collect keys of items to remove
        var toRemove = std.array_list.Managed(u32).init(gameState.fishFoods.allocator);
        defer toRemove.deinit();

        var fishFoodIterator = gameState.fishFoods.iterator();
        while (fishFoodIterator.next()) |fishFoodEntry| {
            fishFoodEntry.value_ptr.sink();
            if (fishFoodEntry.value_ptr.markForRemoval) {
                toRemove.append(fishFoodEntry.key_ptr.*) catch {
                    std.log.err("Failed to append key to remove", .{});
                };
            }
        }

        // Remove items by key
        for (toRemove.items) |key| {
            _ = gameState.fishFoods.remove(key);
        }
        gameState.lastTime = currentTime;
        should_render = true;
    }
    return should_render;
}
