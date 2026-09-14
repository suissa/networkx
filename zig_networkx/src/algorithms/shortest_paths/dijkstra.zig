//! Dijkstra's algorithm for shortest paths.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const PriorityQueue = std.PriorityQueue;

/// Find shortest path from source to target using Dijkstra's algorithm
pub fn dijkstraPath(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    target: NodeType,
    weight_attr: ?[]const u8,
) !ArrayList(NodeType) {
    const allocator = graph.allocator;
    
    var distances = AutoHashMap(NodeType, f64).init(allocator);
    defer distances.deinit();
    
    var predecessors = AutoHashMap(NodeType, NodeType).init(allocator);
    defer predecessors.deinit();
    
    // Priority queue: (distance, node)
    const QueueItem = struct {
        node: NodeType,
        distance: f64,
        
        pub fn lessThan(_: void, a: QueueItem, b: QueueItem) bool {
            return a.distance > b.distance; // Min-heap
        }
    };
    
    var pq = PriorityQueue(QueueItem, void, QueueItem.lessThan).init(allocator, {});
    defer pq.deinit();
    
    // Initialize distances
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        try distances.put(node.*, std.math.inf(f64));
    }
    try distances.put(source, 0);
    
    try pq.add(.{ .node = source, .distance = 0 });
    
    while (pq.removeOrNull()) |item| {
        const u = item.node;
        const dist_u = item.distance;
        
        if (dist_u > distances.get(u).?) continue;
        if (u == target) break;
        
        if (graph.neighbors(u)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |v| {
                const edge_weight = nbrs.get(v.*).?.weight;
                const alt = dist_u + edge_weight;
                
                if (alt < distances.get(v.*).?) {
                    try distances.put(v.*, alt);
                    try predecessors.put(v.*, u);
                    try pq.add(.{ .node = v.*, .distance = alt });
                }
            }
        }
    }
    
    // Reconstruct path
    var path = ArrayList(NodeType).init(allocator);
    errdefer path.deinit();
    
    if (!distances.contains(target) or distances.get(target).? == std.math.inf(f64)) {
        return error.NoPath;
    }
    
    var current = target;
    while (true) {
        try path.insert(0, current);
        if (current == source) break;
        current = predecessors.get(current) orelse return error.NoPath;
    }
    
    return path;
}

/// Get shortest path lengths from source to all reachable nodes
pub fn dijkstraPathLength(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    weight_attr: ?[]const u8,
) !AutoHashMap(NodeType, f64) {
    const allocator = graph.allocator;
    
    var distances = AutoHashMap(NodeType, f64).init(allocator);
    errdefer distances.deinit();
    
    const QueueItem = struct {
        node: NodeType,
        distance: f64,
        
        pub fn lessThan(_: void, a: QueueItem, b: QueueItem) bool {
            return a.distance > b.distance;
        }
    };
    
    var pq = PriorityQueue(QueueItem, void, QueueItem.lessThan).init(allocator, {});
    defer pq.deinit();
    
    // Initialize
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        try distances.put(node.*, std.math.inf(f64));
    }
    try distances.put(source, 0);
    try pq.add(.{ .node = source, .distance = 0 });
    
    while (pq.removeOrNull()) |item| {
        const u = item.node;
        const dist_u = item.distance;
        
        if (dist_u > distances.get(u).?) continue;
        
        if (graph.neighbors(u)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |v| {
                const edge_weight = nbrs.get(v.*).?.weight;
                const alt = dist_u + edge_weight;
                
                if (alt < distances.get(v.*).?) {
                    try distances.put(v.*, alt);
                    try pq.add(.{ .node = v.*, .distance = alt });
                }
            }
        }
    }
    
    return distances;
}

test "dijkstraPath basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 2.0 },
        .{ 0, 2, 5.0 },
    });
    
    const path = try dijkstraPath(i32)(&graph, 0, 2, null);
    defer path.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), path.items.len);
    try std.testing.expectEqual(@as(i32, 0), path.items[0]);
    try std.testing.expectEqual(@as(i32, 1), path.items[1]);
    try std.testing.expectEqual(@as(i32, 2), path.items[2]);
}

test "dijkstraPathLength basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 2.0 },
        .{ 0, 2, 5.0 },
    });
    
    const distances = try dijkstraPathLength(i32)(&graph, 0, null);
    defer distances.deinit();
    
    try std.testing.expectEqual(@as(f64, 0), distances.get(0).?);
    try std.testing.expectEqual(@as(f64, 1), distances.get(1).?);
    try std.testing.expectEqual(@as(f64, 3), distances.get(2).?);
}
