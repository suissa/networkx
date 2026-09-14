//! Graph - Base class for undirected graphs.
//!
//! The Graph class allows any hashable object as a node
//! and can associate key/value attribute pairs with each undirected edge.
//!
//! Self-loops are allowed but multiple edges are not (see MultiGraph).

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

/// Edge data structure holding attributes
pub const EdgeData = struct {
    weight: f64 = 1.0,
    attributes: StringHashMap([]const u8),

    pub fn init(allocator: Allocator) EdgeData {
        return .{
            .weight = 1.0,
            .attributes = StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *EdgeData) void {
        self.attributes.deinit();
    }
};

/// Node data structure holding attributes
pub const NodeData = struct {
    attributes: StringHashMap([]const u8),

    pub fn init(allocator: Allocator) NodeData {
        return .{
            .attributes = StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *NodeData) void {
        self.attributes.deinit();
    }
};

/// Adjacency entry: neighbor -> edge data
pub const AdjEntry = struct {
    neighbor: []const u8,
    edge_data: EdgeData,
};

/// Graph - Base class for undirected graphs
pub fn Graph(comptime NodeType: type) type {
    return struct {
        const Self = @This();

        // Graph-level attributes
        graph_attributes: StringHashMap([]const u8),
        
        // Node storage: node_id -> NodeData
        _node: AutoHashMap(NodeType, NodeData),
        
        // Adjacency list: node_id -> (neighbor_id -> EdgeData)
        _adj: AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData)),
        
        allocator: Allocator,
        edge_count: usize,

        pub const Error = error{
            OutOfMemory,
            NodeNotFound,
            InvalidNode,
        };

        /// Initialize an empty graph
        pub fn init(allocator: Allocator) Self {
            return Self{
                .graph_attributes = StringHashMap([]const u8).init(allocator),
                ._node = AutoHashMap(NodeType, NodeData).init(allocator),
                ._adj = AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData)).init(allocator),
                .allocator = allocator,
                .edge_count = 0,
            };
        }

        /// Free all resources
        pub fn deinit(self: *Self) void {
            // Free all node data
            var node_it = self._node.valueIterator();
            while (node_it.next()) |node_data| {
                node_data.*.deinit();
            }
            self._node.deinit();

            // Free all adjacency data
            var adj_it = self._adj.valueIterator();
            while (adj_it.next()) |inner_map| {
                var edge_it = inner_map.*.valueIterator();
                while (edge_it.next()) |edge_data| {
                    edge_data.*.deinit();
                }
                inner_map.*.deinit();
            }
            self._adj.deinit();

            // Free graph attributes
            self.graph_attributes.deinit();
        }

        /// Add a single node with optional attributes
        pub fn addNode(self: *Self, node: NodeType, attributes: ?StringHashMap([]const u8)) Error!void {
            if (!self._node.contains(node)) {
                var new_node = NodeData.init(self.allocator);
                try self._node.put(node, new_node);
                try self._adj.put(node, AutoHashMap(NodeType, EdgeData).init(self.allocator));
            }
            
            // Update attributes if provided
            if (attributes) |attrs| {
                var node_entry = self._node.getEntry(node);
                if (node_entry) |entry| {
                    var attr_it = attrs.iterator();
                    while (attr_it.next()) |kv| {
                        try entry.value_ptr.attributes.put(kv.key_ptr.*, kv.value_ptr.*);
                    }
                }
            }
        }

        /// Add multiple nodes from an iterable
        pub fn addNodesFrom(self: *Self, nodes: []const NodeType) Error!void {
            for (nodes) |node| {
                try self.addNode(node, null);
            }
        }

        /// Add an edge between two nodes with optional attributes
        pub fn addEdge(self: *Self, u: NodeType, v: NodeType, weight: ?f64) Error!void {
            // Ensure both nodes exist
            try self.addNode(u, null);
            try self.addNode(v, null);

            // Get or create edge data
            var adj_u = self._adj.getPtr(u).?;
            var adj_v = self._adj.getPtr(v).?;

            const is_new_edge = !adj_u.contains(v);
            
            if (is_new_edge) {
                var edge_data = EdgeData.init(self.allocator);
                if (weight) |w| {
                    edge_data.weight = w;
                }
                
                try adj_u.put(v, edge_data);
                try adj_v.put(u, edge_data); // Undirected: symmetric
                self.edge_count += 1;
            } else {
                // Update weight if edge exists
                if (weight) |w| {
                    adj_u.getPtr(v).?.weight = w;
                }
            }
        }

        /// Add multiple edges from a list
        pub fn addEdgesFrom(self: *Self, edges: []const struct { NodeType, NodeType, ?f64 }) Error!void {
            for (edges) |edge| {
                try self.addEdge(edge[0], edge[1], edge[2]);
            }
        }

        /// Remove a node and all incident edges
        pub fn removeNode(self: *Self, node: NodeType) Error!void {
            if (!self._node.contains(node)) {
                return Error.NodeNotFound;
            }

            // Remove all edges incident to this node
            var neighbors = self._adj.get(node).?.clone();
            defer neighbors.deinit();
            
            var it = neighbors.keyIterator();
            while (it.next()) |nbr| {
                try self.removeEdge(node, nbr.*);
            }

            // Remove the node itself
            var node_data = self._node.fetchRemove(node).?;
            node_data.value.deinit();
            _ = self._adj.remove(node);
        }

        /// Remove an edge between two nodes
        pub fn removeEdge(self: *Self, u: NodeType, v: NodeType) Error!void {
            var adj_u = self._adj.getPtr(u) orelse return Error.NodeNotFound;
            var adj_v = self._adj.getPtr(v) orelse return Error.NodeNotFound;

            var edge_data = adj_u.fetchRemove(v) orelse return Error.NodeNotFound;
            _ = adj_v.remove(u);
            edge_data.value.deinit();
            self.edge_count -= 1;
        }

        /// Check if a node exists in the graph
        pub fn hasNode(self: *Self, node: NodeType) bool {
            return self._node.contains(node);
        }

        /// Check if an edge exists between two nodes
        pub fn hasEdge(self: *Self, u: NodeType, v: NodeType) bool {
            return if (self._adj.get(u)) |adj_u|
                adj_u.contains(v)
            else
                false;
        }

        /// Get the number of nodes
        pub fn numberOfNodes(self: *Self) usize {
            return self._node.count();
        }

        /// Get the number of edges
        pub fn numberOfEdges(self: *Self) usize {
            return self.edge_count;
        }

        /// Get neighbors of a node
        pub fn neighbors(self: *Self, node: NodeType) ?AutoHashMap(NodeType, EdgeData) {
            return self._adj.get(node);
        }

        /// Get degree of a node
        pub fn degree(self: *Self, node: NodeType) ?usize {
            return if (self._adj.get(node)) |adj|
                adj.count()
            else
                null;
        }

        /// Iterator over all nodes
        pub fn nodes(self: *Self) AutoHashMap(NodeType, NodeData).KeyIterator {
            return self._node.keyIterator();
        }

        /// Iterator over all edges (returns unique edges only for undirected graph)
        pub fn EdgeIterator = struct {
            adj_it: AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData)).Iterator,
            current_inner_it: ?AutoHashMap(NodeType, EdgeData).Iterator,
            current_node: ?NodeType,
            seen_edges: std.AutoHashMap(struct { NodeType, NodeType }, void),
            allocator: Allocator,

            pub fn init(allocator: Allocator, adj: *AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData))) EdgeIterator {
                return .{
                    .adj_it = adj.iterator(),
                    .current_inner_it = null,
                    .current_node = null,
                    .seen_edges = std.AutoHashMap(struct { NodeType, NodeType }, void).init(allocator),
                    .allocator = allocator,
                };
            }

            pub fn next(self: *EdgeIterator) ?struct { NodeType, NodeType, *EdgeData } {
                while (true) {
                    // Get next inner iterator if needed
                    if (self.current_inner_it == null) {
                        if (self.adj_it.next()) |entry| {
                            self.current_node = entry.key_ptr.*;
                            self.current_inner_it = entry.value_ptr.iterator();
                        } else {
                            return null;
                        }
                    }

                    // Get next edge from current inner iterator
                    if (self.current_inner_it) |*inner_it| {
                        if (inner_it.next()) |edge_entry| {
                            const u = self.current_node.?;
                            const v = edge_entry.key_ptr.*;
                            
                            // For undirected graphs, only return each edge once
                            const edge_key = if (@intFromEnum(u) < @intFromEnum(v))
                                .{ u, v }
                            else
                                .{ v, u };
                            
                            if (!self.seen_edges.contains(edge_key)) {
                                try self.seen_edges.put(edge_key, {});
                                return .{ u, v, edge_entry.value_ptr };
                            }
                        } else {
                            self.current_inner_it = null;
                        }
                    }
                }
            }

            pub fn deinit(self: *EdgeIterator) void {
                self.seen_edges.deinit();
            }
        };

        pub fn edges(self: *Self) EdgeIterator {
            return EdgeIterator.init(self.allocator, &self._adj);
        }

        /// Convert to directed graph
        pub fn toDirectedClass(self: *Self) @import("digraph.zig").DiGraph(NodeType) {
            const DiGraphType = @import("digraph.zig").DiGraph(NodeType);
            var digraph = DiGraphType.init(self.allocator);
            
            // Copy all nodes
            var node_it = self._node.iterator();
            while (node_it.next()) |entry| {
                digraph.addNode(entry.key_ptr.*, null) catch {};
            }
            
            // Copy all edges (both directions for undirected)
            var edge_it = self.edges();
            defer edge_it.deinit();
            while (edge_it.next()) |edge| {
                digraph.addEdge(edge[0], edge[1], edge[2].weight) catch {};
                digraph.addEdge(edge[1], edge[0], edge[2].weight) catch {};
            }
            
            return digraph;
        }
    };
}

