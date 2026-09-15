//! Prim's algorithm for finding Minimum Spanning Tree (MST).
//! Uses a priority queue for efficient edge selection.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Graph = @import("../../classes/graph.zig").Graph;

/// Edge representation with weight
pub const WeightedEdge = struct {
    u: usize,
    v: usize,
    weight: f64,
};

/// Result of MST computation
pub const MstResult = struct {
    edges: []WeightedEdge,
    total_weight: f64,
    allocator: Allocator,

    pub fn deinit(self: *MstResult) void {
        self.allocator.free(self.edges);
    }
};

/// Priority queue entry for Prim's algorithm
const QueueEntry = struct {
    weight: f64,
    node: usize,
    parent: ?usize,
    
    pub fn lessThan(_: void, lhs: QueueEntry, rhs: QueueEntry) bool {
        return lhs.weight < rhs.weight;
    }
};

/// Find Minimum Spanning Tree using Prim's algorithm.
/// Returns a list of edges in the MST and the total weight.
/// 
/// Time complexity: O(E log V) where E is the number of edges and V is the number of vertices
/// Space complexity: O(V)
pub fn primMst(allocator: Allocator, graph: *Graph) !MstResult {
    const num_nodes = graph.numNodes();
    
    if (num_nodes == 0) {
        return MstResult{
            .edges = try allocator.alloc(WeightedEdge, 0),
            .total_weight = 0.0,
            .allocator = allocator,
        };
    }
    
    // Track visited nodes
    var visited = try allocator.alloc(bool, num_nodes);
    defer allocator.free(visited);
    @memset(visited, false);
    
    // Track minimum weight to connect each node
    var min_weight = try allocator.alloc(f64, num_nodes);
    defer allocator.free(min_weight);
    for (min_weight) |*w| {
        w.* = std.math.inf(f64);
    }
    
    // Track parent of each node in MST
    var parent = try allocator.alloc(?usize, num_nodes);
    defer allocator.free(parent);
    for (parent) |*p| {
        p.* = null;
    }
    
    // Priority queue for selecting minimum weight edge
    var pq = std.PriorityQueue(QueueEntry, void, QueueEntry.lessThan).init(allocator, {});
    defer pq.deinit();
    
    // Start from node 0 (or first available node)
    var start_node: ?usize = null;
    var it = graph.nodes.iterator();
    if (it.next()) |entry| {
        start_node = entry.key_ptr.*;
    }
    
    if (start_node == null) {
        return MstResult{
            .edges = try allocator.alloc(WeightedEdge, 0),
            .total_weight = 0.0,
            .allocator = allocator,
        };
    }
    
    const start = start_node.?;
    min_weight[start] = 0.0;
    try pq.add(QueueEntry{
        .weight = 0.0,
        .node = start,
        .parent = null,
    });
    
    var mst_edges = std.ArrayList(WeightedEdge).init(allocator);
    errdefer mst_edges.deinit();
    
    var total_weight: f64 = 0.0;
    var nodes_in_mst: usize = 0;
    
    while (pq.count() > 0) {
        const entry = pq.remove();
        const u = entry.node;
        
        // Skip if already visited
        if (visited[u]) continue;
        
        visited[u] = true;
        nodes_in_mst += 1;
        
        // Add edge to MST (except for starting node)
        if (entry.parent != null) {
            try mst_edges.append(WeightedEdge{
                .u = entry.parent.?,
                .v = u,
                .weight = entry.weight,
            });
            total_weight += entry.weight;
        }
        
        // Explore neighbors
        const neighbors = graph.nodes.get(u) orelse continue;
        var neighbor_it = neighbors.iterator();
        while (neighbor_it.next()) |neighbor_entry| {
            const v = neighbor_entry.key_ptr.*;
            const weight = neighbor_entry.value_ptr.*;
            
            if (!visited[v] and weight < min_weight[v]) {
                min_weight[v] = weight;
                parent[v] = u;
                try pq.add(QueueEntry{
                    .weight = weight,
                    .node = v,
                    .parent = u,
                });
            }
        }
    }
    
    return MstResult{
        .edges = try mst_edges.toOwnedSlice(),
        .total_weight = total_weight,
        .allocator = allocator,
    };
}

test "Prim MST - simple triangle" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    // Create a triangle: 0-1 (weight 1), 1-2 (weight 2), 0-2 (weight 3)
    try graph.addEdge(0, 1, 1.0);
    try graph.addEdge(1, 2, 2.0);
    try graph.addEdge(0, 2, 3.0);
    
    var result = try primMst(allocator, &graph);
    defer result.deinit();
    
    // MST should have 2 edges (for 3 nodes)
    try std.testing.expectEqual(@as(usize, 2), result.edges.len);
    
    // Total weight should be 1 + 2 = 3 (excluding the heaviest edge)
    try std.testing.expectEqual(@as(f64, 3.0), result.total_weight);
}

test "Prim MST - square graph" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    // Create a square: 0-1-2-3-0 with diagonal 0-2
    // Weights: 0-1: 1, 1-2: 2, 2-3: 3, 3-0: 4, 0-2: 5
    try graph.addEdge(0, 1, 1.0);
    try graph.addEdge(1, 2, 2.0);
    try graph.addEdge(2, 3, 3.0);
    try graph.addEdge(3, 0, 4.0);
    try graph.addEdge(0, 2, 5.0);
    
    var result = try primMst(allocator, &graph);
    defer result.deinit();
    
    // MST should have 3 edges (for 4 nodes)
    try std.testing.expectEqual(@as(usize, 3), result.edges.len);
    
    // Total weight should be 1 + 2 + 3 = 6
    try std.testing.expectEqual(@as(f64, 6.0), result.total_weight);
}

test "Prim MST - single node" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    try graph.addNode(0);
    
    var result = try primMst(allocator, &graph);
    defer result.deinit();
    
    try std.testing.expectEqual(@as(usize, 0), result.edges.len);
    try std.testing.expectEqual(@as(f64, 0.0), result.total_weight);
}

test "Prim MST - empty graph" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    var result = try primMst(allocator, &graph);
    defer result.deinit();
    
    try std.testing.expectEqual(@as(usize, 0), result.edges.len);
    try std.testing.expectEqual(@as(f64, 0.0), result.total_weight);
}

test "Prim MST - linear graph" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    // Create a line: 0-1-2-3-4
    try graph.addEdge(0, 1, 1.0);
    try graph.addEdge(1, 2, 2.0);
    try graph.addEdge(2, 3, 3.0);
    try graph.addEdge(3, 4, 4.0);
    
    var result = try primMst(allocator, &graph);
    defer result.deinit();
    
    // MST should have 4 edges (for 5 nodes)
    try std.testing.expectEqual(@as(usize, 4), result.edges.len);
    
    // Total weight should be 1 + 2 + 3 + 4 = 10
    try std.testing.expectEqual(@as(f64, 10.0), result.total_weight);
}
