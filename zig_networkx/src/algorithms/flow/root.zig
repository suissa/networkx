const std = @import("std");

pub const FlowNetwork = @import("max_flow.zig").FlowNetwork;
pub const MaxFlowResult = @import("max_flow.zig").MaxFlowResult;
pub const fordFulkerson = @import("max_flow.zig").fordFulkerson;
pub const edmondsKarp = @import("max_flow.zig").edmondsKarp;
pub const dinic = @import("max_flow.zig").dinic;
pub const minCut = @import("max_flow.zig").minCut;

test {
    std.testing.refAllDecls(@This());
}
