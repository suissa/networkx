// Módulo principal para algoritmos de ciclos

const std = @import("std");

pub const directed_cycle = @import("directed_cycle.zig");
pub const undirected_cycle = @import("undirected_cycle.zig");
pub const eulerian = @import("eulerian.zig");

// Re-export functions for convenience
pub const hasDirectedCycle = directed_cycle.hasDirectedCycle;
pub const findDirectedCycle = directed_cycle.findDirectedCycle;
pub const hasUndirectedCycle = undirected_cycle.hasUndirectedCycle;
pub const findUndirectedCycle = undirected_cycle.findUndirectedCycle;
pub const isEulerian = eulerian.isEulerian;
pub const hasEulerianPath = eulerian.hasEulerianPath;
pub const eulerianCircuit = eulerian.eulerianCircuit;
pub const eulerianPath = eulerian.eulerianPath;

test {
    _ = @import("directed_cycle.zig");
    _ = @import("undirected_cycle.zig");
    _ = @import("eulerian.zig");
}
