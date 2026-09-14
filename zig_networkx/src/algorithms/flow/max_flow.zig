const std = @import("std");
const Allocator = std.mem.Allocator;
const Graph = @import("../../classes/graph.zig").Graph;
const DiGraph = @import("../../classes/digraph.zig").DiGraph;

/// Estrutura para representar uma rede de fluxo
pub fn FlowNetwork(comptime T: type) type {
    return struct {
        const Self = @This();
        
        graph: DiGraph(T),
        capacity: std.AutoHashMap([2]usize, T),
        flow: std.AutoHashMap([2]usize, T),
        allocator: Allocator,
        
        pub fn init(allocator: Allocator) Self {
            return Self{
                .graph = DiGraph(T).init(allocator),
                .capacity = std.AutoHashMap([2]usize, T).init(allocator),
                .flow = std.AutoHashMap([2]usize, T).init(allocator),
                .allocator = allocator,
            };
        }
        
        pub fn deinit(self: *Self) void {
            self.graph.deinit();
            self.capacity.deinit();
            self.flow.deinit();
        }
        
        /// Adiciona uma aresta com capacidade à rede de fluxo
        pub fn addEdge(self: *Self, u: usize, v: usize, capacity: T) !void {
            try self.graph.addEdge(u, v);
            try self.capacity.put(.{ u, v }, capacity);
            try self.flow.put(.{ u, v }, 0);
            
            // Adiciona aresta reversa com capacidade 0 se não existir
            if (!self.graph.hasEdge(v, u)) {
                try self.graph.addEdge(v, u);
                try self.capacity.put(.{ v, u }, 0);
                try self.flow.put(.{ v, u }, 0);
            }
        }
        
        /// Obtém a capacidade de uma aresta
        pub fn getCapacity(self: *Self, u: usize, v: usize) T {
            return self.capacity.get(.{ u, v }) orelse 0;
        }
        
        /// Obtém o fluxo atual de uma aresta
        pub fn getFlow(self: *Self, u: usize, v: usize) T {
            return self.flow.get(.{ u, v }) orelse 0;
        }
        
        /// Calcula a capacidade residual de uma aresta
        pub fn getResidualCapacity(self: *Self, u: usize, v: usize) T {
            const cap = self.getCapacity(u, v);
            const fl = self.getFlow(u, v);
            return cap - fl;
        }
        
        /// Atualiza o fluxo ao longo de um caminho
        pub fn augmentFlow(self: *Self, path: []const usize, bottleneck: T) !void {
            var i: usize = 0;
            while (i < path.len - 1) : (i += 1) {
                const u = path[i];
                const v = path[i + 1];
                
                // Aumenta fluxo na aresta direta
                const current_flow = self.getFlow(u, v);
                try self.flow.put(.{ u, v }, current_flow + bottleneck);
                
                // Diminui fluxo na aresta reversa
                const reverse_flow = self.getFlow(v, u);
                try self.flow.put(.{ v, u }, reverse_flow - bottleneck);
            }
        }
        
        /// Encontra um caminho aumentante usando BFS (Edmonds-Karp)
        pub fn findAugmentingPathBFS(self: *Self, source: usize, sink: usize, visited: *std.BitSet) ?struct {
            path: []usize,
            bottleneck: T,
            buffer: std.ArrayList(usize),
        } {
            var buffer = std.ArrayList(usize).init(self.allocator);
            defer buffer.deinit();
            
            var parent = std.AutoHashMap(usize, ?usize).init(self.allocator);
            defer parent.deinit();
            
            var queue = std.ArrayList(usize).init(self.allocator);
            defer queue.deinit();
            
            try queue.append(source);
            try parent.put(source, null);
            
            var found = false;
            while (queue.items.len > 0 and !found) {
                const u = queue.orderedRemove(0);
                
                if (u == sink) {
                    found = true;
                    break;
                }
                
                const neighbors = self.graph.neighbors(u) catch continue;
                var it = neighbors.iterator();
                while (it.next()) |v_ptr| {
                    const v = v_ptr.*;
                    if (parent.contains(v)) continue;
                    
                    const residual = self.getResidualCapacity(u, v);
                    if (residual <= 0) continue;
                    
                    try parent.put(v, u);
                    try queue.append(v);
                }
            }
            
            if (!parent.contains(sink)) {
                return null;
            }
            
            // Reconstrói o caminho
            buffer.clearRetainingCapacity();
            var current: ?usize = sink;
            while (current) |node| {
                try buffer.append(node);
                current = parent.get(node) orelse break;
            }
            
            // Inverte o caminho
            std.mem.reverse(usize, buffer.items);
            
            // Encontra o bottleneck
            var bottleneck: T = std.math.maxInt(T);
            var i: usize = 0;
            while (i < buffer.items.len - 1) : (i += 1) {
                const u = buffer.items[i];
                const v = buffer.items[i + 1];
                const residual = self.getResidualCapacity(u, v);
                if (residual < bottleneck) {
                    bottleneck = residual;
                }
            }
            
            return .{
                .path = try self.allocator.dupe(usize, buffer.items),
                .bottleneck = bottleneck,
                .buffer = buffer,
            };
        }
    };
}

