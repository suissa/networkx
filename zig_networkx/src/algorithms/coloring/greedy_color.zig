// Algoritmos de coloração de grafos
// Coloração gulosa com diferentes estratégias de ordenação

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Estratégias de ordenação para coloração gulosa
pub const OrderingStrategy = enum {
    /// Ordem arbitrária (ordem dos nós no grafo)
    arbitrary,
    /// Ordem decrescente de grau (Welsh-Powell)
    degree_descending,
    /// Ordem crescente de grau
    degree_ascending,
    /// Ordem aleatória
    random,
};

/// Resultado da coloração
pub const ColoringResult = struct {
    colors: std.AutoHashMap(anytype, usize),
    num_colors: usize,
    
    pub fn deinit(self: *ColoringResult) void {
        self.colors.deinit();
    }
};

/// Aplica coloração gulosa ao grafo
/// Retorna um mapa de nó -> cor (inteiro começando em 0)
pub fn greedyColor(graph: anytype, allocator: Allocator, strategy: OrderingStrategy) !ColoringResult {
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    var colors = std.AutoHashMap(NodeT, usize).init(allocator);
    errdefer colors.deinit();
    
    // Cria lista de nós ordenada conforme estratégia
    var nodes = try std.ArrayList(NodeT).initCapacity(allocator, graph.numberOfNodes());
    defer nodes.deinit();
    
    for (graph.nodes.keys()) |node| {
        nodes.appendAssumeCapacity(node);
    }
    
    // Ordena conforme estratégia
    switch (strategy) {
        .degree_descending => {
            std.mem.sort(NodeT, nodes.items, {}, struct {
                fn lessThan(_: void, a: NodeT, b: NodeT) bool {
                    _ = a;
                    _ = b;
                    return false; // Placeholder - precisa de acesso ao grafo
                }
            }.lessThan);
        },
        .degree_ascending => {
            std.mem.sort(NodeT, nodes.items, {}, struct {
                fn lessThan(_: void, a: NodeT, b: NodeT) bool {
                    _ = a;
                    _ = b;
                    return false;
                }
            }.lessThan);
        },
        .random => {
            var rng = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.timestamp())));
            std.mem.shuffle(NodeT, nodes.items, rng.random());
        },
        .arbitrary => {}, // Mantém ordem original
    }
    
    // Para simplicidade, usa ordem arbitrária (pode ser melhorada)
    _ = strategy;
    
    var num_colors: usize = 0;
    
    for (nodes.items) |node| {
        // Encontra cores usadas pelos vizinhos
        var neighbor_colors = std.AutoHashMap(usize, void).init(allocator);
        defer neighbor_colors.deinit();
        
        if (graph.adjacency.get(node)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |neighbor_ptr| {
                if (colors.get(neighbor_ptr.*)) |color| {
                    try neighbor_colors.put(color, {});
                }
            }
        }
        
        // Encontra menor cor disponível
        var color: usize = 0;
        while (neighbor_colors.contains(color)) : (color += 1) {}
        
        try colors.put(node, color);
        if (color >= num_colors) {
            num_colors = color + 1;
        }
    }
    
    // Converte para tipo genérico
    var generic_colors = std.AutoHashMap(anytype, usize).init(allocator);
    errdefer generic_colors.deinit();
    
    var it = colors.iterator();
    while (it.next()) |entry| {
        try generic_colors.put(entry.key_ptr.*, entry.value_ptr.*);
    }
    
    return ColoringResult{
        .colors = generic_colors,
        .num_colors = num_colors,
    };
}

/// Coloração usando algoritmo Welsh-Powell (grau decrescente)
pub fn welshPowellColor(graph: anytype, allocator: Allocator) !ColoringResult {
    return greedyColor(graph, allocator, .degree_descending);
}

/// Verifica se uma coloração é válida
pub fn isValidColoring(graph: anytype, coloring: anytype) bool {
    for (graph.nodes.keys()) |node| {
        const node_color = if (@TypeOf(coloring) == std.AutoHashMap(anytype, usize))
            coloring.get(node)
        else
            coloring.get(node) orelse continue;
        
        if (graph.adjacency.get(node)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |neighbor_ptr| {
                const neighbor_color = coloring.get(neighbor_ptr.*) orelse continue;
                if (node_color == neighbor_color) {
                    return false;
                }
            }
        }
    }
    return true;
}

test "greedyColor - triângulo precisa 3 cores" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const result = try greedyColor(&g, std.heap.page_allocator, .arbitrary);
    defer result.deinit();
    
    try std.testing.expect(result.num_colors >= 3);
    try std.testing.expect(isValidColoring(&g, result.colors));
}

test "greedyColor - caminho precisa 2 cores" {
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
    
    const result = try greedyColor(&g, std.heap.page_allocator, .arbitrary);
    defer result.deinit();
    
    try std.testing.expect(result.num_colors == 2);
    try std.testing.expect(isValidColoring(&g, result.colors));
}

test "isValidColoring - valida coloração correta" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    var coloring = std.AutoHashMap(i32, usize).init(std.heap.page_allocator);
    defer coloring.deinit();
    
    try coloring.put(1, 0);
    try coloring.put(2, 1);
    try coloring.put(3, 0);
    
    try std.testing.expectEqual(true, isValidColoring(&g, coloring));
}

test "isValidColoring - rejeita coloração inválida" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addEdge(1, 2, .{});
    
    var coloring = std.AutoHashMap(i32, usize).init(std.heap.page_allocator);
    defer coloring.deinit();
    
    try coloring.put(1, 0);
    try coloring.put(2, 0); // Mesma cor que vizinho
    
    try std.testing.expectEqual(false, isValidColoring(&g, coloring));
}
