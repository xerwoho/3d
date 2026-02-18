const std = @import("std");

const Constants = @import("constants.zig");
const Structs = @import("structs.zig");
const Vector = Structs.Vector;
const Camera = Structs.Camera;

pub fn normalizeP(v1: Vector) Vector {
    const len = lenP(v1);
    return .{
        .x = v1.x / len,
        .y = v1.y / len,
        .z = v1.z / len,
    };
}

pub fn dotP(v1: Vector, v2: Vector) f64 {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

pub fn singleDotP(v1: Vector) f64 {
    return v1.x + v1.y + v1.z;
}

pub fn lenP(v1: Vector) f64 {
    return std.math.sqrt((v1.x * v1.x) + (v1.y * v1.y) + (v1.z * v1.z));
}

pub fn diffP(v1: Vector, v2: Vector) Vector {
    const n = Vector{
        .x = v2.x - v1.x,
        .y = v2.y - v1.y,
        .z = v2.z - v1.z,
    };

    return n;
}
pub fn distP(v1: Vector, v2: Vector) f64 {
    return lenP(diffP(v1, v2));
}

pub fn crossP(v1: Vector, v2: Vector) Vector {
    const n = Vector{
        .x = (v1.y * v2.z) - (v1.z * v2.y),
        .y = (v1.z * v2.x) - (v1.x * v2.z),
        .z = (v1.x * v2.y) - (v1.y * v2.x),
    };

    return n;
}

pub fn angleP(v1: Vector, v2: Vector) f64 {
    const dot = dotP(v1, v1);
    const theta: f64 = std.math.acos(dot / (lenP(v1) * lenP(v2)));
    return theta;
}

pub fn singleAngleP(v1: Vector, nom: f64) f64 {
    const len = lenP(v1);
    const calced = nom / len;
    const theta: f64 = std.math.acos(calced);
    return theta;
}

pub fn force(
    r: f64,
    m1: f64,
    m2: f64,
) f64 {
    const u: f64 = Constants.GRAVITY * m1 * m2;
    return u / (r * r);
}

pub fn rotateX(point: Vector, pivot: Vector, delta: f64) Vector {
    const v1v2 = diffP(pivot, point);

    const cos_t = std.math.cos(delta);
    const sin_t = std.math.sin(delta);

    const rotated = Vector{
        .x = v1v2.x,
        .y = v1v2.y * cos_t - v1v2.z * sin_t,
        .z = v1v2.y * sin_t + v1v2.z * cos_t,
    };

    return .{
        .x = pivot.x + rotated.x,
        .y = pivot.y + rotated.y,
        .z = pivot.z + rotated.z,
    };
}

pub fn rotateY(point: Vector, pivot: Vector, delta: f64) Vector {
    const v1v2 = diffP(pivot, point);

    const cos_t = std.math.cos(delta);
    const sin_t = std.math.sin(delta);

    const rotated = Vector{
        .x = cos_t * v1v2.x + sin_t * v1v2.z,
        .y = v1v2.y,
        .z = -sin_t * v1v2.x + cos_t * v1v2.z,
    };

    return .{
        .x = pivot.x + rotated.x,
        .y = pivot.y + rotated.y,
        .z = pivot.z + rotated.z,
    };
}

pub fn rotateZ(point: Vector, pivot: Vector, delta: f64) Vector {
    const v1v2 = diffP(pivot, point);

    const cos_t = std.math.cos(delta);
    const sin_t = std.math.sin(delta);

    const rotated = Vector{
        .x = v1v2.x * cos_t - v1v2.y * sin_t,
        .y = v1v2.x * sin_t + v1v2.y * cos_t,
        .z = v1v2.z,
    };

    return .{
        .x = pivot.x + rotated.x,
        .y = pivot.y + rotated.y,
        .z = pivot.z + rotated.z,
    };
}

pub fn rotateAxis(point: Vector, pivot: Vector, angle: f64, tilt: f64) Vector {
    const r = distP(pivot, point);
    const a = angle;
    const t = tilt;

    const v = Vector{
        .x = pivot.x + r * std.math.cos(a),
        .y = pivot.y + r * std.math.sin(a) * std.math.sin(t),
        .z = pivot.z + r * std.math.sin(a) * std.math.cos(t),
    };
    return v;
}

pub fn compute2D(v: Vector, camera: Camera, x_offset: i32, y_offset: i32) struct { x: c_int, y: c_int } {
    const forward = diffP(camera.target, camera.position);
    const yaw = std.math.atan2(forward.x, forward.z);
    const pitch = std.math.atan2(forward.y, std.math.sqrt(forward.x * forward.x + forward.z * forward.z));

    var cv = v;

    // flip the x, and z axis
    // in order to fix the weird
    // distance issue
    cv.x = -v.x;
    cv.z = -v.z;
    // cv.y = v.y;

    const yawed = rotateY(cv, .{}, -yaw);
    const pitched = rotateX(yawed, .{}, -pitch);

    var x = pitched.x;
    var y = pitched.y;

    const distance = distP(v, camera.position);
    const denom = distance + pitched.z;
    if (denom != 0) {
        x *= distance / denom;
        y *= distance / denom;
    }

    y = -y; // needs to be flipped, as in
    // x = -x; // needs to be flipped, as in

    // Get the offsets from the center.
    // (mouse is able to move freely)
    x += @floatFromInt(x_offset);
    y += @floatFromInt(y_offset);

    // The Distance needs to be multiplied,
    // for each vectors x, and y position
    x *= Constants.DISTANCE;
    y *= Constants.DISTANCE;

    // The (0,0,0) point lies in the center of the screen,
    // meaning the variables
    // x => Constants.WINDOW_W_CENTER
    // y => Constants.WINDOW_H_CENTER
    x += Constants.WINDOW_W_CENTER;
    y += Constants.WINDOW_H_CENTER;

    return .{
        .x = @as(c_int, @intFromFloat(x)),
        .y = @as(c_int, @intFromFloat(y)),
    };
}
