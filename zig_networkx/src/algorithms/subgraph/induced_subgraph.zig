// Operações com subgrafos
// Extração e manipulação de subgrafos

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Cria um subgrafo induzido pelos nós especificados
/// Um subgrafo induzido contém todos os nós e todas as arestas entre eles
pub fn inducedSubgraph(graph: anytype, allocator: Allocator, nodes: []const anytype) !@TypeOf(graph) {
    const GraphT = @TypeOf(graph);
    var subgraph = GraphT.init(allocator);
    errdefer subgraph.deinit();
    
    // Adiciona nós
    for (nodes) |node| {
        try subgraph.addNode(node);
    }
    
    // Adiciona arestas entre os nós do subgrafo
    var node_set = std.AutoHashMap(@TypeOf(nodes[0]), void).init(allocator);
    defer node_set.deinit();
    
    for (nodes) |node| {
        try node_set.put(node, {});
    }
    
    for (nodes) |u| {
        if (graph.adjacency.get(u)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |v_ptr| {
                const v = v_ptr.*;
                if (node_set.contains(v)) {
                    // Aresta está dentro do subgrafo
                    const weight = neighbors.get(v) orelse continue;
                    try subgraph.addEdge(u, v, .{ .weight = weight });
                }
            }
        }
    }
    
    return subgraph;
}

/// Cria um subgrafo baseado em um conjunto de arestas
pub fn edgeSubgraph(graph: anytype, allocator: Allocator, edges: []const anytype) !@TypeOf(graph) {
    const GraphT = @TypeOf(graph);
    var subgraph = GraphT.init(allocator);
    errdefer subgraph.deinit();
    
    const EdgeT = @TypeOf(edges[0]);
    const NodeT = @TypeOf(@field(edges[0], "0"));
    
    var nodes_added = std.AutoHashMap(NodeT, void).init(allocator);
    defer nodes_added.deinit();
    
    // Adiciona arestas e seus nós
    for (edges) |edge_any| {
        const edge = @as(*const struct { NodeT, NodeT }, @ptrCast(@alignCast(&edge_any)));
        const u = edge[0];
        const v = edge[1];
        
        if (!nodes_added.contains(u)) {
            try subgraph.addNode(u);
            try nodes_added.put(u, {});
        }
        
        if (!nodes_added.contains(v)) {
            try subgraph.addNode(v);
            try nodes_added.put(v, {});
        }
        
        // Obtém peso da aresta original se existir
        var weight: ?f64 = null;
        if (graph.adjacency.get(u)) |neighbors| {
            if (neighbors.get(v)) |w| {
                weight = w;
            }
        }
        
        try subgraph.addEdge(u, v, .{ .weight = weight orelse 1.0 });
    }
    
    return subgraph;
}

/// Cria uma cópia do grafo
pub fn copyGraph(graph: anytype, allocator: Allocator) !@TypeOf(graph) {
    const GraphT = @TypeOf(graph);
    var new_graph = GraphT.init(allocator);
    errdefer new_graph.deinit();
    
    // Copia todos os nós
    for (graph.nodes.keys()) |node| {
        try new_graph.addNode(node);
    }
    
    // Copia todas as arestas
    for (graph.nodes.keys()) |u| {
        if (graph.adjacency.get(u)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |v_ptr| {
                const v = v_ptr.*;
                const weight = neighbors.get(v) orelse continue;
                try new_graph.addEdge(u, v, .{ .weight = weight });
            }
        }
    }
    
    return new_graph;
}

/// Retorna o subgrafo complementar (arestas que não estão no grafo original)
pub fn complement(graph: anytype, allocator: Allocator) !@TypeOf(graph) {
    const GraphT = @TypeOf(graph);
    var comp = GraphT.init(allocator);
    errdefer comp.deinit();
    
    // Adiciona todos os nós
    for (graph.nodes.keys()) |node| {
        try comp.addNode(node);
    }
    
    // Adiciona arestas que não existem no grafo original
    const nodes = graph.nodes.keys();
    var i: usize = 0;
    while (i < nodes.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < nodes.len) : (j += 1) {
            const u = nodes[i];
            const v = nodes[j];
            
            if (!graph.hasEdge(u, v)) {
                try comp.addEdge(u, v, .{});
            }
        }
    }
    
    return comp;
}

test "inducedSubgraph - extrai subgrafo correto" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addNode(4);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 4, .{});
    try g.addEdge(1, 4, .{});
    
    var nodes = [_]anytype{ 1, 2, 3 };
    const sub = try inducedSubgraph(&g, std.heap.page_allocator, &nodes);
    defer sub.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), sub.numberOfNodes());
    try std.testing.expect(sub.hasEdge(1, 2));
    try std.testing.expect(sub.hasEdge(2, 3));
    try std.testing.expect(!sub.hasEdge(3, 4)); // 4 não está no subgrafo
}

test "edgeSubgraph - cria subgrafo por arestas" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(1, 3, .{});
    
    var edges = [_]anytype{
        @as(struct { i32, i32 }, .{ 1, 2 }),
        @as(struct { i32, i32 }, .{ 2, 3 }),
    };
    
    const sub = try edgeSubgraph(&g, std.heap.page_allocator, &edges);
    defer sub.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), sub.numberOfNodes());
    try std.testing.expectEqual(@as(usize, 2), sub.numberOfEdges());
}

test "complement - grafo completo tem complemento vazio" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(1, 3, .{});
    
    const comp = try complement(&g, std.heap.page_allocator);
    defer comp.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), comp.numberOfNodes());
    try std.testing.expectEqual(@as(usize, 0), comp.numberOfEdges());
}
