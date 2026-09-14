//! MultiGraph - Undirected graph with multiple edges.
//!
//! The MultiGraph class allows any hashable object as a node
//! and can have multiple edges between the same pair of nodes.
//! Each edge has a unique key and can hold attributes.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

/// Edge data structure holding attributes for multi-edge
pub const MultiEdgeData = struct {
    key: usize,
    weight: f64,
    attributes: StringHashMap([]const u8),

    pub fn init(allocator: Allocator, edge_key: usize, weight: f64) MultiEdgeData {
        return .{
            .key = edge_key,
            .weight = weight,
            .attributes = StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *MultiEdgeData) void {
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

/// MultiGraph - Undirected graph with multiple edges
pub fn MultiGraph(comptime NodeType: type) type {
    return struct {
        const Self = @This();

        // Graph-level attributes
        graph_attributes: StringHashMap([]const u8),

        // Node storage: node_id -> NodeData
        _node: AutoHashMap(NodeType, NodeData),

        // Adjacency list: node_id -> (neighbor_id -> ArrayList(MultiEdgeData))
        // Using ArrayList to store multiple edges between same nodes
        _adj: AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(MultiEdgeData))),

        allocator: Allocator,
        edge_count: usize,
        next_edge_key: usize,

        pub const Error = error{
            OutOfMemory,
            NodeNotFound,
            InvalidNode,
        };

        /// Initialize an empty multigraph
        pub fn init(allocator: Allocator) Self {
            return Self.{
                .graph_attributes = StringHashMap([]const u8).init(allocator),
                ._node = AutoHashMap(NodeType, NodeData).init(allocator),
                ._adj = AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(MultiEdgeData))).init(allocator),
                .allocator = allocator,
                .edge_count = 0,
                .next_edge_key = 0,
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
                var edge_list_it = inner_map.*.valueIterator();
                while (edge_list_it.next()) |edge_list| {
                    for (edge_list.*.items) |*edge| {
                        edge.*.deinit();
                    }
                    edge_list.*.deinit();
                }
                inner_map.*.deinit();
            }
            self._adj.deinit();

            // Free graph attributes
            self.graph_attributes.deinit();
        }

        /// Add a node to the graph
        pub fn addNode(self: *Self, node: NodeType) !void {
            if (!self._node.contains(node)) {
                var node_data = NodeData.init(self.allocator);
                try self._node.put(node, node_data);
                try self._adj.put(node, AutoHashMap(NodeType, ArrayList(MultiEdgeData)).init(self.allocator));
            }
        }

        /// Add multiple nodes from an array
        pub fn addNodesFrom(self: *Self, nodes: []const NodeType) !void {
            for (nodes) |node| {
                try self.addNode(node);
            }
        }

        /// Check if node exists
        pub fn hasNode(self: *const Self, node: NodeType) bool {
            return self._node.contains(node);
        }

        /// Get number of nodes
        pub fn numberOfNodes(self: *const Self) usize {
            return self._node.count();
        }

        /// Get iterator over nodes
        pub fn nodes(self: *const Self) AutoHashMap(NodeType, NodeData).KeyIterator {
            return self._node.keyIterator();
        }

        /// Add an edge between two nodes with optional weight
        pub fn addEdge(self: *Self, u: NodeType, v: NodeType, weight: ?f64) !usize {
            try self.addNode(u);
            try self.addNode(v);

            const edge_weight = weight orelse 1.0;
            const edge_key = self.next_edge_key;
            self.next_edge_key += 1;

            var edge_data = MultiEdgeData.init(self.allocator, edge_key, edge_weight);

            // Get or create adjacency maps
            var adj_u = self._adj.get(u).?;
            var adj_v = self._adj.get(v).?;

            // Add edge in both directions (undirected)
            var edges_u = try adj_u.getOrPut(v);
            if (!edges_u.found_existing) {
                edges_u.value_ptr.* = ArrayList(MultiEdgeData).init(self.allocator);
            }
            try edges_u.value_ptr.*.append(edge_data);

            var edge_data_v = MultiEdgeData.init(self.allocator, edge_key, edge_weight);
            var edges_v = try adj_v.getOrPut(u);
            if (!edges_v.found_existing) {
                edges_v.value_ptr.* = ArrayList(MultiEdgeData).init(self.allocator);
            }
            try edges_v.value_ptr.*.append(edge_data_v);

            self.edge_count += 1;

            return edge_key;
        }

        /// Add multiple edges from an array
        pub fn addEdgesFrom(self: *Self, edges: []const struct { NodeType, NodeType, ?f64 }) !void {
            for (edges) |edge| {
                _ = try self.addEdge(edge[0], edge[1], edge[2]);
            }
        }

        /// Get number of edges
        pub fn numberOfEdges(self: *const Self) usize {
            return self.edge_count;
        }

        /// Check if edge exists (at least one edge between u and v)
        pub fn hasEdge(self: *const Self, u: NodeType, v: NodeType) bool {
            if (self._adj.get(u)) |adj_u| {
                return adj_u.contains(v);
            }
            return false;
        }

        /// Get neighbors of a node
        pub fn neighbors(self: *Self, node: NodeType) ?AutoHashMap(NodeType, ArrayList(MultiEdgeData)).KeyIterator {
            if (self._adj.get(node)) |adj| {
                return adj.keyIterator();
            }
            return null;
        }

        /// Get all edges between two nodes
        pub fn getEdgeData(self: *Self, u: NodeType, v: NodeType) ?ArrayList(MultiEdgeData) {
            if (self._adj.get(u)) |adj_u| {
                if (adj_u.get(v)) |edges| {
                    return edges.*;
                }
            }
            return null;
        }

        /// Remove an edge by key
        pub fn removeEdge(self: *Self, u: NodeType, v: NodeType, key: usize) !void {
            var adj_u = self._adj.get(u) orelse return error.NodeNotFound;
            var adj_v = self._adj.get(v) orelse return error.NodeNotFound;

            var edges_u = adj_u.get(v) orelse return error.NodeNotFound;
            var edges_v = adj_v.get(u) orelse return error.NodeNotFound;

            // Find and remove edge from u->v
            var i: usize = 0;
            while (i < edges_u.items.len) : (i += 1) {
                if (edges_u.items[i].key == key) {
                    edges_u.items[i].deinit();
                    _ = edges_u.swapRemove(i);
                    break;
                }
            }

            // Find and remove edge from v->u
            i = 0;
            while (i < edges_v.items.len) : (i += 1) {
                if (edges_v.items[i].key == key) {
                    edges_v.items[i].deinit();
                    _ = edges_v.swapRemove(i);
                    break;
                }
            }

            self.edge_count -= 1;
        }

        /// Remove a node and all its edges
        pub fn removeNode(self: *Self, node: NodeType) !void {
            // Remove all edges incident to this node
            if (self._adj.get(node)) |adj_node| {
                var neighbor_it = adj_node.keyIterator();
                while (neighbor_it.next()) |nbr_ptr| {
                    const nbr = nbr_ptr.*;
                    try self.removeEdge(node, nbr, 0); // Will need proper key handling
                }
            }

            // Remove node data
            var node_data = self._node.fetchRemove(node) orelse return error.NodeNotFound;
            node_data.value.deinit();

            // Remove adjacency map
            var adj_map = self._adj.fetchRemove(node) orelse unreachable;
            adj_map.value.deinit();
        }

        /// Clear all nodes and edges
        pub fn clear(self: *Self) void {
            self.deinit();
            self.* = Self.init(self.allocator);
        }

        /// Check if graph is directed (always false for MultiGraph)
        pub const is_directed = false;

        /// Get all edges as a list
        pub fn edges(self: *Self) !ArrayList(struct { NodeType, NodeType, f64, usize }) {
            var result = ArrayList(struct { NodeType, NodeType, f64, usize }).init(self.allocator);
            errdefer result.deinit();

            var u_it = self._node.keyIterator();
            while (u_it.next()) |u_ptr| {
                const u = u_ptr.*;
                if (self._adj.get(u)) |adj_u| {
                    var v_it = adj_u.keyIterator();
                    while (v_it.next()) |v_ptr| {
                        const v = v_ptr.*;
                        if (v_ptr.* > u_ptr.*) continue; // Avoid duplicates in undirected graph

                        if (adj_u.get(v)) |edge_list| {
                            for (edge_list.items) |edge| {
                                try result.append(.{ u, v, edge.weight, edge.key });
                            }
                        }
                    }
                }
            }

            return result;
        }
    };
}

test "MultiGraph basic" {
    const allocator = std.testing.allocator;
    var graph = MultiGraph(i32).init(allocator);
    defer graph.deinit();

    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 0, 1, 2.0 }, // Multiple edge
        .{ 1, 2, 3.0 },
    });

    try std.testing.expectEqual(@as(usize, 3), graph.numberOfEdges());
    try std.testing.expect(graph.hasEdge(0, 1));
    try std.testing.expect(graph.hasEdge(1, 2));
}

test "MultiGraph multiple edges" {
    const allocator = std.testing.allocator;
    var graph = MultiGraph(i32).init(allocator);
    defer graph.deinit();

    _ = try graph.addEdge(0, 1, 1.0);
    _ = try graph.addEdge(0, 1, 2.0);
    _ = try graph.addEdge(0, 1, 3.0);

    try std.testing.expectEqual(@as(usize, 3), graph.numberOfEdges());

    const edges = try graph.getEdgeData(0, 1);
    try std.testing.expectEqual(@as(usize, 3), edges.?.items.len);
}
