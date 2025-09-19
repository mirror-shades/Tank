const Types = @import("../types/types.zig");
const Constants = @import("../types/constants.zig");

pub fn getImageSize(asset_name: Types.Asset_Names) Types.pair {
    switch (asset_name) {
        Types.Asset_Names.GOLDFISH => return Types.pair{ .x = 200, .y = 125 },
        Types.Asset_Names.GLASS => return Types.pair{ .x = 1500, .y = 800 },
    }
}
