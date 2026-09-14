//! DiGraph - Directed graph implementation.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const Graph = @import("graph.zig").Graph;
const EdgeData = @import("graph.zig").EdgeData;
const NodeData = @import("graph.zig").NodeData;

/// DiGraph - Directed graph class
pub fn DiGraph(comptime NodeType: type) type {
    return struct {
        const Self = @This();

        // Graph-level attributes
        graph_attributes: AutoHashMap([]const u8, []const u8),
        
        // Node storage: node_id -> NodeData
        _node: AutoHashMap(NodeType, NodeData),
        
        // Successor adjacency: node_id -> (successor_id -> EdgeData)
        _succ: AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData)),
        
        // Predecessor adjacency: node_id -> (predecessor_id -> EdgeData)
        _pred: AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData)),
        
        allocator: Allocator,
        edge_count: usize,

        pub const Error = error{
            OutOfMemory,
            NodeNotFound,
            InvalidNode,
        };

        /// Initialize an empty directed graph
        pub fn init(allocator: Allocator) Self {
            return Self{
                .graph_attributes = AutoHashMap([]const u8, []const u8).init(allocator),
                ._node = AutoHashMap(NodeType, NodeData).init(allocator),
                ._succ = AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData)).init(allocator),
                ._pred = AutoHashMap(NodeType, AutoHashMap(NodeType, EdgeData)).init(allocator),
                .allocator = allocator,
                .edge_count = 0,
            };
        }

        /// Free all resources
        pub fn deinit(self: *Self) void {
            var node_it = self._node.valueIterator();
            while (node_it.next()) |node_data| {
                node_data.*.deinit();
            }
            self._node.deinit();

            var succ_it = self._succ.valueIterator();
            while (succ_it.next()) |inner_map| {
                var edge_it = inner_map.*.valueIterator();
                while (edge_it.next()) |edge_data| {
                    edge_data.*.deinit();
                }
                inner_map.*.deinit();
            }
            self._succ.deinit();

            var pred_it = self._pred.valueIterator();
            while (pred_it.next()) |inner_map| {
                var edge_it = inner_map.*.valueIterator();
                while (edge_it.next()) |edge_data| {
                    edge_data.*.deinit();
                }
                inner_map.*.deinit();
            }
            self._pred.deinit();

            self.graph_attributes.deinit();
        }

        /// Add a single node
        pub fn addNode(self: *Self, node: NodeType, attributes: ?AutoHashMap([]const u8, []const u8)) Error!void {
            if (!self._node.contains(node)) {
                var new_node = NodeData.init(self.allocator);
                try self._node.put(node, new_node);
                try self._succ.put(node, AutoHashMap(NodeType, EdgeData).init(self.allocator));
                try self._pred.put(node, AutoHashMap(NodeType, EdgeData).init(self.allocator));
            }
            
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

        /// Add multiple nodes
        pub fn addNodesFrom(self: *Self, nodes: []const NodeType) Error!void {
            for (nodes) |node| {
                try self.addNode(node, null);
            }
        }

        /// Add a directed edge from u to v
        pub fn addEdge(self: *Self, u: NodeType, v: NodeType, weight: ?f64) Error!void {
            try self.addNode(u, null);
            try self.addNode(v, null);

            var succ_u = self._succ.getPtr(u).?;
            var pred_v = self._pred.getPtr(v).?;

            const is_new_edge = !succ_u.contains(v);
            
            if (is_new_edge) {
                var edge_data = EdgeData.init(self.allocator);
                if (weight) |w| {
                    edge_data.weight = w;
                }
                
                try succ_u.put(v, edge_data);
                try pred_v.put(u, edge_data);
                self.edge_count += 1;
            } else {
                if (weight) |w| {
                    succ_u.getPtr(v).?.weight = w;
                }
            }
        }

        /// Add multiple edges
        pub fn addEdgesFrom(self: *Self, edges: []const struct { NodeType, NodeType, ?f64 }) Error!void {
            for (edges) |edge| {
                try self.addEdge(edge[0], edge[1], edge[2]);
            }
        }

        /// Remove a node
        pub fn removeNode(self: *Self, node: NodeType) Error!void {
            if (!self._node.contains(node)) {
                return Error.NodeNotFound;
            }

            // Remove all outgoing edges
            var successors = self._succ.get(node).?.clone();
            defer successors.deinit();
            var succ_it = successors.keyIterator();
            while (succ_it.next()) |nbr| {
                try self.removeEdge(node, nbr.*);
            }

            // Remove all incoming edges
            var predecessors = self._pred.get(node).?.clone();
            defer predecessors.deinit();
            var pred_it = predecessors.keyIterator();
            while (pred_it.next()) |nbr| {
                try self.removeEdge(nbr.*, node);
            }

            var node_data = self._node.fetchRemove(node).?;
            node_data.value.deinit();
            _ = self._succ.remove(node);
            _ = self._pred.remove(node);
        }

        /// Remove a directed edge
        pub fn removeEdge(self: *Self, u: NodeType, v: NodeType) Error!void {
            var succ_u = self._succ.getPtr(u) orelse return Error.NodeNotFound;
            var pred_v = self._pred.getPtr(v) orelse return Error.NodeNotFound;

            var edge_data = succ_u.fetchRemove(v) orelse return Error.NodeNotFound;
            _ = pred_v.remove(u);
            edge_data.value.deinit();
            self.edge_count -= 1;
        }

        /// Check if node exists
        pub fn hasNode(self: *Self, node: NodeType) bool {
            return self._node.contains(node);
        }

        /// Check if directed edge exists
        pub fn hasEdge(self: *Self, u: NodeType, v: NodeType) bool {
            return if (self._succ.get(u)) |succ_u|
                succ_u.contains(v)
            else
                false;
        }

        /// Get number of nodes
        pub fn numberOfNodes(self: *Self) usize {
            return self._node.count();
        }

        /// Get number of edges
        pub fn numberOfEdges(self: *Self) usize {
            return self.edge_count;
        }

        /// Get successors of a node
        pub fn successors(self: *Self, node: NodeType) ?*AutoHashMap(NodeType, EdgeData) {
            return self._succ.getPtr(node);
        }

        /// Get predecessors of a node
        pub fn predecessors(self: *Self, node: NodeType) ?*AutoHashMap(NodeType, EdgeData) {
            return self._pred.getPtr(node);
        }

        /// Get out-degree of a node
        pub fn outDegree(self: *Self, node: NodeType) ?usize {
            return if (self._succ.get(node)) |succ|
                succ.count()
            else
                null;
        }

        /// Get in-degree of a node
        pub fn inDegree(self: *Self, node: NodeType) ?usize {
            return if (self._pred.get(node)) |pred|
                pred.count()
            else
                null;
        }

        /// Reverse all edges in the graph
        pub fn reverse(self: *Self) Self {
            var reversed = Self.init(self.allocator);
            
            var node_it = self._node.iterator();
            while (node_it.next()) |entry| {
                reversed.addNode(entry.key_ptr.*, null) catch {};
            }
            
            var edge_it = self._succ.iterator();
            while (edge_it.next()) |u_entry| {
                var nbr_it = u_entry.value_ptr.iterator();
                while (nbr_it.next()) |v_entry| {
                    reversed.addEdge(v_entry.key_ptr.*, u_entry.key_ptr.*, u_entry.value_ptr.get(v_entry.key_ptr.*).?.weight) catch {};
                }
            }
            
            return reversed;
        }

        /// Convert to undirected graph
        pub fn toUndirectedClass(self: *Self) Graph(NodeType) {
            const GraphType = Graph(NodeType);
            var graph = GraphType.init(self.allocator);
            
            var node_it = self._node.iterator();
            while (node_it.next()) |entry| {
                graph.addNode(entry.key_ptr.*, null) catch {};
            }
            
            var edge_it = self._succ.iterator();
            while (edge_it.next()) |u_entry| {
                var nbr_it = u_entry.value_ptr.iterator();
                while (nbr_it.next()) |v_entry| {
                    graph.addEdge(u_entry.key_ptr.*, v_entry.key_ptr.*, u_entry.value_ptr.get(v_entry.key_ptr.*).?.weight) catch {};
                }
            }
            
            return graph;
        }
    };
}

