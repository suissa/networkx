// Detecção de ciclos em grafos direcionados
// Algoritmo: DFS com coloração (3 cores)

const std = @import("std");
const Allocator = std.mem.Allocator;
const NetworkXError = @import("../../root.zig").NetworkXError;

const Color = enum(u2) {
    White = 0, // Não visitado
    Gray = 1,  // Em processamento (na pilha atual)
    Black = 2, // Completamente processado
};

/// Verifica se o grafo direcionado possui algum ciclo
pub fn hasDirectedCycle(graph: anytype) bool {
    const NodeT = @TypeOf(graph.nodes);
    const allocator = std.heap.page_allocator;
    
    var colors = std.AutoHashMap(NodeT, Color).init(allocator);
    defer colors.deinit();
    
    // Inicializa todos os nós como brancos
    for (graph.nodes.keys()) |node| {
        colors.put(node, Color.White) catch return false;
    }
    
    // Executa DFS a partir de cada nó não visitado
    for (graph.nodes.keys()) |start_node| {
        if (colors.get(start_node) == Color.White) {
            if (dfsHasCycle(graph, start_node, &colors)) {
                return true;
            }
        }
    }
    
    return false;
}

/// DFS auxiliar para detecção de ciclos
fn dfsHasCycle(graph: anytype, node: anytype, colors: *std.AutoHashMap(anytype, Color)) bool {
    const NodeT = @TypeOf(node);
    
    // Marca como cinza (em processamento)
    colors.put(node, Color.Gray) catch return false;
    
    // Visita todos os vizinhos
    if (graph.adjacency.get(node)) |neighbors| {
        for (neighbors.keys()) |neighbor| {
            const neighbor_color = colors.get(neighbor) orelse Color.White;
            
            if (neighbor_color == Color.Gray) {
                // Encontrou um ancestral na pilha atual = ciclo!
                return true;
            } else if (neighbor_color == Color.White) {
                // Nó não visitado, continua DFS
                if (dfsHasCycle(graph, neighbor, colors)) {
                    return true;
                }
            }
            // Se for preto, já foi processado, ignora
        }
    }
    
    // Marca como preto (completamente processado)
    colors.put(node, Color.Black) catch return false;
    return false;
}

/// Encontra e retorna um ciclo no grafo direcionado, se existir
/// Retorna null se não houver ciclo
pub fn findDirectedCycle(graph: anytype, allocator: Allocator) !?[]anytype {
    const NodeT = @TypeOf(graph.nodes);
    
    var colors = std.AutoHashMap(NodeT, Color).init(allocator);
    defer colors.deinit();
    
    var parent = std.AutoHashMap(NodeT, ?NodeT).init(allocator);
    defer parent.deinit();
    
    // Inicializa
    for (graph.nodes.keys()) |node| {
        try colors.put(node, Color.White);
        try parent.put(node, null);
    }
    
    var cycle_nodes = std.ArrayList(NodeT).init(allocator);
    errdefer cycle_nodes.deinit();
    
    // Executa DFS a partir de cada nó não visitado
    for (graph.nodes.keys()) |start_node| {
        if (colors.get(start_node) == Color.White) {
            if (try dfsFindCycle(graph, start_node, &colors, &parent, &cycle_nodes)) {
                // Converte para array genérico
                const result = try allocator.alloc(anytype, cycle_nodes.items.len);
                for (cycle_nodes.items, 0..) |n, i| {
                    result[i] = n;
                }
                cycle_nodes.deinit();
                return result;
            }
        }
    }
    
    cycle_nodes.deinit();
    return null;
}

/// DFS auxiliar para encontrar ciclo
fn dfsFindCycle(graph: anytype, node: anytype, colors: *std.AutoHashMap(anytype, Color), 
                parent: *std.AutoHashMap(anytype, ?anytype), cycle_nodes: *std.ArrayList(anytype)) !bool {
    const NodeT = @TypeOf(node);
    
    colors.put(node, Color.Gray) catch return false;
    
    if (graph.adjacency.get(node)) |neighbors| {
        for (neighbors.keys()) |neighbor| {
            const neighbor_color = colors.get(neighbor) orelse Color.White;
            
            if (neighbor_color == Color.Gray) {
                // Ciclo encontrado! Reconstrói o caminho
                cycle_nodes.clearRetainingCapacity();
                try cycle_nodes.append(neighbor);
                
                var current = node;
                while (current != neighbor) {
                    try cycle_nodes.append(current);
                    const p = parent.get(current) orelse break;
                    current = p;
                }
                
                // Inverte para ordem correta
                std.mem.reverse(NodeT, cycle_nodes.items);
                return true;
            } else if (neighbor_color == Color.White) {
                try parent.put(neighbor, node);
                if (try dfsFindCycle(graph, neighbor, colors, parent, cycle_nodes)) {
                    return true;
                }
            }
        }
    }
    
    colors.put(node, Color.Black) catch return false;
    return false;
}

test "hasDirectedCycle - grafo sem ciclo" {
    const Graph = @import("../../classes/digraph.zig").DiGraph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    try std.testing.expectEqual(false, hasDirectedCycle(&g));
}

test "hasDirectedCycle - grafo com ciclo" {
    const Graph = @import("../../classes/digraph.zig").DiGraph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    try std.testing.expectEqual(true, hasDirectedCycle(&g));
}

test "findDirectedCycle - encontra ciclo" {
    const Graph = @import("../../classes/digraph.zig").DiGraph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const cycle = try findDirectedCycle(&g, std.heap.page_allocator);
    try std.testing.expect(cycle != null);
    if (cycle) |c| {
        std.heap.page_allocator.free(c);
    }
}

test "findDirectedCycle - sem ciclo retorna null" {
    const Graph = @import("../../classes/digraph.zig").DiGraph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    const cycle = try findDirectedCycle(&g, std.heap.page_allocator);
    try std.testing.expectEqual(@as(?[]anytype, null), cycle);
}
