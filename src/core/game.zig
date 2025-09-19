const std = @import("std");
const Types = @import("../types/types.zig");
const c = @import("../utils/cimport.zig");
const Constants = @import("../types/constants.zig");
const Helpers = @import("../utils/helpers.zig");

pub fn updateGameState(gameState: *Types.GameState, input: c.InputState) void {
    _ = input;
    gameState.frameCounter += 1;

    var fishIterator = gameState.fishes.iterator();
    while (fishIterator.next()) |fishEntry| {
        fishEntry.value_ptr.move(gameState, fishEntry.value_ptr.next_position);
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
}