test "DiGraph basic operations" {
    const allocator = std.testing.allocator;
    var graph = DiGraph(i32).init(allocator);
    defer graph.deinit();

    try graph.addNodesFrom(&[_]i32{ 1, 2, 3 });
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 1, 2, 1.0 },
        .{ 2, 3, 2.0 },
    });

    try std.testing.expect(graph.hasEdge(1, 2));
    try std.testing.expect(!graph.hasEdge(2, 1)); // Directed!
    try std.testing.expectEqual(@as(usize, 2), graph.numberOfEdges());

    // Test in/out degrees
    try std.testing.expectEqual(@as(?usize, 1), graph.outDegree(1));
    try std.testing.expectEqual(@as(?usize, 0), graph.inDegree(1));
    try std.testing.expectEqual(@as(?usize, 1), graph.outDegree(2));
    try std.testing.expectEqual(@as(?usize, 1), graph.inDegree(2));
}

test "DiGraph reverse" {
    const allocator = std.testing.allocator;
    var graph = DiGraph(i32).init(allocator);
    defer graph.deinit();

    try graph.addEdge(1, 2, 1.0);
    try graph.addEdge(2, 3, 2.0);

    var reversed = graph.reverse();
    defer reversed.deinit();

    try std.testing.expect(reversed.hasEdge(2, 1));
    try std.testing.expect(reversed.hasEdge(3, 2));
    try std.testing.expect(!reversed.hasEdge(1, 2));
}
