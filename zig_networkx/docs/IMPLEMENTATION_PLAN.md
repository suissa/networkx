# NetworkX Zig Implementation Plan

This document outlines the implementation plan for recreating NetworkX functionality in Zig 0.16, focusing on common graph operations and the 10 most important algorithms for undirected graphs (Graph).

## Project Structure

```
zig_networkx/
├── build.zig              # Build configuration
├── build.zig.zon          # Package manifest
├── README.md              # Project documentation
├── src/
│   ├── root.zig           # Main library entry point
│   ├── classes/
│   │   ├── graph.zig      # Graph class (undirected)
│   │   ├── digraph.zig    # DiGraph class (directed)
│   │   ├── multigraph.zig # MultiGraph class
│   │   └── multidigraph.zig # MultiDiGraph class
│   ├── algorithms/
│   │   ├── shortest_paths/
│   │   │   ├── generic.zig       # shortest_path, has_path
│   │   │   ├── dijkstra.zig      # Dijkstra's algorithm
│   │   │   ├── bellman_ford.zig  # Bellman-Ford algorithm
│   │   │   └── unweighted.zig    # BFS-based shortest path
│   │   ├── traversal/
│   │   │   ├── bfs.zig           # Breadth-first search
│   │   │   └── dfs.zig           # Depth-first search
│   │   ├── centrality/
│   │   │   ├── degree.zig        # Degree centrality
│   │   │   ├── betweenness.zig   # Betweenness centrality
│   │   │   ├── closeness.zig     # Closeness centrality
│   │   │   └── eigenvector.zig   # Eigenvector centrality
│   │   └── components/
│   │       └── connected.zig     # Connected components
│   └── utils/
│       └── helpers.zig      # Utility functions
├── tests/
│   ├── test_graph.zig
│   ├── test_shortest_paths.zig
│   ├── test_traversal.zig
│   ├── test_centrality.zig
│   └── test_components.zig
└── docs/
    └── IMPLEMENTATION_PLAN.md
```

---

## Section 1: Core Data Structures

### 1.1 Graph Class (`src/classes/graph.zig`)

**Status**: TODO

**Description**: Base class for undirected graphs allowing any hashable object as a node with optional key/value attribute pairs on edges.

**Key Features**:
- Node storage with attributes
- Adjacency list representation
- Edge data storage
- Self-loops allowed, no multiple edges

**Functions to Implement**:
- `init()` - Initialize empty graph
- `deinit()` - Free resources
- `addNode()` - Add single node
- `addNodesFrom()` - Add multiple nodes
- `addEdge()` - Add single edge
- `addEdgesFrom()` - Add multiple edges
- `removeNode()` - Remove node
- `removeEdge()` - Remove edge
- `hasNode()` - Check if node exists
- `hasEdge()` - Check if edge exists
- `nodes()` - Get node iterator
- `edges()` - Get edge iterator
- `neighbors()` - Get neighbor iterator
- `degree()` - Get node degree
- `numberOfNodes()` - Count nodes
- `numberOfEdges()` - Count edges
- `toDirectedClass()` - Convert to DiGraph
- `toUndirectedClass()` - Convert to Graph

**Dependencies**: None (core structure)

---

### 1.2 DiGraph Class (`src/classes/digraph.zig`)

**Status**: TODO

**Description**: Directed graph implementation extending base graph functionality.

**Functions to Implement**:
- All Graph functions plus:
- `predecessors()` - Get predecessor nodes
- `successors()` - Get successor nodes
- `inDegree()` - Get in-degree
- `outDegree()` - Get out-degree
- `reverse()` - Reverse all edges

**Dependencies**: Graph class

---

### 1.3 MultiGraph Class (`src/classes/multigraph.zig`)

**Status**: TODO

**Description**: Undirected graph allowing multiple edges between nodes.

**Functions to Implement**:
- All Graph functions plus:
- `addEdge()` with key parameter
- `removeEdge()` with key parameter
- `numberOfEdges()` counting parallel edges

**Dependencies**: Graph class

---

### 1.4 MultiDiGraph Class (`src/classes/multidigraph.zig`)

**Status**: TODO

**Description**: Directed graph allowing multiple edges between nodes.

**Functions to Implement**:
- All DiGraph and MultiGraph functions combined

**Dependencies**: DiGraph, MultiGraph classes

