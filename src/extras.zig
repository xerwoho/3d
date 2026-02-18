const std = @import("std");

const Math = @import("math.zig");

const Structs = @import("structs.zig");
const Camera = Structs.Camera;
const Vector = Structs.Vector;

const DistVector = struct {
    v: Vector,
    d: f64,
};

fn descByDistance(_: void, a: DistVector, b: DistVector) bool {
    return a.d > b.d; // descending
}

pub fn sortVectors(camera: Camera, vs: []Vector) ![]Vector {
    const allocator = std.heap.page_allocator;
    var v_dists = try allocator.alloc(DistVector, vs.len);
    defer allocator.free(v_dists);

    for (vs, 0..) |*v, i| {
        const dist = Math.distP(v.*, camera.position);
        v.distance = dist;

        v_dists[i] = DistVector{
            .v = v.*,
            .d = dist,
        };
    }

    var sorted_vs = try allocator.alloc(Vector, vs.len);
    std.mem.sort(DistVector, v_dists, {}, descByDistance);
    for (v_dists, 0..) |v, i| {
        sorted_vs[i] = v.v;
        sorted_vs[i].distance = v.d;
    }

    return sorted_vs;
}
