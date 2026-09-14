//! Closeness centrality - TO BE IMPLEMENTED

const std = @import("std");

pub fn closenessCentrality(comptime NodeType: type) fn (
    graph: anytype,
) !std.AutoHashMap(NodeType, f64) {
    _ = graph;
    @compileError("closenessCentrality not yet implemented - see IMPLEMENTATION_PLAN.md Section 4.3");
}
