//! Connected components algorithms.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Queue = std.fifo.LinearFifo;

/// Find all connected components in an undirected graph.
/// 
/// Returns an ArrayList of ArrayLists, where each inner ArrayList
/// contains the nodes in one connected component.
pub fn connectedComponents(comptime NodeType: type) fn (
    graph: anytype,
) !ArrayList(ArrayList(NodeType)) {
    const allocator = graph.allocator;
    
    var components = ArrayList(ArrayList(NodeType)).init(allocator);
    errdefer {
        for (components.items) |*comp| {
            comp.deinit();
        }
        components.deinit();
    }
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    
    var node_it = graph._node.keyIterator();
    while (node_it.next()) |start_node| {
        if (seen.contains(start_node.*)) continue;
        
        // Start a new component with BFS
        var component = ArrayList(NodeType).init(allocator);
        errdefer component.deinit();
        
        try seen.put(start_node.*, {});
        try component.append(start_node.*);
        
        var queue = Queue(NodeType, .Dynamic).init(allocator);
        defer queue.deinit();
        try queue.writeItem(start_node.*);
        
        while (queue.readItem()) |node| {
            if (graph.neighbors(node)) |nbrs| {
                var nbr_it = nbrs.keyIterator();
                while (nbr_it.next()) |child| {
                    if (!seen.contains(child.*)) {
                        try seen.put(child.*, {});
                        try queue.writeItem(child.*);
                        try component.append(child.*);
                    }
                }
            }
        }
        
        try components.append(component);
    }
    
    return components;
}

/// Return the number of connected components in the graph.
pub fn numberOfConnectedComponents(comptime NodeType: type) fn (
    graph: anytype,
) !usize {
    var components = try connectedComponents(NodeType)(graph);
    defer {
        for (components.items) |*comp| {
            comp.deinit();
        }
        components.deinit();
    }
    
    return components.items.len;
}

/// Check if the graph is connected (has exactly one component).
pub fn isConnected(comptime NodeType: type) fn (
    graph: anytype,
) !bool {
    const n = graph.numberOfNodes();
    
    if (n == 0) {
        return false; // Empty graph is not connected
    }
    
    if (n == 1) {
        return true; // Single node is connected
    }
    
    // Do a BFS from an arbitrary node and check if we visit all nodes
    var seen = AutoHashMap(NodeType, void).init(graph.allocator);
    defer seen.deinit();
    
    var node_it = graph._node.keyIterator();
    const start_node = node_it.next().?.*;
    
    try seen.put(start_node, {});
    
    var queue = Queue(NodeType, .Dynamic).init(graph.allocator);
    defer queue.deinit();
    try queue.writeItem(start_node);
    
    var visited_count: usize = 0;
    
    while (queue.readItem()) |node| {
        visited_count += 1;
        
        if (graph.neighbors(node)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(child.*);
                }
            }
        }
    }
    
    return visited_count == n;
}

/// Get the connected component containing a specific node.
pub fn nodeConnectedComponent(comptime NodeType: type) fn (
    graph: anytype,
    node: NodeType,
) !ArrayList(NodeType) {
    const allocator = graph.allocator;
    
    if (!graph.hasNode(node)) {
        return error.NodeNotFound;
    }
    
    var component = ArrayList(NodeType).init(allocator);
    errdefer component.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    try seen.put(node, {});
    try component.append(node);
    
    var queue = Queue(NodeType, .Dynamic).init(allocator);
    defer queue.deinit();
    try queue.writeItem(node);
    
    while (queue.readItem()) |current| {
        if (graph.neighbors(current)) |nbrs| {
            var nbr_it = nbrs.keyIterator();
            while (nbr_it.next()) |child| {
                if (!seen.contains(child.*)) {
                    try seen.put(child.*, {});
                    try queue.writeItem(child.*);
                    try component.append(child.*);
                }
            }
        }
    }
    
    return component;
}

test "connectedComponents basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Create two disconnected components: {0,1,2} and {3,4}
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
        .{ 3, 4, 1.0 },
    });
    
    const components = try connectedComponents(i32)(&graph);
    defer {
        for (components.items) |*comp| {
            comp.deinit();
        }
        components.deinit();
    }
    
    try std.testing.expectEqual(@as(usize, 2), components.items.len);
}

test "isConnected true" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 1, 2, 1.0 },
        .{ 2, 3, 1.0 },
    });
    
    try std.testing.expect(try isConnected(i32)(&graph));
}

test "isConnected false" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 2, 3, 1.0 }, // Disconnected
    });
    
    try std.testing.expect(!try isConnected(i32)(&graph));
}

test "numberOfConnectedComponents" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    // Three components: {0}, {1,2}, {3,4,5}
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 1, 2, 1.0 },
        .{ 3, 4, 1.0 },
        .{ 4, 5, 1.0 },
    });
    
    try std.testing.expectEqual(@as(usize, 3), try numberOfConnectedComponents(i32)(&graph));
}
