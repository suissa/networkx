//! Breadth-First Search traversal algorithms.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Queue = std.fifo.LinearFifo;

/// BFS edges iterator result
pub const BfsEdge = struct {
    parent: []const u8,
    child: []const u8,
};

/// Iterate over edges in a breadth-first search
pub fn bfsEdges(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    reverse: bool,
    depth_limit: ?usize,
) !ArrayList(struct { NodeType, NodeType }) {
    _ = reverse; // TODO: implement for directed graphs
    
    const GraphType = @TypeOf(graph);
    const allocator = graph.allocator;
    
    var edges = ArrayList(struct { NodeType, NodeType }).init(allocator);
    errdefer edges.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    
    try seen.put(source, {});
    
    var queue = Queue(NodeType, .Dynamic).init(allocator);
    defer queue.deinit();
    
    try queue.writeItem(source);
    
    const max_depth = depth_limit orelse graph.numberOfNodes();
    var depth: usize = 0;
    
    while (queue.readItem()) |parent| {
        if (depth >= max_depth) break;
        
        if (graph.neighbors(parent)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(child.*);
                    try edges.append(.{ parent, child.* });
                }
            }
        }
        depth += 1;
    }
    
    return edges;
}

/// Create a BFS tree from source
pub fn bfsTree(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    reverse: bool,
) !@import("digraph.zig").DiGraph(NodeType) {
    const DiGraphType = @import("digraph.zig").DiGraph(NodeType);
    const allocator = graph.allocator;
    
    var tree = DiGraphType.init(allocator);
    errdefer tree.deinit();
    
    // Add source node
    try tree.addNode(source, null);
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(source, {});
    
    var queue = Queue(NodeType, .Dynamic).init(allocator);
    defer queue.deinit();
    try queue.writeItem(source);
    
    while (queue.readItem()) |parent| {
        if (graph.neighbors(parent)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(child.*);
                    try tree.addNode(child.*, null);
                    try tree.addEdge(parent, child.*, null);
                }
            }
        }
    }
    
    return tree;
}

/// Get predecessors in BFS traversal
pub fn bfsPredecessors(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
) !AutoHashMap(NodeType, NodeType) {
    const allocator = graph.allocator;
    
    var predecessors = AutoHashMap(NodeType, NodeType).init(allocator);
    errdefer predecessors.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(source, {});
    
    var queue = Queue(NodeType, .Dynamic).init(allocator);
    defer queue.deinit();
    try queue.writeItem(source);
    
    while (queue.readItem()) |parent| {
        if (graph.neighbors(parent)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(child.*);
                    try predecessors.put(child.*, parent);
                }
            }
        }
    }
    
    return predecessors;
}

/// Get successors in BFS traversal
pub fn bfsSuccessors(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
) !AutoHashMap(NodeType, ArrayList(NodeType)) {
    const allocator = graph.allocator;
    
    var successors = AutoHashMap(NodeType, ArrayList(NodeType)).init(allocator);
    errdefer {
        var it = successors.valueIterator();
        while (it.next()) |list| {
            list.*.deinit();
        }
        successors.deinit();
    }
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(source, {});
    
    var queue = Queue(NodeType, .Dynamic).init(allocator);
    defer queue.deinit();
    try queue.writeItem(source);
    
    while (queue.readItem()) |parent| {
        if (graph.neighbors(parent)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(child.*);
                    
                    if (!successors.contains(parent)) {
                        try successors.put(parent, ArrayList(NodeType).init(allocator));
                    }
                    try successors.getPtr(parent).?.append(child.*);
                }
            }
        }
    }
    
    return successors;
}

/// Get nodes at each BFS layer
pub fn bfsLayers(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
) !ArrayList(ArrayList(NodeType)) {
    const allocator = graph.allocator;
    
    var layers = ArrayList(ArrayList(NodeType)).init(allocator);
    errdefer {
        for (layers.items) |*layer| {
            layer.deinit();
        }
        layers.deinit();
    }
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(source, {});
    
    var current_layer = ArrayList(NodeType).init(allocator);
    defer current_layer.deinit();
    try current_layer.append(source);
    
    while (current_layer.items.len > 0) {
        var next_layer = ArrayList(NodeType).init(allocator);
        errdefer next_layer.deinit();
        
        for (current_layer.items) |node| {
            if (graph.neighbors(node)) |nbrs| {
                var nbr_it = nbrs.keyIterator();
                while (nbr_it.next()) |child| {
                    if (!seen.contains(child.*)) {
                        try seen.put(child.*, {});
                        try next_layer.append(child.*);
                    }
                }
            }
        }
        
        // Clone current layer before appending
        var layer_copy = ArrayList(NodeType).init(allocator);
        try layer_copy.appendSlice(current_layer.items);
        try layers.append(layer_copy);
        
        current_layer.deinit();
        current_layer = next_layer;
    }
    
    return layers;
}

/// Get descendants at a specific distance from source
pub fn descendantsAtDistance(comptime NodeType: type) fn (
    graph: anytype,
    source: NodeType,
    distance: usize,
) !ArrayList(NodeType) {
    const allocator = graph.allocator;
    
    var descendants = ArrayList(NodeType).init(allocator);
    errdefer descendants.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(source, {});
    
    var current_level = ArrayList(NodeType).init(allocator);
    defer current_level.deinit();
    try current_level.append(source);
    
    var current_distance: usize = 0;
    
    while (current_level.items.len > 0 and current_distance < distance) {
        var next_level = ArrayList(NodeType).init(allocator);
        defer next_level.deinit();
        
        for (current_level.items) |node| {
            if (graph.neighbors(node)) |nbrs| {
                var nbr_it = nbrs.keyIterator();
                while (nbr_it.next()) |child| {
                    if (!seen.contains(child.*)) {
                        try seen.put(child.*, {});
                        try next_level.append(child.*);
                    }
                }
            }
        }
        
        current_level.deinit();
        current_level = next_level;
        current_distance += 1;
    }
    
    if (current_distance == distance) {
        try descendants.appendSlice(current_level.items);
    }
    
    return descendants;
}

test "bfsEdges basic" {
    const std = @import("std");
    const Graph = @import("graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
        .{ 2, 3, 1.0 },
    });
    
    const edges = try bfsEdges(i32)(&graph, 0, false, null);
    defer edges.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), edges.items.len);
    try std.testing.expectEqual(@as(i32, 0), edges.items[0][0]);
    try std.testing.expectEqual(@as(i32, 1), edges.items[0][1]);
}

test "bfsTree basic" {
    const std = @import("std");
    const Graph = @import("graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 0, 2, 1.0 },
        .{ 1, 3, 1.0 },
    });
    
    var tree = try bfsTree(i32)(&graph, 0, false);
    defer tree.deinit();
    
    try std.testing.expect(tree.hasNode(0));
    try std.testing.expect(tree.hasNode(1));
    try std.testing.expect(tree.hasNode(2));
    try std.testing.expect(tree.hasNode(3));
    try std.testing.expect(tree.hasEdge(0, 1));
    try std.testing.expect(tree.hasEdge(0, 2));
    try std.testing.expect(tree.hasEdge(1, 3));
}
