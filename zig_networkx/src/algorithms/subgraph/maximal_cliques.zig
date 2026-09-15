// Algoritmo Bron-Kerbosch para encontrar cliques maximais
// Uma clique é um subconjunto de vértices onde todos estão conectados entre si

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Representa uma clique (subconjunto de vértices completamente conectado)
pub const Clique = struct {
    vertices: []anytype,
    
    pub fn deinit(self: *Clique, allocator: Allocator) void {
        allocator.free(self.vertices);
    }
};

/// Estrutura para resultado contendo múltiplas cliques
pub const MaximalCliquesResult = struct {
    cliques: []Clique,
    allocator: Allocator,
    
    pub fn deinit(self: *MaximalCliquesResult) void {
        for (self.cliques) |*clique| {
            clique.deinit(self.allocator);
        }
        self.allocator.free(self.cliques);
    }
};

/// Algoritmo Bron-Kerbosch básico para encontrar todas as cliques maximais
pub fn bronKerbosch(graph: anytype, allocator: Allocator) !MaximalCliquesResult {
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    var result_cliques = std.ArrayList(std.ArrayList(NodeT)).init(allocator);
    errdefer {
        for (result_cliques.items) |*clique| {
            clique.deinit();
        }
        result_cliques.deinit();
    }
    
    var r = std.ArrayList(NodeT).init(allocator); // Clique atual
    defer r.deinit();
    
    var p = std.ArrayList(NodeT).init(allocator); // Candidatos
    defer p.deinit();
    
    var x = std.ArrayList(NodeT).init(allocator); // Já processados
    defer x.deinit();
    
    // Inicializa P com todos os nós
    for (graph.nodes.keys()) |node| {
        try p.append(node);
    }
    
    try bronKerboschRecursive(graph, &r, &p, &x, &result_cliques, allocator);
    
    // Converte para formato de resultado
    const cliques = try allocator.alloc(Clique, result_cliques.items.len);
    errdefer allocator.free(cliques);
    
    for (result_cliques.items, 0..) |clique_list, i| {
        const vertices = try allocator.alloc(anytype, clique_list.items.len);
        errdefer {
            for (cliques[0..i]) |c| {
                allocator.free(c.vertices);
            }
            allocator.free(vertices);
        }
        
        for (clique_list.items, 0..) |node, j| {
            vertices[j] = node;
        }
        
        cliques[i] = Clique{
            .vertices = vertices,
        };
    }
    
    result_cliques.deinit();
    
    return MaximalCliquesResult{
        .cliques = cliques,
        .allocator = allocator,
    };
}

fn bronKerboschRecursive(
    graph: anytype,
    r: *std.ArrayList(anytype),
    p: *std.ArrayList(anytype),
    x: *std.ArrayList(anytype),
    result: *std.ArrayList(std.ArrayList(anytype)),
    allocator: Allocator,
) !void {
    const NodeT = @TypeOf(p.items[0]);
    
    if (p.items.len == 0 and x.items.len == 0) {
        // R é uma clique maximal
        if (r.items.len > 0) {
            var new_clique = std.ArrayList(NodeT).init(allocator);
            try new_clique.ensureTotalCapacity(r.items.len);
            
            for (r.items) |node| {
                new_clique.appendAssumeCapacity(@as(NodeT, @ptrCast(@alignCast(node))));
            }
            
            try result.append(new_clique);
        }
        return;
    }
    
    // Copia P para iterar
    var p_copy = std.ArrayList(NodeT).init(allocator);
    defer p_copy.deinit();
    
    for (p.items) |node| {
        p_copy.appendAssumeCapacity(@as(NodeT, @ptrCast(@alignCast(node))));
    }
    
    for (p_copy.items) |v| {
        // Adiciona v a R
        try r.append(v);
        
        // P' = P ∩ N(v)
        var p_prime = std.ArrayList(NodeT).init(allocator);
        defer p_prime.deinit();
        
        for (p.items) |node| {
            const n = @as(NodeT, @ptrCast(@alignCast(node)));
            if (graph.hasEdge(v, n)) {
                try p_prime.append(n);
            }
        }
        
        // X' = X ∩ N(v)
        var x_prime = std.ArrayList(NodeT).init(allocator);
        defer x_prime.deinit();
        
        for (x.items) |node| {
            const n = @as(NodeT, @ptrCast(@alignCast(node))));
            if (graph.hasEdge(v, n)) {
                try x_prime.append(n);
            }
        }
        
        // Chamada recursiva
        try bronKerboschRecursive(graph, r, @as(*std.ArrayList(anytype), @ptrCast(&p_prime)), 
                                   @as(*std.ArrayList(anytype), @ptrCast(&x_prime)), result, allocator);
        
        // Move v de P para X
        {
            var i: usize = 0;
            while (i < p.items.len) : (i += 1) {
                const n = @as(NodeT, @ptrCast(@alignCast(p.items[i])));
                if (n == v) {
                    _ = p.swapRemove(i);
                    break;
                }
            }
        }
        
        try x.append(v);
        
        // Remove v de R
        _ = r.pop();
    }
}

/// Encontra a maior clique no grafo
pub fn findLargestClique(graph: anytype, allocator: Allocator) !?Clique {
    const result = try bronKerbosch(graph, allocator);
    defer result.deinit();
    
    if (result.cliques.len == 0) {
        return null;
    }
    
    var max_size: usize = 0;
    var max_idx: usize = 0;
    
    for (result.cliques, 0..) |clique, i| {
        if (clique.vertices.len > max_size) {
            max_size = clique.vertices.len;
            max_idx = i;
        }
    }
    
    const largest = result.cliques[max_idx];
    const vertices = try allocator.alloc(anytype, largest.vertices.len);
    for (largest.vertices, 0..) |v, i| {
        vertices[i] = v;
    }
    
    return Clique{
        .vertices = vertices,
    };
}

/// Verifica se um conjunto de vértices forma uma clique
pub fn isClique(graph: anytype, vertices: []const anytype) bool {
    var i: usize = 0;
    while (i < vertices.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < vertices.len) : (j += 1) {
            if (!graph.hasEdge(vertices[i], vertices[j])) {
                return false;
            }
        }
    }
    return true;
}

test "bronKerbosch - triângulo é uma clique" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const result = try bronKerbosch(&g, std.heap.page_allocator);
    defer result.deinit();
    
    try std.testing.expect(result.cliques.len >= 1);
}

test "isClique - verifica clique válida" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    var vertices = [_]anytype{ 1, 2, 3 };
    try std.testing.expectEqual(true, isClique(&g, &vertices));
}

test "isClique - rejeita não-clique" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    // Sem aresta 1-3
    
    var vertices = [_]anytype{ 1, 2, 3 };
    try std.testing.expectEqual(false, isClique(&g, &vertices));
}
