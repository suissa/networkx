//! Bellman-Ford algorithm for shortest paths with negative edge weights.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

/// Find shortest paths from source using Bellman-Ford algorithm.
/// Supports negative edge weights and detects negative cycles.
/// 
/// Returns a struct with:
/// - distances: HashMap mapping nodes to their shortest distance from source
/// - predecessors: HashMap mapping nodes to their predecessor in the shortest path
pub fn bellmanFord(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    weight_attr: ?[]const u8,
) !struct { distances: AutoHashMap(NodeType, f64), predecessors: AutoHashMap(NodeType, NodeType) } {
    const allocator = graph.allocator;
    
    var distances = AutoHashMap(NodeType, f64).init(allocator);
    errdefer distances.deinit();
    
    var predecessors = AutoHashMap(NodeType, NodeType).init(allocator);
    errdefer predecessors.deinit();
    
    // Initialize distances
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        try distances.put(node.*, std.math.inf(f64));
        try predecessors.put(node.*, null);
    }
    try distances.put(source, 0);
    
    // Get all edges
    var edges = ArrayList(struct { from: NodeType, to: NodeType, weight: f64 }).init(allocator);
    defer edges.deinit();
    
    var edge_it = graph.edgesIterator();
    while (edge_it.next()) |edge| {
        try edges.append(.{
            .from = edge.from,
            .to = edge.to,
            .weight = edge.weight,
        });
    }
    
    // Relax edges |V| - 1 times
    const node_count = graph._node.count();
    var i: usize = 0;
    while (i < node_count - 1) : (i += 1) {
        var updated = false;
        for (edges.items) |edge| {
            const dist_u = distances.get(edge.from) orelse continue;
            const dist_v = distances.get(edge.to) orelse std.math.inf(f64);
            
            if (dist_u + edge.weight < dist_v) {
                try distances.put(edge.to, dist_u + edge.weight);
                try predecessors.put(edge.to, edge.from);
                updated = true;
            }
        }
        if (!updated) break;
    }
    
    // Check for negative cycles
    for (edges.items) |edge| {
        const dist_u = distances.get(edge.from) orelse continue;
        const dist_v = distances.get(edge.to) orelse std.math.inf(f64);
        
        if (dist_u + edge.weight < dist_v) {
            return error.NegativeCycle;
        }
    }
    
    return .{ .distances = distances, .predecessors = predecessors };
}

/// Find shortest path from source to target using Bellman-Ford algorithm.
pub fn bellmanFordPath(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    target: NodeType,
    weight_attr: ?[]const u8,
) !ArrayList(NodeType) {
    const allocator = graph.allocator;
    
    const result = try bellmanFord(NodeType)(graph, source, weight_attr);
    defer result.distances.deinit();
    defer result.predecessors.deinit();
    
    if (!result.distances.contains(target) or result.distances.get(target).? == std.math.inf(f64)) {
        return error.NoPath;
    }
    
    // Reconstruct path
    var path = ArrayList(NodeType).init(allocator);
    errdefer path.deinit();
    
    var current = target;
    while (true) {
        try path.insert(0, current);
        if (current == source) break;
        current = result.predecessors.get(current) orelse return error.NoPath;
    }
    
    return path;
}

test "bellmanFord basic" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 4.0 },
        .{ 0, 2, 2.0 },
        .{ 1, 2, 1.0 },
        .{ 2, 3, 3.0 },
    });
    
    const result = try bellmanFord(i32)(&graph, 0, null);
    defer result.distances.deinit();
    defer result.predecessors.deinit();
    
    try std.testing.expectEqual(@as(f64, 0), result.distances.get(0).?);
    try std.testing.expectEqual(@as(f64, 4), result.distances.get(1).?);
    try std.testing.expectEqual(@as(f64, 2), result.distances.get(2).?);
    try std.testing.expectEqual(@as(f64, 5), result.distances.get(3).?);
}

test "bellmanFord negative edge" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 4.0 },
        .{ 0, 2, 2.0 },
        .{ 1, 2, -3.0 },
        .{ 2, 3, 3.0 },
    });
    
    const result = try bellmanFord(i32)(&graph, 0, null);
    defer result.distances.deinit();
    defer result.predecessors.deinit();
    
    try std.testing.expectEqual(@as(f64, 0), result.distances.get(0).?);
    try std.testing.expectEqual(@as(f64, 4), result.distances.get(1).?);
    try std.testing.expectEqual(@as(f64, 1), result.distances.get(2).?);
    try std.testing.expectEqual(@as(f64, 4), result.distances.get(3).?);
}

test "bellmanFord negative cycle detection" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, -2.0 },
        .{ 2, 0, 1.0 },
    });
    
    try std.testing.expectError(error.NegativeCycle, bellmanFord(i32)(&graph, 0, null));
}
