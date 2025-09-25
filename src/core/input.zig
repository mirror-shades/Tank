const std = @import("std");
const c = @import("../utils/cimport.zig");
const Types = @import("../types/types.zig");
const Constants = @import("../types/constants.zig");
const Helpers = @import("../utils/helpers.zig");

pub fn handleInput(gameState: *Types.GameState) c.InputState {
    if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
        const mouse_pos = c.GetMousePosition();
        const coords = Types.Pair{ .x = @as(i32, @intFromFloat(mouse_pos.x)), .y = @as(i32, @intFromFloat(mouse_pos.y)) };
        const numberOfFood = gameState.getCollectionCount(Types.Collections.FISHFOODS);

        std.debug.print("x: {d}, y: {d}\n", .{ coords.x, coords.y });
        var coinIterator = gameState.coins.iterator();
        while (coinIterator.next()) |coinEntry| {
            std.debug.print("coin x: {d}, y: {d}\n", .{ coinEntry.value_ptr.currentPosition.x, coinEntry.value_ptr.currentPosition.y });
        }

        const isInCoin = gameState.isInCoin(coords);
        std.debug.print("isInCoin: {any}\n", .{isInCoin});
        std.debug.print("coin count: {d}\n", .{gameState.coins.count()});

        if (gameState.isInCoin(coords)) |coinId| {
            gameState.gold += 10;
            _ = gameState.coins.remove(coinId);
        } else if (numberOfFood < gameState.maxFood) {
            spawnFishFood(coords, gameState);
        }
        return c.InputState.MOUSE_LEFT_CLICK;
    }
    return c.InputState.NONE;
}

fn spawnFishFood(coords: Types.Pair, gameState: *Types.GameState) void {
    var x = coords.x;
    if (x < 25) {
        x = 25;
    } else if (x > Constants.WINDOW_WIDTH - 25) {
        x = Constants.WINDOW_WIDTH - 25;
    }

    const newCoords = Types.Pair{ .x = x, .y = coords.y };
    const safeCoords = Types.Pair{ .x = newCoords.x, .y = newCoords.y };
    gameState.addFishFood(safeCoords, Types.FoodType.PELLET);
}