test "Graph basic operations" {
    const allocator = std.testing.allocator;
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();

    // Test adding nodes
    try graph.addNode(1, null);
    try graph.addNode(2, null);
    try graph.addNode(3, null);
    
    try std.testing.expect(graph.hasNode(1));
    try std.testing.expect(graph.hasNode(2));
    try std.testing.expect(graph.hasNode(3));
    try std.testing.expectEqual(@as(usize, 3), graph.numberOfNodes());

    // Test adding edges
    try graph.addEdge(1, 2, 1.0);
    try graph.addEdge(2, 3, 2.0);
    
    try std.testing.expect(graph.hasEdge(1, 2));
    try std.testing.expect(graph.hasEdge(2, 3));
    try std.testing.expectEqual(@as(usize, 2), graph.numberOfEdges());

    // Test neighbors
    const nbrs = graph.neighbors(2);
    try std.testing.expect(nbrs != null);
    try std.testing.expectEqual(@as(usize, 2), nbrs.?.count());

    // Test degree
    try std.testing.expectEqual(@as(?usize, 2), graph.degree(2));
    try std.testing.expectEqual(@as(?usize, 1), graph.degree(1));
}

test "Graph remove operations" {
    const allocator = std.testing.allocator;
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();

    try graph.addNodesFrom(&[_]i32{ 1, 2, 3, 4 });
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 1, 2, 1.0 },
        .{ 2, 3, 2.0 },
        .{ 3, 4, 3.0 },
    });

    try std.testing.expectEqual(@as(usize, 4), graph.numberOfNodes());
    try std.testing.expectEqual(@as(usize, 3), graph.numberOfEdges());

    // Remove edge
    try graph.removeEdge(2, 3);
    try std.testing.expectEqual(@as(usize, 2), graph.numberOfEdges());
    try std.testing.expect(!graph.hasEdge(2, 3));

    // Remove node
    try graph.removeNode(1);
    try std.testing.expectEqual(@as(usize, 3), graph.numberOfNodes());
    try std.testing.expect(!graph.hasNode(1));
}
