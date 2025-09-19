const std = @import("std");
const Types = @import("../types/types.zig");
const c = @import("../utils/cimport.zig");
const AssetManager = @import("asset_manager.zig").AssetManager;

pub fn draw(gameState: *Types.GameState) void {
    c.BeginDrawing();
    defer c.EndDrawing();

    c.ClearBackground(c.SKYBLUE);
    drawBackground(&gameState.assetManager);
    drawFishFoods(&gameState.fishFoods, &gameState.assetManager);
    drawCorpses(&gameState.corpses, &gameState.assetManager);
    drawFishes(&gameState.fishes, &gameState.assetManager);
    drawForeground(&gameState.assetManager);
    drawUI(&gameState.assetManager);
}

fn drawFishes(fishes: *const std.hash_map.AutoHashMap(u32, Types.Fish), assetManager: *AssetManager) void {
    var fishIterator = fishes.iterator();
    while (fishIterator.next()) |fishEntry| {
        const fish = fishEntry.value_ptr.*;
        if (assetManager.getTexture(Types.Asset_Names.GOLDFISH)) |texture| {
            const movingRight = fish.current_position.x < fish.next_position.x;
            const width = texture.width;
            const height = texture.height;
            const x = fish.current_position.x;
            const y = fish.current_position.y;

            var textureColor = c.WHITE;
            if (fish.hunger == Types.Hunger.HUNGRY) {
                textureColor = c.ORANGE;
            } else if (fish.hunger == Types.Hunger.STARVING) {
                textureColor = c.RED;
            }

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
                c.DrawTexturePro(texture, source, dest, c.Vector2{ .x = 0, .y = 0 }, 0, textureColor);
            } else {
                // Draw normally
                c.DrawTexture(texture, @intCast(x), @intCast(y), textureColor);
            }
        }
    }
}

fn drawFishFoods(fishFoods: *const std.hash_map.AutoHashMap(u32, Types.FishFood), assetManager: *AssetManager) void {
    _ = assetManager;
    var fishFoodIterator = fishFoods.iterator();
    while (fishFoodIterator.next()) |fishFoodEntry| {
        const fishFood = fishFoodEntry.value_ptr.*;
        c.DrawCircle(fishFood.currentPosition.x, fishFood.currentPosition.y, 10, c.RED);
    }
}

fn drawCorpses(corpses: *const std.hash_map.AutoHashMap(u32, Types.Corpse), assetManager: *AssetManager) void {
    var corpseIterator = corpses.iterator();
    while (corpseIterator.next()) |corpseEntry| {
        const corpse = corpseEntry.value_ptr.*;
        if (assetManager.getTexture(Types.Asset_Names.DEADGOLDFISH)) |texture| {
            const width = texture.width;
            const height = texture.height;
            const x = corpse.currentPosition.x;
            const y = corpse.currentPosition.y;

            // Draw flipped vertically by using a negative height in source rectangle
            const source = c.Rectangle{
                .x = 0,
                .y = @as(f32, @floatFromInt(height)),
                .width = @as(f32, @floatFromInt(width)),
                .height = -@as(f32, @floatFromInt(height)),
            };
            const dest = c.Rectangle{
                .x = @as(f32, @floatFromInt(x)),
                .y = @as(f32, @floatFromInt(y)),
                .width = @as(f32, @floatFromInt(width)),
                .height = @as(f32, @floatFromInt(height)),
            };
            c.DrawTexturePro(texture, source, dest, c.Vector2{ .x = 0, .y = 0 }, 0, c.WHITE);
        } else {
            std.log.info("Corpse texture not available", .{});
        }
    }
}

fn drawBackground(assetManager: *AssetManager) void {
    _ = assetManager;
}

fn drawForeground(assetManager: *AssetManager) void {
    if (assetManager.getTexture(Types.Asset_Names.GLASS)) |texture| {
        c.DrawTexture(texture, -30, -30, c.WHITE);
    }
}

fn drawUI(assetManager: *AssetManager) void {
    _ = assetManager;
}
