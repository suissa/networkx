# Zig NetworkX

A graph library for Zig 0.16, porting NetworkX functionality with the same function and variable names.

## Status

This is an **in-progress** implementation of NetworkX in Zig 0.16. The project focuses on common graph operations and the 10 most important algorithms for undirected graphs.

## Implemented Features

### Core Data Structures
- ✅ `Graph` - Undirected graph with node and edge attributes
- ✅ `DiGraph` - Directed graph with predecessors/successors

### Algorithms

#### Traversal
- ✅ `bfsEdges` - Breadth-first search edges
- ✅ `bfsTree` - BFS spanning tree
- ✅ `bfsPredecessors` - BFS predecessor mapping
- ✅ `bfsSuccessors` - BFS successor mapping  
- ✅ `bfsLayers` - Nodes by BFS layer
- ✅ `descendantsAtDistance` - Nodes at specific distance
- ✅ `dfsEdges` - Depth-first search edges
- ✅ `dfsTree` - DFS spanning tree
- ✅ `dfsPredecessors` - DFS predecessor mapping
- ✅ `dfsPostorderNodes` - DFS post-order traversal

#### Shortest Paths
- ✅ `hasPath` - Check if path exists
- ✅ `shortestPath` - Generic shortest path interface
- ✅ `shortestPathLength` - Get path length
- ✅ `averageShortestPathLength` - Average path length
- ✅ `dijkstraPath` - Dijkstra's algorithm
- ✅ `dijkstraPathLength` - Dijkstra distances
- ✅ `singleSourceShortestPath` - BFS unweighted shortest path
- ✅ `singleSourceShortestPathLength` - BFS distances
- ✅ `allPairsShortestPath` - All pairs shortest paths (unweighted)

#### Centrality
- ✅ `degreeCentrality` - Degree centrality
- ✅ `inDegreeCentrality` - In-degree centrality (directed)
- ✅ `outDegreeCentrality` - Out-degree centrality (directed)
- ⏳ `betweennessCentrality` - Planned
- ⏳ `closenessCentrality` - Planned
- ⏳ `eigenvectorCentrality` - Planned

#### Components
- ✅ `connectedComponents` - Find all connected components
- ✅ `numberOfConnectedComponents` - Count components
- ✅ `isConnected` - Check if graph is connected
- ✅ `nodeConnectedComponent` - Get component containing node

### Not Yet Implemented
- ⏳ `MultiGraph` - Undirected graph with multiple edges
- ⏳ `MultiDiGraph` - Directed graph with multiple edges
- ⏳ Bellman-Ford algorithm
- ⏳ Advanced centrality measures
- ⏳ Graph generators
- ⏳ Graph converters

## Installation

Add to your `build.zig.zon`:

```zig
.{
    .name = "your_project",
    .dependencies = .{
        .zig_networkx = .{
            .url = "https://github.com/yourusername/zig_networkx/archive/main.tar.gz",
            .hash = "TODO",
        },
    },
}
```

## Usage Example

```zig
const std = @import("std");
const networkx = @import("zig_networkx");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Create an undirected graph
    var graph = networkx.Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Add edges
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 2.0 },
        .{ 2, 3, 1.0 },
    });
    
    // BFS traversal
    const bfs_result = try networkx.bfsEdges(i32)(&graph, 0, false, null);
    defer bfs_result.deinit();
    
    // Shortest path
    const path = try networkx.shortestPath(i32)(&graph, 0, 3, null, "dijkstra");
    defer path.deinit();
    
    // Degree centrality
    const centrality = try networkx.degreeCentrality(i32)(&graph);
    defer centrality.deinit();
    
    // Connected components
    const components = try networkx.connectedComponents(i32)(&graph);
    defer {
        for (components.items) |*comp| comp.deinit();
        components.deinit();
    }
}
```

## API Naming Convention

All function names follow NetworkX Python naming conventions:
- `camelCase` for Zig functions (matching Python's `snake_case` semantically)
- Same parameter names as NetworkX where applicable
- Compatible return types adapted for Zig's type system

## Documentation

See [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for the complete implementation roadmap.

## Testing

Run tests with:

```bash
zig build test
```

## License

MIT License - see LICENSE file

## Contributing

Contributions welcome! Please see the IMPLEMENTATION_PLAN.md for upcoming features.
