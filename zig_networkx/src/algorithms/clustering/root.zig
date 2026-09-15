// Módulo principal para algoritmos de clustering

const std = @import("std");

pub const coefficient = @import("coefficient.zig");

// Re-export functions for convenience
pub const localClusteringCoefficient = coefficient.localClusteringCoefficient;
pub const averageClusteringCoefficient = coefficient.averageClusteringCoefficient;
pub const clusteringCoefficients = coefficient.clusteringCoefficients;
pub const globalClusteringCoefficient = coefficient.globalClusteringCoefficient;

test {
    _ = @import("coefficient.zig");
}
