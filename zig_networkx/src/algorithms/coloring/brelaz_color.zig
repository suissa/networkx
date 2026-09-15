// Algoritmo DSatur (Brelaz) para coloração de grafos
// Mais preciso que a coloração gulosa simples

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Resultado da coloração DSatur
pub const DSaturResult = struct {
    colors: std.AutoHashMap(anytype, usize),
    num_colors: usize,
    
    pub fn deinit(self: *DSaturResult) void {
        self.colors.deinit();
    }
};

/// Grau de saturação de um nó (número de cores diferentes nos vizinhos)
fn saturationDegree(graph: anytype, node: anytype, colors: anytype) usize {
    var neighbor_colors = std.AutoHashMap(usize, void).init(std.heap.page_allocator);
    defer neighbor_colors.deinit();
    
    if (graph.adjacency.get(node)) |neighbors| {
        var it = neighbors.keyIterator();
        while (it.next()) |neighbor_ptr| {
            if (colors.get(neighbor_ptr.*)) |color| {
                neighbor_colors.put(color, {}) catch continue;
            }
        }
    }
    
    return neighbor_colors.count();
}

/// Aplica algoritmo DSatur (Brelaz) ao grafo
/// Escolhe sempre o nó com maior grau de saturação
pub fn brelazColor(graph: anytype, allocator: Allocator) !DSaturResult {
    const NodeT = @TypeOf(graph.nodes.keys()[0]);
    
    var colors = std.AutoHashMap(NodeT, usize).init(allocator);
    errdefer colors.deinit();
    
    var colored = std.AutoHashMap(NodeT, bool).init(allocator);
    defer colored.deinit();
    
    // Inicializa todos como não coloridos
    for (graph.nodes.keys()) |node| {
        try colored.put(node, false);
    }
    
    var num_colored: usize = 0;
    var num_colors: usize = 0;
    
    // Começa pelo nó de maior grau
    var start_node: ?NodeT = null;
    var max_degree: usize = 0;
    
    for (graph.nodes.keys()) |node| {
        const degree = graph.degree(node) catch continue;
        if (degree > max_degree) {
            max_degree = degree;
            start_node = node;
        }
    }
    
    if (start_node) |node| {
        try colors.put(node, 0);
        try colored.put(node, true);
        num_colored = 1;
        num_colors = 1;
    }
    
    // Enquanto houver nós não coloridos
    while (num_colored < graph.numberOfNodes()) {
        // Encontra nó não colorido com maior grau de saturação
        var best_node: ?NodeT = null;
        var best_saturation: usize = 0;
        var best_degree: usize = 0;
        
        for (graph.nodes.keys()) |node| {
            if (colored.get(node) == true) continue;
            
            const saturation = saturationDegree(graph, node, colors);
            const degree = graph.degree(node) catch continue;
            
            if (best_node == null or 
                saturation > best_saturation or
                (saturation == best_saturation and degree > best_degree)) {
                best_node = node;
                best_saturation = saturation;
                best_degree = degree;
            }
        }
        
        if (best_node == null) break;
        
        // Encontra menor cor disponível
        var neighbor_colors = std.AutoHashMap(usize, void).init(allocator);
        defer neighbor_colors.deinit();
        
        if (graph.adjacency.get(best_node.?)) |neighbors| {
            var it = neighbors.keyIterator();
            while (it.next()) |neighbor_ptr| {
                if (colors.get(neighbor_ptr.*)) |color| {
                    try neighbor_colors.put(color, {});
                }
            }
        }
        
        var color: usize = 0;
        while (neighbor_colors.contains(color)) : (color += 1) {}
        
        try colors.put(best_node.?, color);
        try colored.put(best_node.?, true);
        num_colored += 1;
        
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
    
    return DSaturResult{
        .colors = generic_colors,
        .num_colors = num_colors,
    };
}

test "brelazColor - triângulo precisa 3 cores" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addEdge(1, 2, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(3, 1, .{});
    
    const result = try brelazColor(&g, std.heap.page_allocator);
    defer result.deinit();
    
    try std.testing.expectEqual(@as(usize, 3), result.num_colors);
}

test "brelazColor - caminho bipartido precisa 2 cores" {
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
    
    const result = try brelazColor(&g, std.heap.page_allocator);
    defer result.deinit();
    
    try std.testing.expectEqual(@as(usize, 2), result.num_colors);
}

test "brelazColor - grafo completo K4 precisa 4 cores" {
    const Graph = @import("../../classes/graph.zig").Graph;
    var g = Graph.init(std.heap.page_allocator);
    defer g.deinit();
    
    try g.addNode(1);
    try g.addNode(2);
    try g.addNode(3);
    try g.addNode(4);
    try g.addEdge(1, 2, .{});
    try g.addEdge(1, 3, .{});
    try g.addEdge(1, 4, .{});
    try g.addEdge(2, 3, .{});
    try g.addEdge(2, 4, .{});
    try g.addEdge(3, 4, .{});
    
    const result = try brelazColor(&g, std.heap.page_allocator);
    defer result.deinit();
    
    try std.testing.expectEqual(@as(usize, 4), result.num_colors);
}
