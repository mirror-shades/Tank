const std = @import("std");
const Types = @import("types/types.zig");
const AssetManager = @import("render/asset_manager.zig").AssetManager;
const c = @import("utils/cimport.zig");
const Draw = @import("render/draw.zig");
const Game = @import("core/game.zig");
const Constants = @import("types/constants.zig");
const Input = @import("core/input.zig");

pub fn main() !void {
    c.InitWindow(Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT, "The Tank");
    defer c.CloseWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var gameState = try Types.GameState.init(gpa.allocator());
    defer gameState.deinit();

    while (!c.WindowShouldClose()) {
        const should_render = Game.updateGameState(&gameState);
        if (should_render) {
            _ = Input.handleInput(&gameState);
            Draw.draw(&gameState);
        }
    }
}
