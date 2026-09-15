// Detecção de ciclos em grafos não direcionados
// Algoritmo: DFS com rastreamento do nó pai

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Verifica se o grafo não direcionado possui algum ciclo
pub fn hasUndirectedCycle(graph: anytype) bool {
    const NodeT = @TypeOf(graph.nodes);
    const allocator = std.heap.page_allocator;
    
    var visited = std.AutoHashMap(NodeT, bool).init(allocator);
    defer visited.deinit();
    
    // Inicializa todos os nós como não visitados
    for (graph.nodes.keys()) |node| {
        visited.put(node, false) catch return false;
    }
    
    // Executa DFS a partir de cada componente conexo
    for (graph.nodes.keys()) |start_node| {
        if (!visited.get(start_node)) {
            if (dfsHasCycle(graph, start_node, null, &visited)) {
                return true;
            }
        }
    }
    
    return false;
}

/// DFS auxiliar para detecção de ciclos em grafos não direcionados
fn dfsHasCycle(graph: anytype, node: anytype, parent: ?anytype, visited: *std.AutoHashMap(anytype, bool)) bool {
    const NodeT = @TypeOf(node);
    
    visited.put(node, true) catch return false;
    
    // Visita todos os vizinhos
    if (graph.adjacency.get(node)) |neighbors| {
        for (neighbors.keys()) |neighbor| {
            const is_visited = visited.get(neighbor) orelse false;
            
            if (!is_visited) {
                // Nó não visitado, continua DFS
                if (dfsHasCycle(graph, neighbor, node, visited)) {
                    return true;
                }
            } else if (parent != null and neighbor != parent.?) {
                // Visitado e não é o pai = ciclo encontrado!
                return true;
            }
        }
    }
    
    return false;
}

/// Encontra e retorna um ciclo no grafo não direcionado, se existir
/// Retorna null se não houver ciclo
pub fn findUndirectedCycle(graph: anytype, allocator: Allocator) !?[]anytype {
    const NodeT = @TypeOf(graph.nodes);
    
    var visited = std.AutoHashMap(NodeT, bool).init(allocator);
    defer visited.deinit();
    
    var parent = std.AutoHashMap(NodeT, ?NodeT).init(allocator);
    defer parent.deinit();
    
    // Inicializa
    for (graph.nodes.keys()) |node| {
        try visited.put(node, false);
        try parent.put(node, null);
    }
    
    var cycle_result = std.ArrayList(NodeT).init(allocator);
    errdefer cycle_result.deinit();
    
    // Executa DFS a partir de cada componente conexo
    for (graph.nodes.keys()) |start_node| {
        if (!visited.get(start_node)) {
            if (try dfsFindCycle(graph, start_node, null, &visited, &parent, &cycle_result)) {
                // Converte para array genérico
                const result = try allocator.alloc(anytype, cycle_result.items.len);
                for (cycle_result.items, 0..) |n, i| {
                    result[i] = n;
                }
                cycle_result.deinit();
                return result;
            }
        }
    }
    
    cycle_result.deinit();
    return null;
}

/// DFS auxiliar para encontrar ciclo
fn dfsFindCycle(graph: anytype, node: anytype, parent_node: ?anytype, 
                visited: *std.AutoHashMap(anytype, bool),
                parent: *std.AutoHashMap(anytype, ?anytype),
                cycle_result: *std.ArrayList(anytype)) !bool {
    const NodeT = @TypeOf(node);
    
    visited.put(node, true) catch return false;
    try parent.put(node, parent_node);
    
    if (graph.adjacency.get(node)) |neighbors| {
        for (neighbors.keys()) |neighbor| {
            const is_visited = visited.get(neighbor) orelse false;
            
            if (!is_visited) {
                if (try dfsFindCycle(graph, neighbor, node, visited, parent, cycle_result)) {
                    return true;
                }
            } else if (parent_node != null and neighbor != parent_node.?) {
                // Ciclo encontrado! Reconstrói o caminho
                cycle_result.clearRetainingCapacity();
                try cycle_result.append(neighbor);
                
                var current = node;
                while (current != neighbor) {
                    try cycle_result.append(current);
                    const p = parent.get(current) orelse break;
                    if (p == null) break;
                    current = p.?;
                }
                
                return true;
            }
        }
    }
    
    return false;
}

test "hasUndirectedCycle - grafo sem ciclo (árvore)" {
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
    
    try std.testing.expectEqual(false, hasUndirectedCycle(&g));
}

test "hasUndirectedCycle - grafo com ciclo" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    try std.testing.expectEqual(true, hasUndirectedCycle(&g));
}

test "findUndirectedCycle - encontra ciclo" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const cycle = try findUndirectedCycle(&g, std.heap.page_allocator);
    try std.testing.expect(cycle != null);
    if (cycle) |c| {
        std.heap.page_allocator.free(c);
    }
}

test "findUndirectedCycle - sem ciclo retorna null" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    const cycle = try findUndirectedCycle(&g, std.heap.page_allocator);
    try std.testing.expectEqual(@as(?[]anytype, null), cycle);
}
