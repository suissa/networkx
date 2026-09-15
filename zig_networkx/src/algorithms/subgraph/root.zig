// Módulo principal para algoritmos de subgrafos

const std = @import("std");

pub const maximal_cliques = @import("maximal_cliques.zig");
pub const matching = @import("matching.zig");
pub const induced_subgraph = @import("induced_subgraph.zig");

// Re-export types and functions
pub const Clique = maximal_cliques.Clique;
pub const MaximalCliquesResult = maximal_cliques.MaximalCliquesResult;
pub const Matching = matching.Matching;

// Maximal cliques functions
pub const bronKerbosch = maximal_cliques.bronKerbosch;
pub const findLargestClique = maximal_cliques.findLargestClique;
pub const isClique = maximal_cliques.isClique;

// Matching functions
pub const greedyMatching = matching.greedyMatching;
pub const isValidMatching = matching.isValidMatching;
pub const maximalMatching = matching.maximalMatching;
pub const matchingNumber = matching.matchingNumber;

// Subgraph operations
pub const inducedSubgraph = induced_subgraph.inducedSubgraph;
pub const edgeSubgraph = induced_subgraph.edgeSubgraph;
pub const copyGraph = induced_subgraph.copyGraph;
pub const complement = induced_subgraph.complement;

test {
    _ = @import("maximal_cliques.zig");
    _ = @import("matching.zig");
    _ = @import("induced_subgraph.zig");
}
