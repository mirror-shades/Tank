const std = @import("std");
const Types = @import("../types/types.zig");
const c = @import("../utils/cimport.zig");
const AssetManager = @import("asset_manager.zig").AssetManager;

pub fn draw(gameState: *Types.GameState) void {
    c.BeginDrawing();
    defer c.EndDrawing();

    c.ClearBackground(c.SKYBLUE);
    drawBackground(&gameState.asset_manager);
    drawFishFoods(&gameState.fishFoods, &gameState.asset_manager);
    drawFishes(&gameState.fishes, &gameState.asset_manager);
    drawForeground(&gameState.asset_manager);
    drawUI(&gameState.asset_manager);
}

fn drawFishes(fishes: *const std.hash_map.AutoHashMap(u32, Types.Fish), asset_manager: *AssetManager) void {
    var fishIterator = fishes.iterator();
    while (fishIterator.next()) |fishEntry| {
        const fish = fishEntry.value_ptr.*;
        if (asset_manager.getTexture(Types.Asset_Names.GOLDFISH)) |texture| {
            const movingRight = fish.current_position.x < fish.next_position.x;
            const width = texture.width;
            const height = texture.height;
            const x = fish.current_position.x;
            const y = fish.current_position.y;

            if (movingRight) {
                // Draw flipped horizontally by using a negative width in source rectangle
                const source = c.Rectangle{
                    .x = @as(f32, @floatFromInt(width)),
                    .y = 0,
                    .width = -@as(f32, @floatFromInt(width)),
                    .height = @as(f32, @floatFromInt(height)),
                };
                const dest = c.Rectangle{
                    .x = @as(f32, @floatFromInt(x)),
                    .y = @as(f32, @floatFromInt(y)),
                    .width = @as(f32, @floatFromInt(width)),
                    .height = @as(f32, @floatFromInt(height)),
                };
                c.DrawTexturePro(texture, source, dest, c.Vector2{ .x = 0, .y = 0 }, 0, c.WHITE);
            } else {
                // Draw normally
                c.DrawTexture(texture, @intCast(x), @intCast(y), c.WHITE);
            }
        }
    }
}

fn drawFishFoods(fishFoods: *const std.hash_map.AutoHashMap(u32, Types.FishFood), asset_manager: *AssetManager) void {
    _ = asset_manager;
    var fishFoodIterator = fishFoods.iterator();
    while (fishFoodIterator.next()) |fishFoodEntry| {
        const fishFood = fishFoodEntry.value_ptr.*;
        c.DrawCircle(fishFood.currentPosition.x, fishFood.currentPosition.y, 10, c.RED);
    }
}

fn drawBackground(asset_manager: *AssetManager) void {
    _ = asset_manager;
}

fn drawForeground(asset_manager: *AssetManager) void {
    if (asset_manager.getTexture(Types.Asset_Names.GLASS)) |texture| {
        c.DrawTexture(texture, -30, -30, c.WHITE);
    }
}

fn drawUI(asset_manager: *AssetManager) void {
    _ = asset_manager;
}
