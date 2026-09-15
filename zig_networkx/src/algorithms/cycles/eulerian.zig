// Algoritmos para circuitos e caminhos eulerianos
// Algoritmo de Hierholzer para encontrar circuitos eulerianos

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Verifica se o grafo é euleriano (possui circuito euleriano)
/// Um grafo é euleriano se todos os vértices têm grau par e é conexo
pub fn isEulerian(graph: anytype) bool {
    if (graph.numberOfNodes() == 0) return false;
    
    // Verifica se todos os nós têm grau par
    for (graph.nodes.keys()) |node| {
        const degree = graph.degree(node) catch return false;
        if (degree % 2 != 0) {
            return false;
        }
    }
    
    // Verifica conectividade (todos os nós com arestas devem estar na mesma componente)
    var visited = std.AutoHashMap(@TypeOf(graph.nodes.keys()[0]), bool).init(std.heap.page_allocator);
    defer visited.deinit();
    
    // Conta nós com grau > 0
    var nodes_with_edges: usize = 0;
    var start_node: ?@TypeOf(graph.nodes.keys()[0]) = null;
    
    for (graph.nodes.keys()) |node| {
        const degree = graph.degree(node) catch return false;
        if (degree > 0) {
            nodes_with_edges += 1;
            if (start_node == null) {
                start_node = node;
            }
        }
    }
    
    if (nodes_with_edges == 0) return true; // Grafo sem arestas é trivialmente euleriano
    
    // DFS para verificar conectividade
    var stack = std.ArrayList(@TypeOf(graph.nodes.keys()[0])).init(std.heap.page_allocator);
    defer stack.deinit();
    
    try stack.append(start_node.?);
    visited.put(start_node.?, true) catch return false;
    
    var visited_count: usize = 1;
    
    while (stack.popOrNull()) |node| {
        if (graph.adjacency.get(node)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |neighbor_ptr| {
                if (!visited.get(neighbor_ptr.*)) {
                    visited.put(neighbor_ptr.*, true) catch return false;
                    visited_count += 1;
                    stack.append(neighbor_ptr.*) catch return false;
                }
            }
        }
    }
    
    return visited_count == nodes_with_edges;
}

/// Verifica se o grafo possui caminho euleriano (mas não necessariamente circuito)
/// Um grafo tem caminho euleriano se tiver 0 ou 2 vértices de grau ímpar
pub fn hasEulerianPath(graph: anytype) bool {
    if (graph.numberOfNodes() == 0) return false;
    
    var odd_degree_count: usize = 0;
    
    for (graph.nodes.keys()) |node| {
        const degree = graph.degree(node) catch return false;
        if (degree % 2 != 0) {
            odd_degree_count += 1;
        }
    }
    
    // 0 ou 2 vértices de grau ímpar
    return odd_degree_count == 0 or odd_degree_count == 2;
}

/// Encontra um circuito euleriano no grafo
/// Retorna null se o grafo não for euleriano
pub fn eulerianCircuit(graph: anytype, allocator: Allocator) !?[]anytype {
    if (!isEulerian(graph)) {
        return null;
    }
    
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    // Copia das arestas para remoção durante o algoritmo
    var edge_multiset = std.AutoHashMap(NodeT, std.ArrayList(NodeT)).init(allocator);
    defer {
        var it = edge_multiset.valueIterator();
        while (it.next()) |list| {
            list.deinit();
        }
        edge_multiset.deinit();
    }
    
    // Constrói multiconjunto de arestas
    for (graph.nodes.keys()) |node| {
        const list = try allocator.alloc(NodeT, 0);
        var edges = std.ArrayList(NodeT).fromList(list);
        
        if (graph.adjacency.get(node)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |neighbor_ptr| {
                try edges.append(neighbor_ptr.*);
            }
        }
        
        try edge_multiset.put(node, edges);
    }
    
    var circuit = std.ArrayList(NodeT).init(allocator);
    errdefer circuit.deinit();
    
    var stack = std.ArrayList(NodeT).init(allocator);
    defer stack.deinit();
    
    // Começa do primeiro nó com arestas
    var start_node: ?NodeT = null;
    for (graph.nodes.keys()) |node| {
        const degree = graph.degree(node) catch continue;
        if (degree > 0) {
            start_node = node;
            break;
        }
    }
    
    if (start_node == null) {
        circuit.deinit();
        return null;
    }
    
    try stack.append(start_node.?);
    
    while (stack.items.len > 0) {
        const current = stack.items[stack.items.len - 1];
        
        var has_edge = false;
        if (edge_multiset.get(current)) |edges| {
            if (edges.items.len > 0) {
                has_edge = true;
                const next_node = edges.pop();
                
                // Remove aresta reversa também
                if (edge_multiset.get(next_node)) |rev_edges| {
                    var i: usize = 0;
                    while (i < rev_edges.items.len) : (i += 1) {
                        if (rev_edges.items[i] == current) {
                            _ = rev_edges.orderedRemove(i);
                            break;
                        }
                    }
                }
                
                try stack.append(next_node);
            }
        }
        
        if (!has_edge) {
            try circuit.append(stack.pop());
        }
    }
    
    // Inverte o circuito para ordem correta
    std.mem.reverse(NodeT, circuit.items);
    
    const result = try allocator.alloc(anytype, circuit.items.len);
    for (circuit.items, 0..) |n, i| {
        result[i] = n;
    }
    circuit.deinit();
    
    return result;
}

