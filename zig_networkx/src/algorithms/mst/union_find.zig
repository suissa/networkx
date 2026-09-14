//! Union-Find (Disjoint Set Union) data structure with path compression and union by rank.
//! This is a fundamental data structure used in Kruskal's algorithm and other graph algorithms.

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Union-Find data structure for efficient disjoint set operations.
pub const UnionFind = struct {
    parent: []usize,
    rank: []usize,
    count: usize,
    allocator: Allocator,

    /// Initialize a new Union-Find structure with n elements.
    pub fn init(allocator: Allocator, n: usize) !UnionFind {
        const parent = try allocator.alloc(usize, n);
        errdefer allocator.free(parent);
        
        const rank = try allocator.alloc(usize, n);
        errdefer allocator.free(rank);
        
        // Initially, each element is its own parent
        for (0..n) |i| {
            parent[i] = i;
            rank[i] = 0;
        }
        
        return UnionFind{
            .parent = parent,
            .rank = rank,
            .count = n,
            .allocator = allocator,
        };
    }

    /// Free all allocated memory.
    pub fn deinit(self: *UnionFind) void {
        self.allocator.free(self.parent);
        self.allocator.free(self.rank);
    }

    /// Find the representative (root) of the set containing element x.
    /// Uses path compression for optimization.
    pub fn find(self: *UnionFind, x: usize) usize {
        if (self.parent[x] != x) {
            // Path compression: make all nodes on path point directly to root
            self.parent[x] = self.find(self.parent[x]);
        }
        return self.parent[x];
    }

    /// Union the sets containing elements x and y.
    /// Uses union by rank for optimization.
    pub fn union(self: *UnionFind, x: usize, y: usize) void {
        const root_x = self.find(x);
        const root_y = self.find(y);
        
        if (root_x == root_y) return; // Already in same set
        
        // Union by rank: attach smaller tree under larger tree
        if (self.rank[root_x] < self.rank[root_y]) {
            self.parent[root_x] = root_y;
        } else if (self.rank[root_x] > self.rank[root_y]) {
            self.parent[root_y] = root_x;
        } else {
            self.parent[root_y] = root_x;
            self.rank[root_x] += 1;
        }
        
        self.count -= 1;
    }

    /// Check if two elements are in the same set.
    pub fn connected(self: *UnionFind, x: usize, y: usize) bool {
        return self.find(x) == self.find(y);
    }

    /// Get the number of disjoint sets.
    pub fn getCount(self: *UnionFind) usize {
        return self.count;
    }
};

test "UnionFind basic operations" {
    const allocator = std.testing.allocator;
    
    var uf = try UnionFind.init(allocator, 5);
    defer uf.deinit();
    
    // Initially all elements are separate
    try std.testing.expectEqual(@as(usize, 5), uf.getCount());
    
    // Union some elements
    uf.union(0, 1);
    try std.testing.expectEqual(@as(usize, 4), uf.getCount());
    try std.testing.expect(uf.connected(0, 1));
    try std.testing.expect(!uf.connected(0, 2));
    
    uf.union(2, 3);
    try std.testing.expectEqual(@as(usize, 3), uf.getCount());
    
    uf.union(1, 3);
    try std.testing.expectEqual(@as(usize, 2), uf.getCount());
    try std.testing.expect(uf.connected(0, 2));
    try std.testing.expect(uf.connected(1, 3));
}

test "UnionFind path compression" {
    const allocator = std.testing.allocator;
    
    var uf = try UnionFind.init(allocator, 10);
    defer uf.deinit();
    
    // Create a chain: 0-1-2-3-4-5-6-7-8-9
    for (0..9) |i| {
        uf.union(i, i + 1);
    }
    
    // All should be connected
    for (0..10) |i| {
        for (0..10) |j| {
            try std.testing.expect(uf.connected(i, j));
        }
    }
    
    try std.testing.expectEqual(@as(usize, 1), uf.getCount());
}
