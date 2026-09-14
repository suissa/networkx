//! Depth-First Search traversal algorithms.

const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

/// Iterate over edges in a depth-first search
pub fn dfsEdges(comptime NodeType: type) fn (
    graph: anytype,
    source: ?NodeType,
) !ArrayList(struct { NodeType, NodeType }) {
    const GraphType = @TypeOf(graph);
    const allocator = graph.allocator;
    
    var edges = ArrayList(struct { NodeType, NodeType }).init(allocator);
    errdefer edges.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    
    // If no source specified, iterate over all nodes
    var nodes_to_visit = ArrayList(NodeType).init(allocator);
    defer nodes_to_visit.deinit();
    
    if (source) |s| {
        try nodes_to_visit.append(s);
    } else {
        // Add all nodes
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try nodes_to_visit.append(node.*);
        }
    }
    
    for (nodes_to_visit.items) |start_node| {
        if (seen.contains(start_node)) continue;
        
        var stack = ArrayList(NodeType).init(allocator);
        defer stack.deinit();
        try stack.append(start_node);
        
        while (stack.popOrNull()) |node| {
            if (!seen.contains(node)) {
                try seen.put(node, {});
                
                if (graph.neighbors(node)) |nbrs| {
                    var nbr_it = nbrs.keyIterator();
                    while (nbr_it.next()) |child| {
                        if (!seen.contains(child.*)) {
                            try edges.append(.{ node, child.* });
                            try stack.append(child.*);
                        }
                    }
                }
            }
        }
    }
    
    return edges;
}

/// Create a DFS tree from source
pub fn dfsTree(comptime NodeType: type) fn (
    graph: anytype,
    source: ?NodeType,
) !@import("../classes/digraph.zig").DiGraph(NodeType) {
    const DiGraphType = @import("../classes/digraph.zig").DiGraph(NodeType);
    const allocator = graph.allocator;
    
    var tree = DiGraphType.init(allocator);
    errdefer tree.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    
    var nodes_to_visit = ArrayList(NodeType).init(allocator);
    defer nodes_to_visit.deinit();
    
    if (source) |s| {
        try nodes_to_visit.append(s);
        try tree.addNode(s, null);
    } else {
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try nodes_to_visit.append(node.*);
        }
        if (nodes_to_visit.items.len > 0) {
            try tree.addNode(nodes_to_visit.items[0], null);
        }
    }
    
    for (nodes_to_visit.items) |start_node| {
        if (seen.contains(start_node)) continue;
        
        var stack = ArrayList(NodeType).init(allocator);
        defer stack.deinit();
        try stack.append(start_node);
        
        while (stack.popOrNull()) |node| {
            if (!seen.contains(node)) {
                try seen.put(node, {});
                
                if (graph.neighbors(node)) |nbrs| {
                    var nbr_it = nbrs.keyIterator();
                    while (nbr_it.next()) |child| {
                        if (!seen.contains(child.*)) {
                            try tree.addNode(child.*, null);
                            try tree.addEdge(node, child.*, null);
                            try stack.append(child.*);
                        }
                    }
                }
            }
        }
    }
    
    return tree;
}

/// Get predecessors in DFS traversal
pub fn dfsPredecessors(comptime NodeType: type) fn (
    graph: anytype,
    source: ?NodeType,
) !AutoHashMap(NodeType, NodeType) {
    const allocator = graph.allocator;
    
    var predecessors = AutoHashMap(NodeType, NodeType).init(allocator);
    errdefer predecessors.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    
    var nodes_to_visit = ArrayList(NodeType).init(allocator);
    defer nodes_to_visit.deinit();
    
    if (source) |s| {
        try nodes_to_visit.append(s);
    } else {
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try nodes_to_visit.append(node.*);
        }
    }
    
    for (nodes_to_visit.items) |start_node| {
        if (seen.contains(start_node)) continue;
        
        var stack = ArrayList(NodeType).init(allocator);
        defer stack.deinit();
        try stack.append(start_node);
        
        while (stack.popOrNull()) |node| {
            if (!seen.contains(node)) {
                try seen.put(node, {});
                
                if (graph.neighbors(node)) |nbrs| {
                    var nbr_it = nbrs.keyIterator();
                    while (nbr_it.next()) |child| {
                        if (!seen.contains(child.*)) {
                            try predecessors.put(child.*, node);
                            try stack.append(child.*);
                        }
                    }
                }
            }
        }
    }
    
    return predecessors;
}

/// Get nodes in DFS post-order traversal
pub fn dfsPostorderNodes(comptime NodeType: type) fn (
    graph: anytype,
    source: ?NodeType,
) !ArrayList(NodeType) {
    const allocator = graph.allocator;
    
    var result = ArrayList(NodeType).init(allocator);
    errdefer result.deinit();
    
    var seen = AutoHashMap(NodeType, void).init(allocator);
    defer seen.deinit();
    
    var nodes_to_visit = ArrayList(NodeType).init(allocator);
    defer nodes_to_visit.deinit();
    
    if (source) |s| {
        try nodes_to_visit.append(s);
    } else {
        var node_it = graph._node.keyIterator();
        while (node_it.next()) |node| {
            try nodes_to_visit.append(node.*);
        }
    }
    
    for (nodes_to_visit.items) |start_node| {
        if (seen.contains(start_node)) continue;
        
        // Use two stacks for post-order: one for traversal, one for result
        var stack = ArrayList(NodeType).init(allocator);
        defer stack.deinit();
        try stack.append(start_node);
        
        var output_stack = ArrayList(NodeType).init(allocator);
        defer output_stack.deinit();
        
        while (stack.popOrNull()) |node| {
            if (!seen.contains(node)) {
                try seen.put(node, {});
                try output_stack.append(node);
                
                if (graph.neighbors(node)) |nbrs| {
                    var nbr_it = nbrs.keyIterator();
                    while (nbr_it.next()) |child| {
                        if (!seen.contains(child.*)) {
                            try stack.append(child.*);
                        }
                    }
                }
            }
        }
        
        // Pop from output stack to get post-order
        while (output_stack.popOrNull()) |node| {
            try result.append(node);
        }
    }
    
    return result;
}

test "dfsEdges basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 0, 2, 1.0 },
        .{ 1, 3, 1.0 },
    });
    
    const edges = try dfsEdges(i32)(&graph, 0);
    defer edges.deinit();
    
    try std.testing.expect(edges.items.len >= 2);
}

test "dfsTree basic" {
    const std = @import("std");
    const Graph = @import("../classes/graph.zig").Graph;
    const allocator = std.testing.allocator;
    
    var graph = Graph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdgesFrom(&[_]struct { i32, i32, ?f64 }{
        .{ 0, 1, 1.0 },
        .{ 0, 2, 1.0 },
        .{ 1, 3, 1.0 },
    });
    
    var tree = try dfsTree(i32)(&graph, 0);
    defer tree.deinit();
    
    try std.testing.expect(tree.hasNode(0));
    try std.testing.expect(tree.hasNode(1));
    try std.testing.expect(tree.hasNode(2));
    try std.testing.expect(tree.hasNode(3));
}
