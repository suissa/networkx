//! Eigenvector centrality - TO BE IMPLEMENTED

const std = @import("std");

pub fn eigenvectorCentrality(comptime NodeType: type) fn (
    graph: anytype,
    max_iter: usize,
    tolerance: f64,
) !std.AutoHashMap(NodeType, f64) {
    _ = graph;
    _ = max_iter;
    _ = tolerance;
    @compileError("eigenvectorCentrality not yet implemented - see IMPLEMENTATION_PLAN.md Section 4.4");
}
