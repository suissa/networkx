# Minimum Spanning Tree (MST) - Guia de Uso

## Visão Geral

A biblioteca Zig NetworkX implementa dois algoritmos clássicos para encontrar a Minimum Spanning Tree (MST) de grafos não direcionados ponderados:

- **Kruskal's Algorithm**: Baseado em Union-Find, ideal para grafos esparsos
- **Prim's Algorithm**: Baseado em priority queue, eficiente para grafos densos

## Estrutura Union-Find

A estrutura `UnionFind` é fundamental para o algoritmo de Kruskal e outras aplicações:

```zig
const nx = @import("networkx");

// Criar Union-Find com 10 elementos
var uf = try nx.UnionFind.init(allocator, 10);
defer uf.deinit();

// Operações básicas
uf.union(0, 1);  // Une os conjuntos contendo 0 e 1
const root = uf.find(5);  // Encontra o representante do conjunto de 5
const connected = uf.connected(2, 3);  // Verifica se 2 e 3 estão no mesmo conjunto
const count = uf.getCount();  // Número de conjuntos disjuntos
```

### Complexidade
- **find**: O(α(n)) - quase constante devido à compressão de caminho
- **union**: O(α(n)) - quase constante devido à união por rank
- **connected**: O(α(n))
- α(n) é a função inversa de Ackermann, que cresce extremamente devagar

## Algoritmo de Kruskal

### Uso Básico

```zig
const nx = @import("networkx");

// Criar grafo
var graph = nx.Graph.init(allocator);
defer graph.deinit();

try graph.addEdge(0, 1, 1.0);
try graph.addEdge(1, 2, 2.0);
try graph.addEdge(0, 2, 3.0);
try graph.addEdge(2, 3, 4.0);

// Calcular MST
var result = try nx.kruskalMst(allocator, &graph);
defer result.deinit();

// Acessar resultados
std.debug.print("Total weight: {d}\n", .{result.total_weight});
std.debug.print("Number of edges: {d}\n", .{result.edges.len});

for (result.edges) |edge| {
    std.debug.print("Edge: {d} -- {d} (weight: {d})\n", .{edge.u, edge.v, edge.weight});
}
```

### Minimum Spanning Forest

Para grafos desconectados, use `kruskalMsf` que retorna uma floresta geradora mínima:

```zig
var forest = try nx.kruskalMsf(allocator, &graph);
defer forest.deinit();
```

### Complexidade
- **Tempo**: O(E log E) ou O(E log V), onde E é o número de arestas e V é o número de vértices
- **Espaço**: O(V + E)

## Algoritmo de Prim

### Uso Básico

```zig
const nx = @import("networkx");

// Criar grafo (mesmo exemplo)
var graph = nx.Graph.init(allocator);
defer graph.deinit();

try graph.addEdge(0, 1, 1.0);
try graph.addEdge(1, 2, 2.0);
try graph.addEdge(0, 2, 3.0);
try graph.addEdge(2, 3, 4.0);

// Calcular MST usando Prim
var result = try nx.primMst(allocator, &graph);
defer result.deinit();

// Resultados idênticos ao Kruskal
std.debug.print("Total weight: {d}\n", .{result.total_weight});
```

### Complexidade
- **Tempo**: O(E log V) com binary heap
- **Espaço**: O(V)

## Comparação entre Algoritmos

| Característica | Kruskal | Prim |
|----------------|---------|------|
| Melhor caso | Grafos esparsos (E << V²) | Grafos densos (E ≈ V²) |
| Estrutura principal | Union-Find | Priority Queue |
| Complexidade tempo | O(E log E) | O(E log V) |
| Complexidade espaço | O(V + E) | O(V) |
| Lida com desconexos | Sim (MSF) | Não (precisa de componente conexo) |
| Implementação | Mais simples | Moderada |

## Exemplo Completo

```zig
const std = @import("std");
const nx = @import("networkx");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer gpa.deinit();
    const allocator = gpa.allocator();
    
    // Criar grafo completo K4
    var graph = nx.Graph.init(allocator);
    defer graph.deinit();
    
    // Adicionar todas as arestas de K4 com pesos diferentes
    try graph.addEdge(0, 1, 10.0);
    try graph.addEdge(0, 2, 6.0);
    try graph.addEdge(0, 3, 5.0);
    try graph.addEdge(1, 2, 15.0);
    try graph.addEdge(1, 3, 4.0);
    try graph.addEdge(2, 3, 12.0);
    
    // Usar Kruskal
    var kruskal_result = try nx.kruskalMst(allocator, &graph);
    defer kruskal_result.deinit();
    
    std.debug.print("=== Kruskal MST ===\n", .{});
    std.debug.print("Total weight: {d}\n", .{kruskal_result.total_weight});
    for (kruskal_result.edges) |edge| {
        std.debug.print("{d} -- {d}: {d}\n", .{edge.u, edge.v, edge.weight});
    }
    
    // Usar Prim
    var prim_result = try nx.primMst(allocator, &graph);
    defer prim_result.deinit();
    
    std.debug.print("\n=== Prim MST ===\n", .{});
    std.debug.print("Total weight: {d}\n", .{prim_result.total_weight});
    for (prim_result.edges) |edge| {
        std.debug.print("{d} -- {d}: {d}\n", .{edge.u, edge.v, edge.weight});
    }
}
```

## Casos Especiais

### Grafo Vazio
Ambos os algoritmos retornam MST vazia com peso total 0.

### Nó Único
Retorna MST vazia (sem arestas necessárias).

### Grafo Desconectado
- **Kruskal**: Retorna Minimum Spanning Forest (MST de cada componente)
- **Prim**: Retorna MST do componente conexo contendo o nó inicial

### Arestas com Pesos Negativos
Ambos os algoritmos funcionam corretamente com pesos negativos.

## Dicas de Performance

1. **Grafos Esparsos**: Prefira Kruskal quando E << V²
2. **Grafos Densos**: Prefira Prim quando E ≈ V²
3. **Memória Limitada**: Prim usa menos memória O(V) vs O(V+E)
4. **Grafos Dinâmicos**: Union-Find pode ser reutilizado para operações incrementais

## Erros Comuns

- Esquecer de chamar `deinit()` no resultado (vazamento de memória)
- Usar com `DiGraph` (algoritmos são para grafos não direcionados)
- Esperar árvore única em grafos desconectados (use MSF)
