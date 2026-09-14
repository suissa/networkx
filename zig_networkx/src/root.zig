// Zig NetworkX - Graph Library for Zig 0.16
// A port of NetworkX functionality to Zig

const std = @import("std");
const Allocator = std.mem.Allocator;

// Graph classes
pub const Graph = @import("classes/graph.zig").Graph;
pub const DiGraph = @import("classes/digraph.zig").DiGraph;
pub const MultiGraph = @import("classes/multigraph.zig").MultiGraph;
pub const MultiDiGraph = @import("classes/multidigraph.zig").MultiDiGraph;

// Shortest path algorithms
pub const shortest_paths = @import("algorithms/shortest_paths/generic.zig");
pub const dijkstra = @import("algorithms/shortest_paths/dijkstra.zig");
pub const bellman_ford = @import("algorithms/shortest_paths/bellman_ford.zig");
pub const unweighted_shortest_path = @import("algorithms/shortest_paths/unweighted.zig");

// Traversal algorithms
pub const bfs = @import("algorithms/traversal/bfs.zig");
pub const dfs = @import("algorithms/traversal/dfs.zig");

// Centrality measures
pub const degree_centrality = @import("algorithms/centrality/degree.zig");
pub const betweenness_centrality = @import("algorithms/centrality/betweenness.zig");
pub const closeness_centrality = @import("algorithms/centrality/closeness.zig");
pub const eigenvector_centrality = @import("algorithms/centrality/eigenvector.zig");

// Components
pub const connected_components = @import("algorithms/components/connected.zig");

// Minimum Spanning Tree algorithms
pub const mst = @import("algorithms/mst/root.zig");

// Error types
pub const NetworkXError = error{
    NodeNotFound,
    NoPath,
    NoCycle,
    AmbiguousSolution,
    ExceededMaxIterations,
    PowerIterationFailedConvergence,
};

// Re-export commonly used items
pub const hasPath = shortest_paths.hasPath;
pub const shortestPath = shortest_paths.shortestPath;
pub const shortestPathLength = shortest_paths.shortestPathLength;
pub const averageShortestPathLength = shortest_paths.averageShortestPathLength;

pub const dijkstraPath = dijkstra.dijkstraPath;
pub const dijkstraPathLength = dijkstra.dijkstraPathLength;

pub const bfsEdges = bfs.bfsEdges;
pub const bfsTree = bfs.bfsTree;
pub const dfsEdges = dfs.dfsEdges;
pub const dfsTree = dfs.dfsTree;

pub const degreeCentrality = degree_centrality.degreeCentrality;
pub const betweennessCentrality = betweenness_centrality.betweennessCentrality;
pub const closenessCentrality = closeness_centrality.closenessCentrality;
pub const eigenvectorCentrality = eigenvector_centrality.eigenvectorCentrality;

pub const connectedComponents = connected_components.connectedComponents;
pub const numberOfConnectedComponents = connected_components.numberOfConnectedComponents;
pub const isConnected = connected_components.isConnected;

pub const kruskalMst = mst.kruskalMst;
pub const primMst = mst.primMst;
pub const UnionFind = mst.UnionFind;

test {
    // Import all tests
    _ = @import("classes/graph.zig");
    _ = @import("algorithms/shortest_paths/generic.zig");
    _ = @import("algorithms/shortest_paths/dijkstra.zig");
    _ = @import("algorithms/traversal/bfs.zig");
    _ = @import("algorithms/traversal/dfs.zig");
    _ = @import("algorithms/centrality/degree.zig");
    _ = @import("algorithms/components/connected.zig");
    _ = @import("algorithms/mst/root.zig");
}