/// Encontra um caminho euleriano no grafo
/// Retorna null se o grafo não tiver caminho euleriano
pub fn eulerianPath(graph: anytype, allocator: Allocator) !?[]anytype {
    if (!hasEulerianPath(graph)) {
        return null;
    }
    
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    // Encontra nó de início apropriado
    var start_node: ?NodeT = null;
    var odd_degree_nodes = std.ArrayList(NodeT).init(allocator);
    defer odd_degree_nodes.deinit();
    
    for (graph.nodes.keys()) |node| {
        const degree = graph.degree(node) catch continue;
        if (degree % 2 != 0) {
            try odd_degree_nodes.append(node);
        }
    }
    
    // Se houver 2 nós de grau ímpar, começa em um deles
    if (odd_degree_nodes.items.len == 2) {
        start_node = odd_degree_nodes.items[0];
    } else {
        // Todos graus pares, começa em qualquer nó com arestas
        for (graph.nodes.keys()) |node| {
            const degree = graph.degree(node) catch continue;
            if (degree > 0) {
                start_node = node;
                break;
            }
        }
    }
    
    if (start_node == null) {
        return null;
    }
    
    // Usa algoritmo similar ao circuito euleriano
    var edge_multiset = std.AutoHashMap(NodeT, std.ArrayList(NodeT)).init(allocator);
    defer {
        var it = edge_multiset.valueIterator();
        while (it.next()) |list| {
            list.deinit();
        }
        edge_multiset.deinit();
    }
    
    for (graph.nodes.keys()) |node| {
        const list = try allocator.alloc(NodeT, 0);
        var edges = std.ArrayList(NodeT).fromList(list);
        
        if (graph.adjacency.get(node)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |neighbor_ptr| {
                try edges.append(neighbor_ptr.*);
            }
        }
        
        try edge_multiset.put(node, edges);
    }
    
    var path = std.ArrayList(NodeT).init(allocator);
    errdefer path.deinit();
    
    var stack = std.ArrayList(NodeT).init(allocator);
    defer stack.deinit();
    
    try stack.append(start_node.?);
    
    while (stack.items.len > 0) {
        const current = stack.items[stack.items.len - 1];
        
        var has_edge = false;
        if (edge_multiset.get(current)) |edges| {
            if (edges.items.len > 0) {
                has_edge = true;
                const next_node = edges.pop();
                
                // Remove aresta reversa também
                if (edge_multiset.get(next_node)) |rev_edges| {
                    var i: usize = 0;
                    while (i < rev_edges.items.len) : (i += 1) {
                        if (rev_edges.items[i] == current) {
                            _ = rev_edges.orderedRemove(i);
                            break;
                        }
                    }
                }
                
                try stack.append(next_node);
            }
        }
        
        if (!has_edge) {
            try path.append(stack.pop());
        }
    }
    
    std.mem.reverse(NodeT, path.items);
    
    const result = try allocator.alloc(anytype, path.items.len);
    for (path.items, 0..) |n, i| {
        result[i] = n;
    }
    path.deinit();
    
    return result;
}

test "isEulerian - triângulo é euleriano" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    try std.testing.expectEqual(true, isEulerian(&g));
}

test "isEulerian - caminho não é euleriano" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    try std.testing.expectEqual(false, isEulerian(&g));
}

test "hasEulerianPath - caminho tem caminho euleriano" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    try std.testing.expectEqual(true, hasEulerianPath(&g));
}

test "eulerianCircuit - encontra circuito" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const circuit = try eulerianCircuit(&g, std.heap.page_allocator);
    try std.testing.expect(circuit != null);
    if (circuit) |c| {
        std.heap.page_allocator.free(c);
    }
}
