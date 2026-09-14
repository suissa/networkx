//! MultiDiGraph - Directed graph with multiple edges.
//!
//! The MultiDiGraph class allows any hashable object as a node
//! and can have multiple directed edges between the same pair of nodes.
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

/// MultiDiGraph - Directed graph with multiple edges
pub fn MultiDiGraph(comptime NodeType: type) type {
    return struct {
        const Self = @This();

        // Graph-level attributes
        graph_attributes: StringHashMap([]const u8),

        // Node storage: node_id -> NodeData
        _node: AutoHashMap(NodeType, NodeData),

        // Successor adjacency: node_id -> (successor_id -> ArrayList(MultiEdgeData))
        _succ: AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(MultiEdgeData))),

        // Predecessor adjacency: node_id -> (predecessor_id -> ArrayList(MultiEdgeData))
        _pred: AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(MultiEdgeData))),

        allocator: Allocator,
        edge_count: usize,
        next_edge_key: usize,

        pub const Error = error{
            OutOfMemory,
            NodeNotFound,
            InvalidNode,
        };

        /// Initialize an empty multidigraph
        pub fn init(allocator: Allocator) Self {
            return Self.{
                .graph_attributes = StringHashMap([]const u8).init(allocator),
                ._node = AutoHashMap(NodeType, NodeData).init(allocator),
                ._succ = AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(MultiEdgeData))).init(allocator),
                ._pred = AutoHashMap(NodeType, AutoHashMap(NodeType, ArrayList(MultiEdgeData))).init(allocator),
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

            // Free all successor adjacency data
            var succ_it = self._succ.valueIterator();
            while (succ_it.next()) |inner_map| {
                var edge_list_it = inner_map.*.valueIterator();
                while (edge_list_it.next()) |edge_list| {
                    for (edge_list.*.items) |*edge| {
                        edge.*.deinit();
                    }
                    edge_list.*.deinit();
                }
                inner_map.*.deinit();
            }
            self._succ.deinit();

            // Free all predecessor adjacency data
            var pred_it = self._pred.valueIterator();
            while (pred_it.next()) |inner_map| {
                var edge_list_it = inner_map.*.valueIterator();
                while (edge_list_it.next()) |edge_list| {
                    for (edge_list.*.items) |*edge| {
                        edge.*.deinit();
                    }
                    edge_list.*.deinit();
                }
                inner_map.*.deinit();
            }
            self._pred.deinit();

            // Free graph attributes
            self.graph_attributes.deinit();
        }

        /// Add a node to the graph
        pub fn addNode(self: *Self, node: NodeType) !void {
            if (!self._node.contains(node)) {
                var node_data = NodeData.init(self.allocator);
                try self._node.put(node, node_data);
                try self._succ.put(node, AutoHashMap(NodeType, ArrayList(MultiEdgeData)).init(self.allocator));
                try self._pred.put(node, AutoHashMap(NodeType, ArrayList(MultiEdgeData)).init(self.allocator));
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

        /// Add a directed edge from u to v with optional weight
        pub fn addEdge(self: *Self, u: NodeType, v: NodeType, weight: ?f64) !usize {
            try self.addNode(u);
            try self.addNode(v);

            const edge_weight = weight orelse 1.0;
            const edge_key = self.next_edge_key;
            self.next_edge_key += 1;

            var edge_data = MultiEdgeData.init(self.allocator, edge_key, edge_weight);
            var edge_data_pred = MultiEdgeData.init(self.allocator, edge_key, edge_weight);

            // Add edge in successor map (u -> v)
            var succ_u = self._succ.get(u).?;
            var edges_succ = try succ_u.getOrPut(v);
            if (!edges_succ.found_existing) {
                edges_succ.value_ptr.* = ArrayList(MultiEdgeData).init(self.allocator);
            }
            try edges_succ.value_ptr.*.append(edge_data);

            // Add edge in predecessor map (v <- u)
            var pred_v = self._pred.get(v).?;
            var edges_pred = try pred_v.getOrPut(u);
            if (!edges_pred.found_existing) {
                edges_pred.value_ptr.* = ArrayList(MultiEdgeData).init(self.allocator);
            }
            try edges_pred.value_ptr.*.append(edge_data_pred);

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

        /// Check if edge exists (at least one edge from u to v)
        pub fn hasEdge(self: *const Self, u: NodeType, v: NodeType) bool {
            if (self._succ.get(u)) |succ_u| {
                return succ_u.contains(v);
            }
            return false;
        }

        /// Get successors of a node
        pub fn successors(self: *Self, node: NodeType) ?AutoHashMap(NodeType, ArrayList(MultiEdgeData)).KeyIterator {
            if (self._succ.get(node)) |succ| {
                return succ.keyIterator();
            }
            return null;
        }

        /// Get predecessors of a node
        pub fn predecessors(self: *Self, node: NodeType) ?AutoHashMap(NodeType, ArrayList(MultiEdgeData)).KeyIterator {
            if (self._pred.get(node)) |pred| {
                return pred.keyIterator();
            }
            return null;
        }

        /// Get neighbors (both successors and predecessors)
        pub fn neighbors(self: *Self, node: NodeType) !ArrayList(NodeType) {
            var result = ArrayList(NodeType).init(self.allocator);
            errdefer result.deinit();

            if (self._succ.get(node)) |succ| {
                var it = succ.keyIterator();
                while (it.next()) |nbr| {
                    try result.append(nbr.*);
                }
            }

            if (self._pred.get(node)) |pred| {
                var it = pred.keyIterator();
                while (it.next()) |nbr| {
                    // Avoid duplicates
                    var found = false;
                    for (result.items) |existing| {
                        if (existing == nbr.*) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        try result.append(nbr.*);
                    }
                }
            }

            return result;
        }

        /// Get all edges from u to v
        pub fn getEdgeData(self: *Self, u: NodeType, v: NodeType) ?ArrayList(MultiEdgeData) {
            if (self._succ.get(u)) |succ_u| {
                if (succ_u.get(v)) |edges| {
                    return edges.*;
                }
            }
            return null;
        }

        /// Remove an edge by key
        pub fn removeEdge(self: *Self, u: NodeType, v: NodeType, key: usize) !void {
            var succ_u = self._succ.get(u) orelse return error.NodeNotFound;
            var pred_v = self._pred.get(v) orelse return error.NodeNotFound;

            var edges_succ = succ_u.get(v) orelse return error.NodeNotFound;
            var edges_pred = pred_v.get(u) orelse return error.NodeNotFound;

            // Find and remove edge from successor map
            var i: usize = 0;
            while (i < edges_succ.items.len) : (i += 1) {
                if (edges_succ.items[i].key == key) {
                    edges_succ.items[i].deinit();
                    _ = edges_succ.swapRemove(i);
                    break;
                }
            }

            // Find and remove edge from predecessor map
            i = 0;
            while (i < edges_pred.items.len) : (i += 1) {
                if (edges_pred.items[i].key == key) {
                    edges_pred.items[i].deinit();
                    _ = edges_pred.swapRemove(i);
                    break;
                }
            }

            self.edge_count -= 1;
        }

        /// Remove a node and all its edges
        pub fn removeNode(self: *Self, node: NodeType) !void {
            // Remove all outgoing edges
            if (self._succ.get(node)) |succ_node| {
                var neighbor_it = succ_node.keyIterator();
                while (neighbor_it.next()) |nbr_ptr| {
                    const nbr = nbr_ptr.*;
                    // Remove first edge found (will need proper key handling for multiple edges)
                    if (self.getEdgeData(node, nbr)) |edges| {
                        if (edges.items.len > 0) {
                            try self.removeEdge(node, nbr, edges.items[0].key);
                        }
                    }
                }
            }

            // Remove all incoming edges
            if (self._pred.get(node)) |pred_node| {
                var neighbor_it = pred_node.keyIterator();
                while (neighbor_it.next()) |nbr_ptr| {
                    const nbr = nbr_ptr.*;
                    if (self.getEdgeData(nbr, node)) |edges| {
                        if (edges.items.len > 0) {
                            try self.removeEdge(nbr, node, edges.items[0].key);
                        }
                    }
                }
            }

            // Remove node data
            var node_data = self._node.fetchRemove(node) orelse return error.NodeNotFound;
            node_data.value.deinit();

            // Remove adjacency maps
            var succ_map = self._succ.fetchRemove(node) orelse unreachable;
            succ_map.value.deinit();

            var pred_map = self._pred.fetchRemove(node) orelse unreachable;
            pred_map.value.deinit();
        }

        /// Clear all nodes and edges
        pub fn clear(self: *Self) void {
            self.deinit();
            self.* = Self.init(self.allocator);
        }

        /// Check if graph is directed (always true for MultiDiGraph)
        pub const is_directed = true;

        /// Get all edges as a list
        pub fn edges(self: *Self) !ArrayList(struct { NodeType, NodeType, f64, usize }) {
            var result = ArrayList(struct { NodeType, NodeType, f64, usize }).init(self.allocator);
            errdefer result.deinit();

            var u_it = self._node.keyIterator();
            while (u_it.next()) |u_ptr| {
                const u = u_ptr.*;
                if (self._succ.get(u)) |succ_u| {
                    var v_it = succ_u.keyIterator();
                    while (v_it.next()) |v_ptr| {
                        const v = v_ptr.*;

                        if (succ_u.get(v)) |edge_list| {
                            for (edge_list.items) |edge| {
                                try result.append(.{ u, v, edge.weight, edge.key });
                            }
                        }
                    }
                }
            }

            return result;
        }

        /// Get in-degree of a node
        pub fn inDegree(self: *const Self, node: NodeType) usize {
            if (self._pred.get(node)) |pred_node| {
                var count: usize = 0;
                var it = pred_node.valueIterator();
                while (it.next()) |edges| {
                    count += edges.*.items.len;
                }
                return count;
            }
            return 0;
        }

        /// Get out-degree of a node
        pub fn outDegree(self: *const Self, node: NodeType) usize {
            if (self._succ.get(node)) |succ_node| {
                var count: usize = 0;
                var it = succ_node.valueIterator();
                while (it.next()) |edges| {
                    count += edges.*.items.len;
                }
                return count;
            }
            return 0;
        }
    };
}

test "MultiDiGraph basic" {
    const allocator = std.testing.allocator;
    var graph = MultiDiGraph(i32).init(allocator);
    defer graph.deinit();

    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 0, 1, 2.0 }, // Multiple edge
        .{ 1, 2, 3.0 },
    });

    try std.testing.expectEqual(@as(usize, 3), graph.numberOfEdges());
    try std.testing.expect(graph.hasEdge(0, 1));
    try std.testing.expect(graph.hasEdge(1, 2));
    try std.testing.expect(!graph.hasEdge(1, 0)); // Directed, so reverse edge doesn't exist
}

test "MultiDiGraph multiple edges" {
    const allocator = std.testing.allocator;
    var graph = MultiDiGraph(i32).init(allocator);
    defer graph.deinit();

    _ = try graph.addEdge(0, 1, 1.0);
    _ = try graph.addEdge(0, 1, 2.0);
    _ = try graph.addEdge(0, 1, 3.0);

    try std.testing.expectEqual(@as(usize, 3), graph.numberOfEdges());

    const edges = try graph.getEdgeData(0, 1);
    try std.testing.expectEqual(@as(usize, 3), edges.?.items.len);
}

test "MultiDiGraph directed" {
    const allocator = std.testing.allocator;
    var graph = MultiDiGraph(i32).init(allocator);
    defer graph.deinit();

    try graph.addEdge(0, 1, 1.0);

    try std.testing.expect(graph.hasEdge(0, 1));
    try std.testing.expect(!graph.hasEdge(1, 0));

    try std.testing.expectEqual(@as(usize, 1), graph.outDegree(0));
    try std.testing.expectEqual(@as(usize, 1), graph.inDegree(1));
    try std.testing.expectEqual(@as(usize, 0), graph.inDegree(0));
    try std.testing.expectEqual(@as(usize, 0), graph.outDegree(1));
}
