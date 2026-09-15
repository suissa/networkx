//! Closeness centrality algorithm.
//!
//! Closeness centrality of a node v is the reciprocal of the average shortest path distance
//! from v to all other nodes in the graph.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

/// Calculate closeness centrality for all nodes in the graph.
/// 
/// Closeness centrality is defined as:
/// C(v) = (n - 1) / sum(d(v, u) for all u != v)
/// 
/// where n is the number of nodes and d(v, u) is the shortest path distance from v to u.
/// 
/// Parameters:
/// - graph: The graph to analyze
/// - wf_improved: If true, use Wasserman-Vis improvement for disconnected graphs
/// 
/// Returns a HashMap mapping each node to its closeness centrality value.
pub fn closenessCentrality(comptime NodeType: type) fn (
    graph: anytype,
    wf_improved: bool,
) !AutoHashMap(NodeType, f64) {
    const allocator = graph.allocator;
    
    var closeness = AutoHashMap(NodeType, f64).init(allocator);
    errdefer closeness.deinit();
    
    const n = graph._node.count();
    if (n < 2) {
        // Single node or empty graph
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try closeness.put(node.*, 0.0);
        }
        return closeness;
    }
    
    // For each source node, perform BFS to find distances to all other nodes
    var source_it = graph._node.keyIterator();
    while (source_it.next()) |source_ptr| {
        const source = source_ptr.*;
        
        // BFS to find distances
        var distances = AutoHashMap(NodeType, usize).init(allocator);
        defer distances.deinit();
        
        // Initialize all distances to infinity
        var init_it = graph._node.keyIterator();
        while (init_it.next()) |node| {
            try distances.put(node.*, std.math.maxInt(usize));
        }
        try distances.put(source, 0);
        
        // BFS queue
        var queue = ArrayList(NodeType).init(allocator);
        defer queue.deinit();
        
        try queue.append(source);
        
        var head: usize = 0;
        while (head < queue.items.len) {
            const v = queue.items[head];
            head += 1;
            
            const dist_v = distances.get(v).?;
            
            if (graph.neighbors(v)) |nbrs| {
                var nbr_it = nbrs.keyIterator();
                while (nbr_it.next()) |w_ptr| {
                    const w = w_ptr.*;
                    const dist_w = distances.get(w).?;
                    
                    if (dist_w == std.math.maxInt(usize)) {
                        try distances.put(w, dist_v + 1);
                        try queue.append(w);
                    }
                }
            }
        }
        
        // Sum distances to reachable nodes
        var total_dist: f64 = 0;
        var reachable_count: usize = 0;
        
        var dist_it = distances.iterator();
        while (dist_it.next()) |entry| {
            if (entry.key_ptr.* != source and entry.value_ptr.* != std.math.maxInt(usize)) {
                total_dist += @as(f64, @floatFromInt(entry.value_ptr.*));
                reachable_count += 1;
            }
        }
        
        // Calculate closeness
        if (total_dist > 0) {
            var c = @as(f64, @floatFromInt(reachable_count)) / total_dist;
            
            // Apply Wasserman-Vis improvement for disconnected graphs
            if (wf_improved and reachable_count < n - 1) {
                const fraction = @as(f64, @floatFromInt(reachable_count)) / @as(f64, @floatFromInt(n - 1));
                c *= fraction;
            }
            
            try closeness.put(source, c);
        } else {
            try closeness.put(source, 0.0);
        }
    }
    
    return closeness;
}

test "closenessCentrality basic" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create a complete graph K4
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, null },
        .{ 0, 2, null },
        .{ 0, 3, null },
        .{ 1, 2, null },
        .{ 1, 3, null },
        .{ 2, 3, null },
    });
    
    const centrality = try closenessCentrality(i32)(&graph, false);
    defer centrality.deinit();
    
    // In a complete graph, all nodes have the same closeness
    const expected = 1.0; // All distances are 1, so closeness = 3/3 = 1
    try std.testing.expectEqual(@as(f64, 1.0), centrality.get(0).?);
    try std.testing.expectEqual(@as(f64, 1.0), centrality.get(1).?);
    try std.testing.expectEqual(@as(f64, 1.0), centrality.get(2).?);
    try std.testing.expectEqual(@as(f64, 1.0), centrality.get(3).?);
}

test "closenessCentrality path" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create a path: 0 - 1 - 2 - 3 - 4
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, null },
        .{ 1, 2, null },
        .{ 2, 3, null },
        .{ 3, 4, null },
    });
    
    const centrality = try closenessCentrality(i32)(&graph, false);
    defer centrality.deinit();
    
    // Middle node (2) should have highest closeness
    try std.testing.expect(centrality.get(2).? > centrality.get(0).?);
    try std.testing.expect(centrality.get(2).? > centrality.get(4).?);
}