/// Resultado do algoritmo de fluxo máximo
pub const MaxFlowResult = struct {
    max_flow: anytype,
    flow_network: anytype,
    
    const Self = @This();
    
    pub fn deinit(self: *Self) void {
        self.flow_network.deinit();
    }
};

/// Algoritmo Ford-Fulkerson para fluxo máximo
/// Complexidade: O(E * max_flow) no pior caso
pub fn fordFulkerson(comptime T: type, allocator: Allocator, graph: *DiGraph(T), source: usize, sink: usize) !MaxFlowResult {
    var network = FlowNetwork(T).init(allocator);
    errdefer network.deinit();
    
    // Copia todas as arestas do grafo original para a rede de fluxo
    var nodes = graph.nodes();
    var node_it = nodes.iterator();
    while (node_it.next()) |node_ptr| {
        const u = node_ptr.*;
        const neighbors = graph.neighbors(u) catch continue;
        var neighbor_it = neighbors.iterator();
        while (neighbor_it.next()) |v_ptr| {
            const v = v_ptr.*;
            // Assume capacidade infinita se não especificada, ou usa peso como capacidade
            const weight = graph.getEdgeData(u, v) orelse 1;
            const capacity = if (@TypeOf(weight) == T) weight else @as(T, 1);
            try network.addEdge(u, v, capacity);
        }
    }
    
    var total_flow: T = 0;
    var visited = std.BitSet.initEmpty();
    
    while (true) {
        const result = network.findAugmentingPathBFS(source, sink, &visited) orelse break;
        defer {
            allocator.free(result.path);
            result.buffer.deinit();
        }
        
        try network.augmentFlow(result.path, result.bottleneck);
        total_flow += result.bottleneck;
    }
    
    return MaxFlowResult{
        .max_flow = total_flow,
        .flow_network = network,
    };
}

/// Algoritmo Edmonds-Karp para fluxo máximo (Ford-Fulkerson com BFS)
/// Complexidade: O(V * E²)
pub fn edmondsKarp(comptime T: type, allocator: Allocator, graph: *DiGraph(T), source: usize, sink: usize) !MaxFlowResult {
    // Edmonds-Karp é essencialmente Ford-Fulkerson com BFS para encontrar caminhos aumentantes
    return fordFulkerson(T, allocator, graph, source, sink);
}