---

## Section 2: Shortest Path Algorithms

### 2.1 Generic Shortest Path (`src/algorithms/shortest_paths/generic.zig`)

**Status**: TODO

**Functions to Implement**:
- `hasPath(graph, source, target)` - Check if path exists
- `shortestPath(graph, source, target, weight, method)` - Compute shortest path
- `shortestPathLength(graph, source, target, weight)` - Get path length
- `averageShortestPathLength(graph)` - Compute average path length

**Dependencies**: Graph, Dijkstra, Bellman-Ford, BFS

---

### 2.2 Dijkstra's Algorithm (`src/algorithms/shortest_paths/dijkstra.zig`)

**Priority**: HIGH (Top 10 Algorithm #1)

**Status**: TODO

**Description**: Find shortest paths from source to all other nodes using Dijkstra's algorithm with priority queue.

**Functions to Implement**:
- `dijkstraPath(graph, source, target, weight)` - Single pair shortest path
- `dijkstraPathLength(graph, source, weight)` - All distances from source
- `singleSourceDijkstraPath(graph, source, weight)` - All paths from source
- `allPairsDijkstraPath(graph, weight)` - All pairs shortest paths

**Time Complexity**: O((V + E) log V) with binary heap

**Dependencies**: Graph, PriorityQueue

---

### 2.3 Bellman-Ford Algorithm (`src/algorithms/shortest_paths/bellman_ford.zig`)

**Status**: TODO

**Description**: Handle graphs with negative edge weights.

**Functions to Implement**:
- `bellmanFordPath(graph, source, target, weight)`
- `bellmanFordPathLength(graph, source, weight)`
- `singleSourceBellmanFordPath(graph, source, weight)`

**Time Complexity**: O(V * E)

**Dependencies**: Graph

---

### 2.4 Unweighted Shortest Path (`src/algorithms/shortest_paths/unweighted.zig`)

**Priority**: HIGH (Top 10 Algorithm #2)

**Status**: TODO

**Description**: BFS-based shortest path for unweighted graphs.

**Functions to Implement**:
- `singleSourceShortestPath(graph, source)`
- `singleSourceShortestPathLength(graph, source)`
- `allPairsShortestPath(graph)`

**Time Complexity**: O(V + E)

**Dependencies**: Graph, BFS

---

## Section 3: Graph Traversal

### 3.1 Breadth-First Search (`src/algorithms/traversal/bfs.zig`)

**Priority**: HIGH (Top 10 Algorithm #3)

**Status**: TODO

**Description**: Traverse graph level by level from source node.

**Functions to Implement**:
- `bfsEdges(graph, source, reverse, depthLimit)` - Iterate BFS edges
- `bfsTree(graph, source)` - Get BFS tree
- `bfsPredecessors(graph, source)` - Get predecessor mapping
- `bfsSuccessors(graph, source)` - Get successor mapping
- `bfsLayers(graph, source)` - Get nodes by layer
- `descendantsAtDistance(graph, source, distance)` - Get nodes at distance

**Time Complexity**: O(V + E)

**Dependencies**: Graph

---

### 3.2 Depth-First Search (`src/algorithms/traversal/dfs.zig`)

**Priority**: HIGH (Top 10 Algorithm #4)

**Status**: TODO

**Description**: Traverse graph depth-first from source node.

**Functions to Implement**:
- `dfsEdges(graph, source)` - Iterate DFS edges
- `dfsTree(graph, source)` - Get DFS tree
- `dfsPredecessors(graph, source)` - Get predecessor mapping
- `dfsSuccessors(graph, source)` - Get successor mapping
- `dfsPostorderNodes(graph, source)` - Get post-order traversal

**Time Complexity**: O(V + E)

**Dependencies**: Graph

---

## Section 4: Centrality Measures

### 4.1 Degree Centrality (`src/algorithms/centrality/degree.zig`)

**Priority**: HIGH (Top 10 Algorithm #5)

**Status**: TODO

**Description**: Measure node importance based on number of connections.

**Functions to Implement**:
- `degreeCentrality(graph)` - Normalized degree centrality
- `inDegreeCentrality(graph)` - For directed graphs
- `outDegreeCentrality(graph)` - For directed graphs

**Time Complexity**: O(V + E)

**Dependencies**: Graph

---

### 4.2 Betweenness Centrality (`src/algorithms/centrality/betweenness.zig`)

**Priority**: HIGH (Top 10 Algorithm #6)

**Status**: TODO

**Description**: Measure how often a node appears on shortest paths.

**Functions to Implement**:
- `betweennessCentrality(graph, normalized, endpoints)` 
- `edgeBetweennessCentrality(graph, normalized)`

**Time Complexity**: O(V * E) for unweighted, O(V * E + V^2 log V) for weighted

**Dependencies**: Graph, Shortest Paths

---

### 4.3 Closeness Centrality (`src/algorithms/centrality/closeness.zig`)

**Priority**: MEDIUM (Top 10 Algorithm #7)

**Status**: TODO

**Description**: Measure how close a node is to all other nodes.

**Functions to Implement**:
- `closenessCentrality(graph, node, distance)` 
- `improvedClosenessCentrality(graph)` 

**Time Complexity**: O(V * (V + E))

**Dependencies**: Graph, Shortest Paths

---

### 4.4 Eigenvector Centrality (`src/algorithms/centrality/eigenvector.zig`)

**Priority**: MEDIUM (Top 10 Algorithm #8)

**Status**: TODO

**Description**: Measure influence based on connections to important nodes.

**Functions to Implement**:
- `eigenvectorCentrality(graph, maxIter, tolerance)`
- `pagerank(graph, damping, personalization)`
- `hits(graph, maxIter, tolerance)` - Returns hub and authority scores

**Time Complexity**: O(V * iterations)

**Dependencies**: Graph, Linear Algebra utilities

---

## Section 5: Connected Components

### 5.1 Connected Components (`src/algorithms/components/connected.zig`)

**Priority**: HIGH (Top 10 Algorithm #9)

**Status**: TODO

**Description**: Find connected components in undirected graphs.

**Functions to Implement**:
- `connectedComponents(graph)` - Iterator over components
- `numberOfConnectedComponents(graph)` - Count components
- `isConnected(graph)` - Check if graph is connected
- `nodeConnectedComponent(graph, node)` - Get component containing node

**Time Complexity**: O(V + E)

**Dependencies**: Graph, BFS/DFS

---

### 5.2 Strongly Connected Components (for DiGraph)

**Priority**: HIGH (Top 10 Algorithm #10)

**Status**: TODO

**Description**: Find strongly connected components in directed graphs using Kosaraju's or Tarjan's algorithm.

**Functions to Implement**:
- `stronglyConnectedComponents(digraph)` - Iterator over SCCs
- `numberOfStronglyConnectedComponents(digraph)` - Count SCCs
- `isStronglyConnected(digraph)` - Check if strongly connected
- `condensation(digraph)` - Create DAG of SCCs

**Time Complexity**: O(V + E)

**Dependencies**: DiGraph, DFS

---

## Section 6: Additional Important Algorithms

### 6.1 Minimum Spanning Tree

**Status**: FUTURE

**Functions**:
- `minimumSpanningTree(graph, weight)` - Kruskal's or Prim's algorithm
- `isSpanningTree(graph, subgraph)`

---

### 6.2 Cycle Detection

**Status**: FUTURE

**Functions**:
- `findCycle(graph, source)` - Find a cycle
- `cycleBasis(graph)` - Get cycle basis
- `simpleCycles(graph)` - Find all simple cycles (directed)

---

### 6.3 Clustering Coefficient

**Status**: FUTURE

**Functions**:
- `clustering(graph, node)` - Local clustering coefficient
- `averageClustering(graph)` - Average clustering coefficient

---

### 6.4 Community Detection

**Status**: FUTURE

**Functions**:
- `greedyModularityCommunities(graph)` - Louvain-like algorithm
- `modularity(graph, communities)` - Compute modularity score

---

### 6.5 Matching

**Status**: FUTURE

**Functions**:
- `maxWeightMatching(graph, maxcardinality)` - Maximum weighted matching
- `minWeightMatching(graph)` - Minimum weighted matching

---

### 6.6 Flow Algorithms

**Status**: FUTURE

**Functions**:
- `maximumFlow(graph, source, target, capacity)` - Max flow
- `minimumCut(graph, source, target, capacity)` - Min cut

---

### 6.7 Graph Generators

**Status**: FUTURE

**Functions**:
- `completeGraph(n)` - Complete graph K_n
- `pathGraph(n)` - Path graph P_n
- `cycleGraph(n)` - Cycle graph C_n
- `starGraph(n)` - Star graph S_n
- `randomGraph(n, p)` - Erdős-Rényi G(n, p)

---

### 6.8 Graph Converters

**Status**: FUTURE

**Functions**:
- `toAdjacencyMatrix(graph)` - Convert to adjacency matrix
- `fromAdjacencyMatrix(matrix)` - Create graph from matrix
- `toSparseMatrix(graph)` - Convert to sparse matrix
- `fromEdgeList(edges)` - Create graph from edge list

---

### 6.9 Isomorphism

**Status**: FUTURE

**Functions**:
- `isIsomorphic(graph1, graph2)` - Check graph isomorphism
- `subgraphIsomorphic(subgraph, graph)` - Check subgraph isomorphism

---

### 6.10 Planarity Testing

**Status**: FUTURE

**Functions**:
- `isPlanar(graph)` - Test planarity
- `planarEmbedding(graph)` - Get planar embedding if exists

---

## Section 7: Implementation Order

### Phase 1: Foundation (Week 1-2)
1. ✅ Project setup with build.zig
2. ✅ Graph class implementation
3. ✅ Basic graph operations (add/remove nodes/edges)
4. ✅ Node and edge iterators
5. Unit tests for Graph class

### Phase 2: Core Traversal (Week 2-3)
6. ✅ BFS implementation
7. ✅ DFS implementation  
8. ✅ Unweighted shortest paths
9. Unit tests for traversal algorithms

### Phase 3: Weighted Algorithms (Week 3-4)
10. ✅ Dijkstra's algorithm
11. ✅ Bellman-Ford algorithm
12. ✅ Generic shortest path interface
13. Unit tests for shortest path algorithms

### Phase 4: Centrality Measures (Week 4-5)
14. ✅ Degree centrality
15. ✅ Betweenness centrality
16. ✅ Closeness centrality
17. ✅ Eigenvector centrality & PageRank
18. Unit tests for centrality algorithms

### Phase 5: Components (Week 5-6)
19. ✅ Connected components (undirected)
20. ✅ Strongly connected components (directed)
21. ✅ Condensation graph
22. Unit tests for component algorithms

### Phase 6: Advanced Features (Week 6-8)
23. DiGraph implementation
24. MultiGraph implementation
25. MultiDiGraph implementation
26. Graph converters
27. Unit tests for all graph types

### Phase 7: Polish & Documentation (Week 8-9)
28. Performance optimization
29. Comprehensive documentation
30. Example programs
31. Benchmark suite

---

## Section 8: Technical Considerations for Zig 0.16

### Memory Management
- Use Arena allocator for temporary allocations during algorithm execution
- Provide both owned and borrowed return types where appropriate
- Implement proper `deinit()` methods for all data structures

### Generics
- Leverage Zig's comptime for generic node types (any hashable type)
- Use `comptime T: type` for node type parameters
- Implement hash functions for common types

### Error Handling
- Define comprehensive error sets for each algorithm
- Use `!T` return types for fallible functions
- Provide clear error messages for debugging

### Performance
- Use `ArrayList` for dynamic arrays
- Implement custom priority queue for Dijkstra
- Consider SIMD optimizations for dense graph operations
- Profile and optimize hot paths

### API Design
- Mirror NetworkX Python API naming conventions
- Provide both iterator-based and collection-returning variants
- Support optional parameters with sensible defaults

---

## Section 9: Testing Strategy

### Unit Tests
- Test each function independently
- Cover edge cases (empty graphs, single node, disconnected)
- Verify against known results from NetworkX Python

### Integration Tests
- Test algorithm combinations (e.g., BFS + shortest path)
- Verify consistency across different graph types

### Property-Based Tests
- Generate random graphs and verify invariants
- Check that algorithms produce valid outputs

### Benchmark Suite
- Compare performance against NetworkX Python
- Track performance regressions

---

## Section 10: Success Criteria

The implementation will be considered complete when:
1. All 10 priority algorithms are implemented and tested
2. Graph, DiGraph, MultiGraph, and MultiDiGraph classes work correctly
3. API matches NetworkX naming conventions
4. Documentation is comprehensive
5. Test coverage exceeds 90%
6. Performance is competitive with or better than NetworkX for common operations
