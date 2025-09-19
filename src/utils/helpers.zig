const Types = @import("../types/types.zig");
const Constants = @import("../types/constants.zig");

pub fn getFishSize(species: Types.Species) Types.pair {
    switch (species) {
        Types.Species.GOLDFISH => return Types.pair{ .x = 200, .y = 125 },
    }
}
