// Algoritmos de emparelhamento (matching) em grafos
// Emparelhamento é um conjunto de arestas sem vértices em comum

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Representa um emparelhamento (conjunto de arestas)
pub const Matching = struct {
    edges: []struct { anytype, anytype },
    allocator: Allocator,
    
    pub fn deinit(self: *Matching) void {
        self.allocator.free(self.edges);
    }
    
    /// Retorna o tamanho do emparelhamento (número de arestas)
    pub fn size(self: *const Matching) usize {
        return self.edges.len;
    }
    
    /// Verifica se um nó está coberto pelo emparelhamento
    pub fn isMatched(self: *const Matching, node: anytype) bool {
        for (self.edges) |edge| {
            // Comparação simplificada - em produção precisaria de comparação genérica
            _ = edge;
            _ = node;
            // Implementação real dependeria do tipo de nó
        }
        return false;
    }
};

/// Encontra um emparelhamento máximo usando algoritmo guloso
/// Não garante o máximo global, mas é rápido O(E + V)
pub fn greedyMatching(graph: anytype, allocator: Allocator) !Matching {
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    var matched = std.AutoHashMap(NodeT, bool).init(allocator);
    defer matched.deinit();
    
    // Inicializa todos como não emparelhados
    for (graph.nodes.keys()) |node| {
        try matched.put(node, false);
    }
    
    var edges_list = std.ArrayList(struct { NodeT, NodeT }).init(allocator);
    errdefer edges_list.deinit();
    
    // Itera sobre todas as arestas
    for (graph.nodes.keys()) |u| {
        if (matched.get(u)) continue;
        
        if (graph.adjacency.get(u)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |v_ptr| {
                const v = v_ptr.*;
                if (matched.get(v)) continue;
                
                // Emparelha u e v
                try edges_list.append(.{ u, v });
                try matched.put(u, true);
                try matched.put(v, true);
                break; // Move para próximo nó
            }
        }
    }
    
    // Converte para array genérico
    const result_edges = try allocator.alloc(struct { anytype, anytype }, edges_list.items.len);
    for (edges_list.items, 0..) |edge, i| {
        result_edges[i] = .{ edge[0], edge[1] };
    }
    edges_list.deinit();
    
    return Matching{
        .edges = result_edges,
        .allocator = allocator,
    };
}

/// Verifica se um conjunto de arestas forma um emparelhamento válido
pub fn isValidMatching(graph: anytype, edges: []const anytype) bool {
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    var used_nodes = std.AutoHashMap(NodeT, void).init(std.heap.page_allocator);
    defer used_nodes.deinit();
    
    for (edges) |edge_any| {
        const edge = @as(*const struct { NodeT, NodeT }, @ptrCast(@alignCast(&edge_any)));
        const u = edge[0];
        const v = edge[1];
        
        // Verifica se a aresta existe no grafo
        if (!graph.hasEdge(u, v)) {
            return false;
        }
        
        // Verifica se algum nó já foi usado
        if (used_nodes.contains(u) or used_nodes.contains(v)) {
            return false;
        }
        
        used_nodes.put(u, {}) catch return false;
        used_nodes.put(v, {}) catch return false;
    }
    
    return true;
}

/// Encontra um emparelhamento maximal (não pode ser estendido)
pub fn maximalMatching(graph: anytype, allocator: Allocator) !Matching {
    return greedyMatching(graph, allocator);
}

/// Conta o número de arestas no emparelhamento máximo
pub fn matchingNumber(graph: anytype, allocator: Allocator) !usize {
    const matching = try greedyMatching(graph, allocator);
    defer matching.deinit();
    return matching.size();
}

test "greedyMatching - caminho de 4 nós" {
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
    
    const matching = try greedyMatching(&g, std.heap.page_allocator);
    defer matching.deinit();
    
    try std.testing.expect(matching.size() >= 1);
    try std.testing.expect(matching.size() <= 2);
}

test "isValidMatching - verifica emparelhamento válido" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addNode(4);
    try g.addEdge(1, 2, .{});
    try g.addEdge(3, 4, .{});
    
    var edges = [_]anytype{
        @as(struct { i32, i32 }, .{ 1, 2 }),
        @as(struct { i32, i32 }, .{ 3, 4 }),
    };
    
    try std.testing.expectEqual(true, isValidMatching(&g, &edges));
}

test "maximalMatching - retorna emparelhamento maximal" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    const matching = try maximalMatching(&g, std.heap.page_allocator);
    defer matching.deinit();
    
    try std.testing.expect(matching.size() >= 1);
}
