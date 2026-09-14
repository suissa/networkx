//! Eigenvector centrality algorithm.
//!
//! Eigenvector centrality computes the centrality for a node based on the centrality of its neighbors.
//! It uses the power iteration method to find the principal eigenvector of the adjacency matrix.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

/// Calculate eigenvector centrality for all nodes in the graph.
/// 
/// Eigenvector centrality is defined as the principal eigenvector of the adjacency matrix.
/// A node has high eigenvector centrality if it is connected to other nodes with high centrality.
/// 
/// Parameters:
/// - graph: The graph to analyze
/// - max_iter: Maximum number of iterations (default: 100)
/// - tolerance: Convergence tolerance (default: 1e-6)
/// 
/// Returns a HashMap mapping each node to its eigenvector centrality value.
pub fn eigenvectorCentrality(comptime NodeType: type) fn (
    graph: anytype,
    max_iter: usize,
    tolerance: f64,
) !AutoHashMap(NodeType, f64) {
    const allocator = graph.allocator;
    
    var centrality = AutoHashMap(NodeType, f64).init(allocator);
    errdefer centrality.deinit();
    
    const n = graph._node.count();
    if (n == 0) return centrality;
    
    // Initialize all nodes with equal centrality
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        try centrality.put(node.*, 1.0 / @as(f64, @floatFromInt(n)));
    }
    
    var prev_centrality = AutoHashMap(NodeType, f64).init(allocator);
    defer prev_centrality.deinit();
    
    // Power iteration
    var iter: usize = 0;
    while (iter < max_iter) : (iter += 1) {
        // Save previous values
        prev_centrality.clearRetainingCapacity();
        var cent_it = centrality.iterator();
        while (cent_it.next()) |entry| {
            try prev_centrality.put(entry.key_ptr.*, entry.value_ptr.*);
        }
        
        // Compute new centrality values
        var sum_x: f64 = 0;
        node_it = graph._node.keyIterator();
        while (node_it.next()) |node_ptr| {
            const node = node_ptr.*;
            var x_new: f64 = 0;
            
            if (graph.neighbors(node)) |nbrs| {
                var nbr_it = nbrs.keyIterator();
                while (nbr_it.next()) |nbr_ptr| {
                    const nbr = nbr_ptr.*;
                    const x_nbr = prev_centrality.get(nbr) orelse continue;
                    x_new += x_nbr;
                }
            }
            
            try centrality.put(node, x_new);
            sum_x += x_new * x_new;
        }
        
        // Normalize
        const norm = @sqrt(sum_x);
        if (norm > 0) {
            var result_it = centrality.valueIterator();
            while (result_it.next()) |value| {
                value.* /= norm;
            }
        }
        
        // Check convergence
        var diff: f64 = 0;
        var check_it = centrality.iterator();
        while (check_it.next()) |entry| {
            const old_val = prev_centrality.get(entry.key_ptr.*) orelse continue;
            const d = entry.value_ptr.* - old_val;
            diff += d * d;
        }
        diff = @sqrt(diff);
        
        if (diff < tolerance) break;
    }
    
    return centrality;
}

test "eigenvectorCentrality basic" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create a star graph: center node 0 connected to 1, 2, 3, 4
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, null },
        .{ 0, 2, null },
        .{ 0, 3, null },
        .{ 0, 4, null },
    });
    
    const centrality = try eigenvectorCentrality(i32)(&graph, 100, 1e-6);
    defer centrality.deinit();
    
    // Center node should have highest eigenvector centrality
    try std.testing.expect(centrality.get(0).? > centrality.get(1).?);
    try std.testing.expect(centrality.get(0).? > centrality.get(2).?);
    try std.testing.expect(centrality.get(0).? > centrality.get(3).?);
    try std.testing.expect(centrality.get(0).? > centrality.get(4).?);
}

test "eigenvectorCentrality path" {
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
    
    const centrality = try eigenvectorCentrality(i32)(&graph, 100, 1e-6);
    defer centrality.deinit();
    
    // Middle node (2) should have highest eigenvector centrality
    try std.testing.expect(centrality.get(2).? > centrality.get(0).?);
    try std.testing.expect(centrality.get(2).? > centrality.get(4).?);
}
