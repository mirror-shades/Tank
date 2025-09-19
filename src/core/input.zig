const c = @import("../utils/cimport.zig");
const Types = @import("../types/types.zig");
const std = @import("std");

pub fn handleInput(gameState: *Types.GameState) c.InputState {
    if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
        std.log.info("Left mouse clicked at: {d}, {d}", .{ c.GetMousePosition().x, c.GetMousePosition().y });
        const mouse_pos = c.GetMousePosition();
        const coords = Types.pair{ .x = @as(u16, @intFromFloat(mouse_pos.x)), .y = @as(u16, @intFromFloat(mouse_pos.y)) };
        spawnFishFood(coords, gameState);
        return c.InputState.MOUSE_LEFT_CLICK;
    }
    return c.InputState.NONE;
}

fn spawnFishFood(coords: Types.pair, gameState: *Types.GameState) void {
    const fishFood = Types.FishFood.new(coords, Types.FoodType.PELLET);
    gameState.fishFoods.put(gameState.fishFoodIdCounter, fishFood) catch {
        std.log.err("Failed to append fish food", .{});
    };
}
