//! Minimum Spanning Tree algorithms module.
//! 
//! This module provides implementations of classic MST algorithms:
//! - Kruskal's algorithm (using Union-Find)
//! - Prim's algorithm (using priority queue)

const std = @import("std");

pub const union_find = @import("union_find.zig");
pub const kruskal = @import("kruskal.zig");
pub const prim = @import("prim.zig");

// Re-export commonly used types and functions
pub const UnionFind = union_find.UnionFind;
pub const WeightedEdge = kruskal.WeightedEdge;
pub const MstResult = kruskal.MstResult;
pub const kruskalMst = kruskal.kruskalMst;
pub const kruskalMsf = kruskal.kruskalMsf;
pub const primMst = prim.primMst;

test {
    // Run all tests in this module
    _ = @import("union_find.zig");
    _ = @import("kruskal.zig");
    _ = @import("prim.zig");
}
