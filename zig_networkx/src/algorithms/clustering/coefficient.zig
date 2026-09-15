// Coeficientes de agrupamento (clustering coefficients)
// Mede o quão conectado estão os vizinhos de um nó

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Calcula o coeficiente de agrupamento local de um nó
/// É a fração de pares de vizinhos que estão conectados entre si
pub fn localClusteringCoefficient(graph: anytype, node: anytype) f64 {
    const neighbors = graph.adjacency.get(node) orelse return 0.0;
    const k = neighbors.count(); // Grau do nó
    
    if (k < 2) return 0.0; // Precisa de pelo menos 2 vizinhos para formar triângulo
    
    // Número máximo possível de arestas entre vizinhos
    const max_edges: f64 = @as(f64, @floatFromInt(k * (k - 1) / 2));
    
    // Conta arestas reais entre vizinhos
    var actual_edges: usize = 0;
    
    var it1 = neighbors.keyIterator();
    while (it1.next()) |neighbor1_ptr| {
        var it2 = neighbors.keyIterator();
        while (it2.next()) |neighbor2_ptr| {
            // Evita contar duas vezes e self-loops
            if (neighbor1_ptr.* >= neighbor2_ptr.*) continue;
            
            // Verifica se neighbor1 e neighbor2 estão conectados
            if (graph.hasEdge(neighbor1_ptr.*, neighbor2_ptr.*)) {
                actual_edges += 1;
            }
        }
    }
    
    const actual: f64 = @as(f64, @floatFromInt(actual_edges));
    return actual / max_edges;
}

/// Calcula o coeficiente de agrupamento médio de todo o grafo
pub fn averageClusteringCoefficient(graph: anytype) f64 {
    if (graph.numberOfNodes() == 0) return 0.0;
    
    var sum: f64 = 0.0;
    
    for (graph.nodes.keys()) |node| {
        sum += localClusteringCoefficient(graph, node);
    }
    
    return sum / @as(f64, @floatFromInt(graph.numberOfNodes()));
}

/// Calcula coeficientes de agrupamento para todos os nós
pub fn clusteringCoefficients(graph: anytype, allocator: Allocator) !std.AutoHashMap(anytype, f64) {
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    var result = std.AutoHashMap(NodeT, f64).init(allocator);
    errdefer result.deinit();
    
    for (graph.nodes.keys()) |node| {
        const coeff = localClusteringCoefficient(graph, node);
        try result.put(node, coeff);
    }
    
    // Converte para tipo genérico
    var generic_result = std.AutoHashMap(anytype, f64).init(allocator);
    errdefer generic_result.deinit();
    
    var it = result.iterator();
    while (it.next()) |entry| {
        try generic_result.put(entry.key_ptr.*, entry.value_ptr.*);
    }
    result.deinit();
    
    return generic_result;
}

/// Calcula o coeficiente de agrupamento global (transitividade)
/// É 3 * número de triângulos / número de tripletas conectadas
pub fn globalClusteringCoefficient(graph: anytype) f64 {
    var triangles: usize = 0;
    var triplets: usize = 0;
    
    for (graph.nodes.keys()) |node| {
        const neighbors = graph.adjacency.get(node) orelse continue;
        const k = neighbors.count();
        
        if (k < 2) continue;
        
        // Conta triângulos envolvendo este nó
        var it1 = neighbors.keyIterator();
        while (it1.next()) |n1_ptr| {
            var it2 = neighbors.keyIterator();
            while (it2.next()) |n2_ptr| {
                if (n1_ptr.* >= n2_ptr.*) continue;
                
                triplets += 1;
                
                if (graph.hasEdge(n1_ptr.*, n2_ptr.*)) {
                    triangles += 1;
                }
            }
        }
    }
    
    if (triplets == 0) return 0.0;
    
    // Cada triângulo é contado 3 vezes (uma para cada vértice)
    // Cada tripleta é contada uma vez
    return @as(f64, @floatFromInt(triangles)) / @as(f64, @floatFromInt(triplets));
}

test "localClusteringCoefficient - triângulo perfeito" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const coeff = localClusteringCoefficient(&g, 1);
    try std.testing.expectEqual(@as(f64, 1.0), coeff);
}

test "localClusteringCoefficient - caminho sem triângulo" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    
    const coeff = localClusteringCoefficient(&g, 2);
    try std.testing.expectEqual(@as(f64, 0.0), coeff);
}

test "averageClusteringCoefficient - triângulo" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const avg = averageClusteringCoefficient(&g);
    try std.testing.expectEqual(@as(f64, 1.0), avg);
}

test "globalClusteringCoefficient - triângulo" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const global = globalClusteringCoefficient(&g);
    try std.testing.expectEqual(@as(f64, 1.0), global);
}

test "clusteringCoefficients - retorna mapa completo" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const coeffs = try clusteringCoefficients(&g, std.heap.page_allocator);
    defer coeffs.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), coeffs.count());
    try std.testing.expect(coeffs.get(1) != null);
}
