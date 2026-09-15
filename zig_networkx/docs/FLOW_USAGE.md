# Seção 6 Completa: Algoritmos de Fluxo Máximo ✅

Implementada com sucesso a **Seção 6: Maximum Flow Algorithms** do plano de desenvolvimento.

## 📦 Arquivos Criados

### 1. `src/algorithms/flow/max_flow.zig`
Implementação completa de algoritmos de fluxo máximo em redes:

#### Estruturas Principais:
- **`FlowNetwork(T)`**: Estrutura genérica para representar redes de fluxo
  - Grafo direcionado com capacidades e fluxos
  - Métodos: `addEdge()`, `getCapacity()`, `getFlow()`, `getResidualCapacity()`, `augmentFlow()`
  - Suporte a arestas reversas para algoritmos de fluxo

- **`MaxFlowResult`**: Estrutura para retornar resultados
  - `max_flow`: Valor do fluxo máximo
  - `flow_network`: Rede de fluxo após computação

#### Algoritmos Implementados:

1. **`fordFulkerson()`** - Algoritmo Ford-Fulkerson
   - Complexidade: O(E * max_flow) no pior caso
   - Encontra caminhos aumentantes usando BFS
   - Atualiza fluxos ao longo dos caminhos

2. **`edmondsKarp()`** - Algoritmo Edmonds-Karp
   - Complexidade: O(V * E²)
   - Implementação de Ford-Fulkerson com BFS para caminhos aumentantes
   - Garante terminação em tempo polinomial

3. **`dinic()`** - Algoritmo de Dinic
   - Complexidade: O(V² * E)
   - Usa grafo em camadas (level graph) e caminhos bloqueantes
   - Mais eficiente para grafos grandes

4. **`minCut()`** - Corte Mínimo
   - Encontra o corte mínimo após computar fluxo máximo
   - Retorna nós dos lados S e T
   - Calcula valor do corte

#### Funções Auxiliares:
- `findAugmentingPathBFS()`: Encontra caminho aumentante com BFS
- `dinicDFS()`: DFS para encontrar caminhos bloqueantes no algoritmo de Dinic

### 2. `src/algorithms/flow/root.zig`
Módulo principal que exporta todas as funcionalidades de fluxo:
- Re-exporta `FlowNetwork`, `MaxFlowResult`
- Exporta funções: `fordFulkerson`, `edmondsKarp`, `dinic`, `minCut`
- Inclui testes do módulo

## 🔗 Integração com a Biblioteca

### Atualizações em `src/root.zig`:
```zig
// Novo módulo exportado
pub const flow = @import("algorithms/flow/root.zig");

// Funções re-exportadas
pub const fordFulkerson = flow.fordFulkerson;
pub const edmondsKarp = flow.edmondsKarp;
pub const dinic = flow.dinic;
pub const minCut = flow.minCut;
pub const FlowNetwork = flow.FlowNetwork;
```

## ✨ Features Principais

- ✅ **Suporte a capacidades personalizadas**: Use qualquer tipo numérico (i32, f32, etc.)
- ✅ **Arestas reversas automáticas**: Gerenciamento automático de arestas residuais
- ✅ **Múltiplos algoritmos**: Escolha entre Ford-Fulkerson, Edmonds-Karp ou Dinic
- ✅ **Corte mínimo**: Função para encontrar corte mínimo após fluxo máximo
- ✅ **API consistente**: Segue padrões do NetworkX e da biblioteca Zig
- ✅ **Testes abrangentes**: 4 testes unitários cobrindo casos variados
- ✅ **Nomes mantidos**: Todos os nomes das funções seguem convenções do NetworkX

## 📊 Comparação de Algoritmos

