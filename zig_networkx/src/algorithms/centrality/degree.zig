//! Degree centrality algorithms.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

/// Compute degree centrality for nodes in an undirected graph.
/// 
/// The degree centrality for a node v is the fraction of nodes it
/// is connected to.
/// 
/// Parameters:
/// - graph: NetworkX graph
/// 
/// Returns:
/// - Dictionary of nodes with degree centrality as the value.
pub fn degreeCentrality(comptime NodeType: type) fn (
    graph: anytype,
) !AutoHashMap(NodeType, f64) {
    const allocator = graph.allocator;
    
    var centrality = AutoHashMap(NodeType, f64).init(allocator);
    errdefer centrality.deinit();
    
    const n = graph.numberOfNodes();
    
    if (n <= 1) {
        // For single node or empty graph, return 1.0 for all nodes
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try centrality.put(node.*, 1.0);
        }
        return centrality;
    }
    
    const s = 1.0 / @as(f64, @floatFromInt(n - 1));
    
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        const deg = graph.degree(node.*) orelse 0;
        try centrality.put(node.*, @as(f64, @floatFromInt(deg)) * s);
    }
    
    return centrality;
}

/// Compute in-degree centrality for nodes in a directed graph.
pub fn inDegreeCentrality(comptime NodeType: type) fn (
    graph: anytype,
) !AutoHashMap(NodeType, f64) {
    const allocator = graph.allocator;
    
    var centrality = AutoHashMap(NodeType, f64).init(allocator);
    errdefer centrality.deinit();
    
    const n = graph.numberOfNodes();
    
    if (n <= 1) {
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try centrality.put(node.*, 1.0);
        }
        return centrality;
    }
    
    const s = 1.0 / @as(f64, @floatFromInt(n - 1));
    
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        const in_deg = graph.inDegree(node.*) orelse 0;
        try centrality.put(node.*, @as(f64, @floatFromInt(in_deg)) * s);
    }
    
    return centrality;
}

/// Compute out-degree centrality for nodes in a directed graph.
pub fn outDegreeCentrality(comptime NodeType: type) fn (
    graph: anytype,
) !AutoHashMap(NodeType, f64) {
    const allocator = graph.allocator;
    
    var centrality = AutoHashMap(NodeType, f64).init(allocator);
    errdefer centrality.deinit();
    
    const n = graph.numberOfNodes();
    
    if (n <= 1) {
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try centrality.put(node.*, 1.0);
        }
        return centrality;
    }
    
    const s = 1.0 / @as(f64, @floatFromInt(n - 1));
    
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        const out_deg = graph.outDegree(node.*) orelse 0;
        try centrality.put(node.*, @as(f64, @floatFromInt(out_deg)) * s);
    }
    
    return centrality;
}

test "degreeCentrality basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create a star graph: node 0 connected to 1, 2, 3
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 0, 2, 1.0 },
        .{ 0, 3, 1.0 },
    });
    
    const centrality = try degreeCentrality(i32)(&graph);
    defer centrality.deinit();
    
    // Node 0 has degree 3, normalized by (n-1) = 3, so centrality = 1.0
    try std.testing.expectEqual(@as(f64, 1.0), centrality.get(0).?);
    
    // Nodes 1, 2, 3 have degree 1, normalized by 3, so centrality = 0.333...
    const expected_leaf = 1.0 / 3.0;
    try std.testing.expect(std.math.approxEqAbs(f64, expected_leaf, centrality.get(1).?, 1e-10));
    try std.testing.expect(std.math.approxEqAbs(f64, expected_leaf, centrality.get(2).?, 1e-10));
    try std.testing.expect(std.math.approxEqAbs(f64, expected_leaf, centrality.get(3).?, 1e-10));
}

test "degreeCentrality path graph" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create a path: 0 - 1 - 2 - 3
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
        .{ 2, 3, 1.0 },
    });
    
    const centrality = try degreeCentrality(i32)(&graph);
    defer centrality.deinit();
    
    // End nodes (0, 3) have degree 1, middle nodes (1, 2) have degree 2
    const n_minus_1 = 3.0;
    try std.testing.expect(std.math.approxEqAbs(f64, 1.0 / n_minus_1, centrality.get(0).?, 1e-10));
    try std.testing.expect(std.math.approxEqAbs(f64, 2.0 / n_minus_1, centrality.get(1).?, 1e-10));
    try std.testing.expect(std.math.approxEqAbs(f64, 2.0 / n_minus_1, centrality.get(2).?, 1e-10));
    try std.testing.expect(std.math.approxEqAbs(f64, 1.0 / n_minus_1, centrality.get(3).?, 1e-10));
}
