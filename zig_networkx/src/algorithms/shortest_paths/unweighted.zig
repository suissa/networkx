//! Unweighted shortest path algorithms using BFS.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Queue = std.fifo.LinearFifo;

/// Find shortest path from source to target in unweighted graph
pub fn singleSourceShortestPath(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    target: ?NodeType,
) !ArrayList(NodeType) {
    const allocator = graph.allocator;
    
    var predecessors = AutoHashMap(NodeType, NodeType).init(allocator);
    defer predecessors.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(source, {});
    
    var queue = Queue(NodeType, .Dynamic).init(allocator);
    defer queue.deinit();
    try queue.writeItem(source);
    
    var found = false;
    
    while (queue.readItem()) |node| {
        if (target) |t| {
            if (node == t) {
                found = true;
                break;
            }
        }
        
        if (graph.neighbors(node)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(child.*);
                    try predecessors.put(child.*, node);
                }
            }
        }
    }
    
    // Reconstruct path
    var path = ArrayList(NodeType).init(allocator);
    errdefer path.deinit();
    
    const end_node = target orelse {
        // If no target specified, return empty path
        return path;
    };
    
    if (!seen.contains(end_node)) {
        return error.NoPath;
    }
    
    var current = end_node;
    while (true) {
        try path.insert(0, current);
        if (current == source) break;
        current = predecessors.get(current) orelse return error.NoPath;
    }
    
    return path;
}

/// Get shortest path lengths from source to all reachable nodes (unweighted)
pub fn singleSourceShortestPathLength(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
) !AutoHashMap(NodeType, usize) {
    const allocator = graph.allocator;
    
    var distances = AutoHashMap(NodeType, usize).init(allocator);
    errdefer distances.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(source, {});
    try distances.put(source, 0);
    
    var queue = Queue(struct { NodeType, usize }, .Dynamic).init(allocator);
    defer queue.deinit();
    try queue.writeItem(.{ source, 0 });
    
    while (queue.readItem()) |item| {
        const node = item[0];
        const dist = item[1];
        
        if (graph.neighbors(node)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(.{ child.*, dist + 1 });
                    try distances.put(child.*, dist + 1);
                }
            }
        }
    }
    
    return distances;
}

/// Get all pairs shortest paths (unweighted)
pub fn allPairsShortestPath(comptime NodeType: type) fn (
    graph: anytype,
) !AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(NodeType))) {
    const allocator = graph.allocator;
    
    var result = AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(NodeType))).init(allocator);
    errdefer {
        var it = result.valueIterator();
        while (it.next()) |inner_map| {
            var inner_it = inner_map.*.valueIterator();
            while (inner_it.next()) |path| {
                path.*.deinit();
            }
            inner_map.*.deinit();
        }
        result.deinit();
    }
    
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |source| {
        var inner_map = AutoHashMap(NodeType, ArrayList(NodeType)).init(allocator);
        errdefer {
            var inner_it = inner_map.valueIterator();
            while (inner_it.next()) |path| {
                path.*.deinit();
            }
            inner_map.deinit();
        }
        
        var target_it = graph._node.keyIterator();
        while (target_it.next()) |target| {
            const path = try singleSourceShortestPath(NodeType)(graph, source.*, target.*, null);
            try inner_map.put(target.*, path);
        }
        
        try result.put(source.*, inner_map);
    }
    
    return result;
}

test "singleSourceShortestPath basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
        .{ 2, 3, 1.0 },
    });
    
    const path = try singleSourceShortestPath(i32)(&graph, 0, 3);
    defer path.deinit();
    
    try std.testing.expectEqual(@as(usize, 4), path.items.len);
    try std.testing.expectEqual(@as(i32, 0), path.items[0]);
    try std.testing.expectEqual(@as(i32, 3), path.items[3]);
}

test "singleSourceShortestPathLength basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
        .{ 0, 2, 1.0 },
    });
    
    const distances = try singleSourceShortestPathLength(i32)(&graph, 0);
    defer distances.deinit();
    
    try std.testing.expectEqual(@as(usize, 0), distances.get(0).?);
    try std.testing.expectEqual(@as(usize, 1), distances.get(1).?);
    try std.testing.expectEqual(@as(usize, 1), distances.get(2).?);
}