/// Algoritmo de Dinic para fluxo máximo
/// Complexidade: O(V² * E)
pub fn dinic(comptime T: type, allocator: Allocator, graph: *DiGraph(T), source: usize, sink: usize) !MaxFlowResult {
    var network = FlowNetwork(T).init(allocator);
    errdefer network.deinit();
    
    // Copia todas as arestas do grafo original
    var nodes = graph.nodes();
    var node_it = nodes.iterator();
    while (node_it.next()) |node_ptr| {
        const u = node_ptr.*;
        const neighbors = graph.neighbors(u) catch continue;
        var neighbor_it = neighbors.iterator();
        while (neighbor_it.next()) |v_ptr| {
            const v = v_ptr.*;
            const weight = graph.getEdgeData(u, v) orelse 1;
            const capacity = if (@TypeOf(weight) == T) weight else @as(T, 1);
            try network.addEdge(u, v, capacity);
        }
    }
    
    var total_flow: T = 0;
    
    while (true) {
        // Constrói o grafo residual em camadas usando BFS
        var level = std.AutoHashMap(usize, usize).init(allocator);
        defer level.deinit();
        
        var queue = std.ArrayList(usize).init(allocator);
        defer queue.deinit();
        
        try level.put(source, 0);
        try queue.append(source);
        
        while (queue.items.len > 0) {
            const u = queue.orderedRemove(0);
            const current_level = level.get(u).?;
            
            const neighbors = network.graph.neighbors(u) catch continue;
            var neighbor_it = neighbors.iterator();
            while (neighbor_it.next()) |v_ptr| {
                const v = v_ptr.*;
                if (level.contains(v)) continue;
                
                const residual = network.getResidualCapacity(u, v);
                if (residual <= 0) continue;
                
                try level.put(v, current_level + 1);
                try queue.append(v);
            }
        }
        
        // Se o sumidouro não é alcançável, terminamos
        if (!level.contains(sink)) break;
        
        // Encontra caminhos bloqueantes usando DFS
        var start_node = std.AutoHashMap(usize, usize).init(allocator);
        defer start_node.deinit();
        
        // Inicializa ponteiros para cada nó
        var node_list = std.ArrayList(usize).init(allocator);
        defer node_list.deinit();
        
        var level_it = level.keyIterator();
        while (level_it.next()) |node_ptr| {
            try node_list.append(node_ptr.*);
            try start_node.put(node_ptr.*, 0);
        }
        
        while (true) {
            const pushed = try dinicDFS(T, &network, source, sink, std.math.maxInt(T), &level, &start_node);
            if (pushed == 0) break;
            total_flow += pushed;
        }
    }
    
    return MaxFlowResult{
        .max_flow = total_flow,
        .flow_network = network,
    };
}

fn dinicDFS(comptime T: type, network: *FlowNetwork(T), u: usize, sink: usize, flow: T, level: *std.AutoHashMap(usize, usize), start_node: *std.AutoHashMap(usize, usize)) !T {
    if (u == sink or flow == 0) return flow;
    
    const neighbors = try network.graph.neighbors(u);
    var neighbor_it = neighbors.iterator();
    
    const current_start = start_node.get(u) orelse 0;
    var pushed: T = 0;
    var count: usize = 0;
    
    while (neighbor_it.next()) |v_ptr| {
        if (count >= current_start) {
            const v = v_ptr.*;
            const u_level = level.get(u) orelse 0;
            const v_level = level.get(v) orelse std.math.maxInt(usize);
            
            if (v_level != u_level + 1) continue;
            
            const residual = network.getResidualCapacity(u, v);
            const can_push = @min(flow - pushed, residual);
            
            if (can_push > 0) {
                const actual_pushed = try dinicDFS(T, network, v, sink, can_push, level, start_node);
                if (actual_pushed > 0) {
                    pushed += actual_pushed;
                    
                    // Atualiza fluxos
                    const current_flow = network.getFlow(u, v);
                    try network.flow.put(.{ u, v }, current_flow + actual_pushed);
                    
                    const reverse_flow = network.getFlow(v, u);
                    try network.flow.put(.{ v, u }, reverse_flow - actual_pushed);
                    
                    if (pushed == flow) break;
                }
            }
        }
        count += 1;
    }
    
    try start_node.put(u, count);
    return pushed;
}

