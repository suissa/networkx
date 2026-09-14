//! Shortest path algorithms - generic interface.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

/// Check if a path exists between source and target
pub fn hasPath(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    target: NodeType,
) !bool {
    _ = try shortestPath(NodeType)(graph, source, target, null, "dijkstra");
    return true;
} catch |_| false;

/// Compute shortest path between source and target
pub fn shortestPath(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    target: NodeType,
    weight: ?[]const u8,
    method: []const u8,
) !ArrayList(NodeType) {
    const allocator = graph.allocator;
    
    // For unweighted graphs or when weight is null, use BFS
    if (weight == null) {
        return try @import("unweighted.zig").singleSourceShortestPath(NodeType)(graph, source, target);
    }
    
    // Use Dijkstra by default
    if (std.mem.eql(u8, method, "dijkstra")) {
        return try @import("dijkstra.zig").dijkstraPath(NodeType)(graph, source, target, weight);
    }
    
    // Use Bellman-Ford for negative weights
    if (std.mem.eql(u8, method, "bellman-ford")) {
        return try @import("bellman_ford.zig").bellmanFordPath(NodeType)(graph, source, target, weight);
    }
    
    return error.UnsupportedMethod;
}

/// Compute shortest path length between source and target
pub fn shortestPathLength(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    target: NodeType,
    weight: ?[]const u8,
) !f64 {
    const path = try shortestPath(NodeType)(graph, source, target, weight, "dijkstra");
    defer path.deinit();
    
    if (path.items.len == 0) {
        return error.NoPath;
    }
    
    // Calculate total weight
    var total: f64 = 0;
    var i: usize = 0;
    while (i < path.items.len - 1) : (i += 1) {
        const u = path.items[i];
        const v = path.items[i + 1];
        
        if (graph.neighbors(u)) |nbrs| {
            if (nbrs.get(v)) |edge| {
                total += edge.weight;
            }
        }
    }
    
    return total;
}

/// Compute average shortest path length for all pairs of nodes
pub fn averageShortestPathLength(comptime NodeType: type) fn (
    graph: anytype,
) !f64 {
    const allocator = graph.allocator;
    
    var total_distance: f64 = 0;
    var pair_count: usize = 0;
    
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |source_node| {
        var target_it = graph._node.keyIterator();
        while (target_it.next()) |target_node| {
            if (source_node.* != target_node.*) {
                const path = try shortestPath(NodeType)(graph, source_node.*, target_node.*, null, "dijkstra");
                defer path.deinit();
                
                if (path.items.len > 0) {
                    total_distance += @as(f64, @floatFromInt(path.items.len - 1));
                    pair_count += 1;
                }
            }
        }
    }
    
    if (pair_count == 0) {
        return 0;
    }
    
    return total_distance / @as(f64, @floatFromInt(pair_count));
}

test "hasPath basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
    });
    
    try std.testing.expect(try hasPath(i32)(&graph, 0, 2));
    try std.testing.expect(!try hasPath(i32)(&graph, 0, 5)); // Non-existent node
}

test "shortestPath basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
        .{ 0, 2, 5.0 }, // Longer direct path
    });
    
    const path = try shortestPath(i32)(&graph, 0, 2, null, "dijkstra");
    defer path.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), path.items.len);
    try std.testing.expectEqual(@as(i32, 0), path.items[0]);
    try std.testing.expectEqual(@as(i32, 2), path.items[2]);
}
