//! Betweenness centrality algorithm.
//!
//! Betweenness centrality of a node v is the sum of the fraction of all-pairs shortest paths
//! that pass through v.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Queue = std.fifo.LinearFifo;

/// Calculate betweenness centrality for all nodes in the graph.
/// 
/// Parameters:
/// - graph: The graph to analyze
/// - normalized: If true, normalize the results by dividing by (n-1)(n-2)/2 for undirected graphs
///               or (n-1)(n-2) for directed graphs
/// - endpoints: If true, include endpoints in the shortest path counts
/// 
/// Returns a HashMap mapping each node to its betweenness centrality value.
pub fn betweennessCentrality(comptime NodeType: type) fn (
    graph: anytype,
    normalized: bool,
    endpoints: bool,
) !AutoHashMap(NodeType, f64) {
    const allocator = graph.allocator;
    
    var betweenness = AutoHashMap(NodeType, f64).init(allocator);
    errdefer betweenness.deinit();
    
    // Initialize betweenness values to 0
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |node| {
        try betweenness.put(node.*, 0.0);
    }
    
    const n = graph._node.count();
    if (n < 3) return betweenness;
    
    // For each source node, perform BFS to find shortest paths
    var source_it = graph._node.keyIterator();
    while (source_it.next()) |source_ptr| {
        const source = source_ptr.*;
        
        // BFS structures
        var distances = AutoHashMap(NodeType, isize).init(allocator);
        defer distances.deinit();
        
        var sigma = AutoHashMap(NodeType, f64).init(allocator);
        defer sigma.deinit();
        
        var predecessors = AutoHashMap(NodeType, ArrayList(NodeType)).init(allocator);
        defer {
            var pred_it = predecessors.valueIterator();
            while (pred_it.next()) |pred_list| {
                pred_list.*.deinit();
            }
            predecessors.deinit();
        }
        
        // Initialize
        var node_init_it = graph._node.keyIterator();
        while (node_init_it.next()) |node| {
            try distances.put(node.*, -1);
            try sigma.put(node.*, 0.0);
            try predecessors.put(node.*, ArrayList(NodeType).init(allocator));
        }
        
        try distances.put(source, 0);
        try sigma.put(source, 1.0);
        
        // BFS queue
        var queue = ArrayList(NodeType).init(allocator);
        defer queue.deinit();
        
        var stack = ArrayList(NodeType).init(allocator);
        defer stack.deinit();
        
        try queue.append(source);
        
        var head: usize = 0;
        while (head < queue.items.len) {
            const v = queue.items[head];
            head += 1;
            
            try stack.append(v);
            
            const dist_v = distances.get(v).?;
            
            if (graph.neighbors(v)) |nbrs| {
                var nbr_it = nbrs.keyIterator();
                while (nbr_it.next()) |w_ptr| {
                    const w = w_ptr.*;
                    
                    const dist_w = distances.get(w).?;
                    
                    // First time seeing this node
                    if (dist_w < 0) {
                        try distances.put(w, dist_v + 1);
                        try queue.append(w);
                    }
                    
                    // Shortest path to w via v
                    if (distances.get(w).? == dist_v + 1) {
                        const sigma_v = sigma.get(v).?;
                        const sigma_w = sigma.get(w).?;
                        try sigma.put(w, sigma_w + sigma_v);
                        
                        try predecessors.get(w).?.append(v);
                    }
                }
            }
        }
        
        // Accumulation phase
        var delta = AutoHashMap(NodeType, f64).init(allocator);
        defer delta.deinit();
        
        node_init_it = graph._node.keyIterator();
        while (node_init_it.next()) |node| {
            try delta.put(node.*, 0.0);
        }
        
        // Process nodes in reverse order of distance
        var i: isize = @intCast(stack.items.len);
        while (i > 0) {
            i -= 1;
            const w_idx: usize = @intCast(i);
            const w = stack.items[w_idx];
            
            const pred_list = predecessors.get(w).?;
            for (pred_list.items) |v| {
                const sigma_w = sigma.get(w).?;
                const sigma_v = sigma.get(v).?;
                const delta_w = delta.get(w).?;
                
                if (sigma_w > 0) {
                    const coeff = (sigma_v / sigma_w) * (1.0 + delta_w);
                    const delta_v = delta.get(v).?;
                    try delta.put(v, delta_v + coeff);
                }
            }
            
            // Add to betweenness
            if (w != source) {
                const delta_w = delta.get(w).?;
                const bw = betweenness.get(w).?;
                try betweenness.put(w, bw + delta_w);
            }
        }
    }
    
    // Normalization
    if (normalized) {
        const scale: f64 = if (graph.is_directed) 
            1.0 / (@as(f64, @floatFromInt(n - 1)) * @as(f64, @floatFromInt(n - 2)))
        else 
            2.0 / (@as(f64, @floatFromInt(n - 1)) * @as(f64, @floatFromInt(n - 2)));
        
        var result_it = betweenness.valueIterator();
        while (result_it.next()) |value| {
            value.* *= scale;
        }
    }
    
    return betweenness;
}

test "betweennessCentrality basic" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create a simple path: 0 - 1 - 2 - 3
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, null },
        .{ 1, 2, null },
        .{ 2, 3, null },
    });
    
    const centrality = try betweennessCentrality(i32)(&graph, false, false);
    defer centrality.deinit();
    
    // Node 1 and 2 should have higher betweenness as they are in the middle
    try std.testing.expect(centrality.get(0).? < centrality.get(1).?);
    try std.testing.expect(centrality.get(3).? < centrality.get(2).?);
}

test "betweennessCentrality normalized" {
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create a star graph: center node 0 connected to 1, 2, 3
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, null },
        .{ 0, 2, null },
        .{ 0, 3, null },
    });
    
    const centrality = try betweennessCentrality(i32)(&graph, true, false);
    defer centrality.deinit();
    
    // Center node should have highest betweenness
    try std.testing.expect(centrality.get(0).? > centrality.get(1).?);
    try std.testing.expect(centrality.get(0).? > centrality.get(2).?);
    try std.testing.expect(centrality.get(0).? > centrality.get(3).?);
}