| Algoritmo | Complexidade | Melhor Caso | Uso Recomendado |
|-----------|-------------|-------------|-----------------|
| Ford-Fulkerson | O(E * max_flow) | Grafos pequenos | Simples, fácil implementação |
| Edmonds-Karp | O(V * E²) | Grafos médios | Garantia de tempo polinomial |
| Dinic | O(V² * E) | Grafos grandes | Performance ótima |

## 📝 Exemplo de Uso

```zig
const std = @import("std");
const networkx = @import("networkx");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer gpa.deinit();
    const allocator = gpa.allocator;
    
    // Cria grafo direcionado
    var graph = networkx.DiGraph(i32).init(allocator);
    defer graph.deinit();
    
    // Adiciona arestas com capacidades
    try graph.addEdge(0, 1); // source -> a
    try graph.addEdge(0, 2); // source -> b
    try graph.addEdge(1, 2); // a -> b
    try graph.addEdge(1, 3); // a -> sink
    try graph.addEdge(2, 3); // b -> sink
    
    // Computa fluxo máximo com Edmonds-Karp
    const result = try networkx.edmondsKarp(i32, allocator, &graph, 0, 3);
    defer result.deinit();
    
    std.debug.print("Fluxo máximo: {}\n", .{result.max_flow});
    
    // Também disponível:
    // - networkx.fordFulkerson(...)
    // - networkx.dinic(...)
    // - networkx.minCut(...)
}
```

## 🧪 Testes Implementados

1. **Ford-Fulkerson basic flow**: Grafo simples com múltiplos caminhos
2. **Edmonds-Karp with capacities**: Grafo clássico de exemplo
3. **Dinic algorithm**: Teste com algoritmo de Dinic
4. **Min cut**: Verificação de corte mínimo

## 📚 Próximos Passos

De acordo com o `IMPLEMENTATION_PLAN.md`, a próxima seção a ser implementada é:

### **Seção 7: Algoritmos de Ciclo e Torneio**
- [ ] Detecção de ciclos em grafos direcionados
- [ ] Detecção de ciclos em grafos não direcionados
- [ ] Encontrar ciclos específicos
- [ ] Algoritmos para grafos de torneio
- [ ] Circuitos eulerianos

**Tempo estimado:** 2 semanas

## 🎯 Status do Projeto

| Seção | Status | Descrição |
|-------|--------|-----------|
| 1 | ✅ COMPLETA | Estruturas de Grafos Avançadas (MultiGraph, MultiDiGraph) |
| 2 | ✅ COMPLETA | Caminho Mínimo (Dijkstra, Bellman-Ford, A*, etc.) |
| 3 | ✅ COMPLETA | Métricas de Centralidade (Betweenness, Closeness, Eigenvector, PageRank) |
| 4 | ✅ COMPLETA | Componentes Conexos |
| 5 | ✅ COMPLETA | Árvore Geradora Mínima (Kruskal, Prim) |
| 6 | ✅ COMPLETA | **Fluxo Máximo (Ford-Fulkerson, Edmonds-Karp, Dinic)** |
| 7 | ⏳ PENDENTE | Ciclos e Torneio |
| 8 | ⏳ PENDENTE | Coloração e Agrupamento |
| 9 | ⏳ PENDENTE | Isomorfismo e Subgrafos |
| 10 | ⏳ PENDENTE | Otimizações e Funcionalidades Adicionais |

**Progresso total:** 60% (6 de 10 seções completas)

## 📖 Referências

- NetworkX Python documentation: https://networkx.org/documentation/stable/reference/algorithms/flow.html
- Algoritmo Ford-Fulkerson: https://en.wikipedia.org/wiki/Ford%E2%80%93Fulkerson_algorithm
- Algoritmo Edmonds-Karp: https://en.wikipedia.org/wiki/Edmonds%E2%80%93Karp_algorithm
- Algoritmo de Dinic: https://en.wikipedia.org/wiki/Dinic%27s_algorithm
- Teorema Max-Flow Min-Cut: https://en.wikipedia.org/wiki/Max-flow_min-cut_theorem
