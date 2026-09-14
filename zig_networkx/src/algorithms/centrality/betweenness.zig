//! Betweenness centrality - TO BE IMPLEMENTED

const std = @import("std");

pub fn betweennessCentrality(comptime NodeType: type) fn (
    graph: anytype,
    normalized: bool,
    endpoints: bool,
) !std.AutoHashMap(NodeType, f64) {
    _ = graph;
    _ = normalized;
    _ = endpoints;
    @compileError("betweennessCentrality not yet implemented - see IMPLEMENTATION_PLAN.md Section 4.2");
}
