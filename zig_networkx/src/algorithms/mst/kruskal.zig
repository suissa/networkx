//! Kruskal's algorithm for finding Minimum Spanning Tree (MST).
//! Uses Union-Find data structure for efficient cycle detection.

const std = @import("std");
const Allocator = std.mem.Allocator;
const UnionFind = @import("union_find.zig").UnionFind;
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

/// Find Minimum Spanning Tree using Kruskal's algorithm.
/// Returns a list of edges in the MST and the total weight.
/// 
/// Time complexity: O(E log E) where E is the number of edges
/// Space complexity: O(V + E) where V is the number of vertices
pub fn kruskalMst(allocator: Allocator, graph: *Graph) !MstResult {
    const num_nodes = graph.numNodes();
    
    if (num_nodes == 0) {
        return MstResult{
            .edges = try allocator.alloc(WeightedEdge, 0),
            .total_weight = 0.0,
            .allocator = allocator,
        };
    }
    
    // Collect all edges with their weights
    var edges = std.ArrayList(WeightedEdge).init(allocator);
    defer edges.deinit();
    
    // Iterate through all nodes and their edges
    var it = graph.nodes.iterator();
    while (it.next()) |node_entry| {
        const u = node_entry.key_ptr.*;
        const neighbors = node_entry.value_ptr.*;
        var neighbor_it = neighbors.iterator();
        while (neighbor_it.next()) |neighbor_entry| {
            const v = neighbor_entry.key_ptr.*;
            const weight = neighbor_entry.value_ptr.*;
            
            // Only add edge once (for undirected graph, avoid duplicates)
            if (u < v) {
                try edges.append(WeightedEdge{
                    .u = u,
                    .v = v,
                    .weight = weight,
                });
            }
        }
    }
    
    // Sort edges by weight (ascending)
    std.mem.sort(WeightedEdge, edges.items, {}, comptime std.sort.asc(WeightedEdge));
    
    // Initialize Union-Find structure
    var uf = try UnionFind.init(allocator, num_nodes);
    defer uf.deinit();
    
    // Build MST
    var mst_edges = std.ArrayList(WeightedEdge).init(allocator);
    errdefer mst_edges.deinit();
    
    var total_weight: f64 = 0.0;
    
    for (edges.items) |edge| {
        // Check if adding this edge creates a cycle
        if (!uf.connected(edge.u, edge.v)) {
            // Add edge to MST
            try mst_edges.append(edge);
            total_weight += edge.weight;
            uf.union(edge.u, edge.v);
        }
    }
    
    return MstResult{
        .edges = try mst_edges.toOwnedSlice(),
        .total_weight = total_weight,
        .allocator = allocator,
    };
}

/// Find Minimum Spanning Forest for disconnected graphs.
/// Returns MST for each connected component.
pub fn kruskalMsf(allocator: Allocator, graph: *Graph) !MstResult {
    // Kruskal's naturally handles disconnected graphs
    // It will produce a minimum spanning forest
    return kruskalMst(allocator, graph);
}

test "Kruskal MST - simple triangle" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    // Create a triangle: 0-1 (weight 1), 1-2 (weight 2), 0-2 (weight 3)
    try graph.addEdge(0, 1, 1.0);
    try graph.addEdge(1, 2, 2.0);
    try graph.addEdge(0, 2, 3.0);
    
    var result = try kruskalMst(allocator, &graph);
    defer result.deinit();
    
    // MST should have 2 edges (for 3 nodes)
    try std.testing.expectEqual(@as(usize, 2), result.edges.len);
    
    // Total weight should be 1 + 2 = 3 (excluding the heaviest edge)
    try std.testing.expectEqual(@as(f64, 3.0), result.total_weight);
    
    // Verify edges are the two lightest ones
    var has_edge_0_1 = false;
    var has_edge_1_2 = false;
    for (result.edges) |edge| {
        if ((edge.u == 0 and edge.v == 1) or (edge.u == 1 and edge.v == 0)) {
            has_edge_0_1 = true;
        }
        if ((edge.u == 1 and edge.v == 2) or (edge.u == 2 and edge.v == 1)) {
            has_edge_1_2 = true;
        }
    }
    try std.testing.expect(has_edge_0_1);
    try std.testing.expect(has_edge_1_2);
}

test "Kruskal MST - square graph" {
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
    
    var result = try kruskalMst(allocator, &graph);
    defer result.deinit();
    
    // MST should have 3 edges (for 4 nodes)
    try std.testing.expectEqual(@as(usize, 3), result.edges.len);
    
    // Total weight should be 1 + 2 + 3 = 6 (three lightest edges that don't form cycle)
    try std.testing.expectEqual(@as(f64, 6.0), result.total_weight);
}

test "Kruskal MST - single node" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    try graph.addNode(0);
    
    var result = try kruskalMst(allocator, &graph);
    defer result.deinit();
    
    try std.testing.expectEqual(@as(usize, 0), result.edges.len);
    try std.testing.expectEqual(@as(f64, 0.0), result.total_weight);
}

test "Kruskal MST - empty graph" {
    const allocator = std.testing.allocator;
    
    var graph = Graph.init(allocator);
    defer graph.deinit();
    
    var result = try kruskalMst(allocator, &graph);
    defer result.deinit();
    
    try std.testing.expectEqual(@as(usize, 0), result.edges.len);
    try std.testing.expectEqual(@as(f64, 0.0), result.total_weight);
}
