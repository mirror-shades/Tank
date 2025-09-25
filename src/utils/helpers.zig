const Types = @import("../types/types.zig");
const Constants = @import("../types/constants.zig");

pub fn getImageSize(asset_name: Types.Asset_Names) Types.Pair {
    switch (asset_name) {
        Types.Asset_Names.GOLDFISH => return Types.Pair{ .x = 100, .y = 75 },
        Types.Asset_Names.DEADGOLDFISH => return Types.Pair{ .x = 200, .y = 125 },
        Types.Asset_Names.GLASS => return Types.Pair{ .x = 1500, .y = 800 },
        Types.Asset_Names.COIN => return Types.Pair{ .x = 40, .y = 40 },

        else => return Types.Pair{ .x = 200, .y = 125 },
    }
}

pub fn speciesToAsset(species: Types.Species) Types.Asset_Names {
    switch (species) {
        Types.Species.GOLDFISH => return Types.Asset_Names.GOLDFISH,
    }
}

pub fn pairInRect(pair: Types.Pair, rect: Types.Rect) bool {
    return rect.contains(pair);
}