/// Encontra o corte mínimo dado uma rede de fluxo após computar o fluxo máximo
pub fn minCut(allocator: Allocator, network: *FlowNetwork(anytype), source: usize) !struct {
    s_side: std.ArrayList(usize),
    t_side: std.ArrayList(usize),
    cut_value: anytype,
} {
    var s_side = std.ArrayList(usize).init(allocator);
    var t_side = std.ArrayList(usize).init(allocator);
    errdefer {
        s_side.deinit();
        t_side.deinit();
    }
    
    var visited = std.AutoHashMap(usize, void).init(allocator);
    defer visited.deinit();
    
    var queue = std.ArrayList(usize).init(allocator);
    defer queue.deinit();
    
    try queue.append(source);
    try visited.put(source, {});
    
    while (queue.items.len > 0) {
        const u = queue.orderedRemove(0);
        try s_side.append(u);
        
        const neighbors = network.graph.neighbors(u) catch continue;
        var neighbor_it = neighbors.iterator();
        while (neighbor_it.next()) |v_ptr| {
            const v = v_ptr.*;
            if (visited.contains(v)) continue;
            
            const residual = network.getResidualCapacity(u, v);
            if (residual <= 0) continue;
            
            try visited.put(v, {});
            try queue.append(v);
        }
    }
    
    // Todos os nós não visitados estão do lado do sumidouro
    var nodes = network.graph.nodes();
    var node_it = nodes.iterator();
    while (node_it.next()) |node_ptr| {
        const node = node_ptr.*;
        if (!visited.contains(node)) {
            try t_side.append(node);
        }
    }
    
    // Calcula o valor do corte
    var cut_value: @TypeOf(network.getCapacity(0, 0)) = 0;
    for (s_side.items) |u| {
        const neighbors = network.graph.neighbors(u) catch continue;
        var neighbor_it = neighbors.iterator();
        while (neighbor_it.next()) |v_ptr| {
            const v = v_ptr.*;
            if (visited.contains(v)) continue;
            cut_value += network.getCapacity(u, v);
        }
    }
    
    return .{
        .s_side = s_side,
        .t_side = t_side,
        .cut_value = cut_value,
    };
}

test "Ford-Fulkerson basic flow" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var graph = DiGraph(i32).init(allocator);
    defer graph.deinit();
    
    // Grafo simples: s -> a -> t, s -> b -> t
    try graph.addEdge(0, 1); // s -> a
    try graph.addEdge(1, 3); // a -> t
    try graph.addEdge(0, 2); // s -> b
    try graph.addEdge(2, 3); // b -> t
    
    const result = try fordFulkerson(i32, allocator, &graph, 0, 3);
    defer result.deinit();
    
    try testing.expectEqual(@as(i32, 2), result.max_flow);
}

test "Edmonds-Karp with capacities" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var graph = DiGraph(i32).init(allocator);
    defer graph.deinit();
    
    // Grafo clássico de exemplo
    try graph.addEdge(0, 1);
    try graph.addEdge(0, 2);
    try graph.addEdge(1, 2);
    try graph.addEdge(1, 3);
    try graph.addEdge(2, 3);
    
    const result = try edmondsKarp(i32, allocator, &graph, 0, 3);
    defer result.deinit();
    
    try testing.expect(result.max_flow > 0);
}

test "Dinic algorithm" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var graph = DiGraph(i32).init(allocator);
    defer graph.deinit();
    
    try graph.addEdge(0, 1);
    try graph.addEdge(0, 2);
    try graph.addEdge(1, 3);
    try graph.addEdge(2, 3);
    
    const result = try dinic(i32, allocator, &graph, 0, 3);
    defer result.deinit();
    
    try testing.expect(result.max_flow > 0);
}

test "Min cut" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var network = FlowNetwork(i32).init(allocator);
    defer network.deinit();
    
    try network.addEdge(0, 1, 10);
    try network.addEdge(0, 2, 5);
    try network.addEdge(1, 3, 5);
    try network.addEdge(2, 3, 10);
    
    // Primeiro computa fluxo máximo
    _ = try fordFulkerson(i32, allocator, &network.graph, 0, 3);
    
    const cut = try minCut(allocator, &network, 0);
    defer {
        cut.s_side.deinit();
        cut.t_side.deinit();
    }
    
    try testing.expect(cut.s_side.items.len > 0);
    try testing.expect(cut.t_side.items.len > 0);
    try testing.expect(cut.cut_value > 0);
}
