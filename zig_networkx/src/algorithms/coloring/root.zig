// Módulo principal para algoritmos de coloração

const std = @import("std");

pub const greedy_color = @import("greedy_color.zig");
pub const brelaz_color = @import("brelaz_color.zig");

// Re-export functions for convenience
pub const OrderingStrategy = greedy_color.OrderingStrategy;
pub const ColoringResult = greedy_color.ColoringResult;
pub const DSaturResult = brelaz_color.DSaturResult;

pub const greedyColor = greedy_color.greedyColor;
pub const welshPowellColor = greedy_color.welshPowellColor;
pub const isValidColoring = greedy_color.isValidColoring;
pub const brelazColor = brelaz_color.brelazColor;

test {
    _ = @import("greedy_color.zig");
    _ = @import("brelaz_color.zig");
}
