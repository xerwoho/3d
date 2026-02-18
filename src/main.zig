const rl = @import("raylib.zig");
const raylib = rl.raylib;

const std = @import("std");

const Constants = @import("constants.zig");
const Structs = @import("structs.zig");
const Math = @import("math.zig");
const Extras = @import("extras.zig");

var Y_OFFSET: i32 = 0;
var X_OFFSET: i32 = 0;

var PREV_Y_OFFSET: ?i32 = null;
var PREV_X_OFFSET: ?i32 = null;

var MOUSE_CLICKED_X: ?i32 = null;
var MOUSE_CLICKED_Y: ?i32 = null;

pub fn main() !void {
    raylib.SetConfigFlags(raylib.FLAG_WINDOW_RESIZABLE);
    raylib.SetTargetFPS(Constants.FRAME_RATE);

    raylib.InitWindow(Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT, Constants.WINDOW_NAME);

    const allocator = std.heap.page_allocator;
    var vectors = try std.ArrayList(Structs.Vector).initCapacity(allocator, 200);
    defer vectors.deinit(allocator);
    var edges = try std.ArrayList(Structs.Edge).initCapacity(allocator, 50);
    defer edges.deinit(allocator);
    var planets = try std.ArrayList(Structs.Planet).initCapacity(allocator, 50);
    defer planets.deinit(allocator);

    const nullpoint: Structs.Vector = .{};
    try vectors.append(allocator, nullpoint);

    try createGraph(100, &vectors);
    try createSquare(nullpoint, 5.0, &edges);
    try createSolarSystem(&vectors, &planets);

    var sun: ?Structs.Planet = null;
    for (planets.items) |p| {
        if (!std.mem.eql(u8, p.name, "Sun")) continue;
        sun = p;
        break;
    }

    var a_sun = sun orelse return error.NoSun;
    const sun_vector = a_sun.getPlanet(vectors.items);

    var camera = Structs.Camera{
        .position = .{
            .x = 30,
            .y = 17,
            .z = 34,
        },
        .target = .{},
    };

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();

        const camera_t = try std.fmt.allocPrint(
            allocator,
            "({d}, {d}, {d})",
            .{
                camera.position.x,
                camera.position.y,
                camera.position.z,
            },
        );
        defer allocator.free(camera_t);
        raylib.DrawText(camera_t.ptr, 10, 10, 30, raylib.BLACK);

        for (edges.items) |*edge| {
            const v1_computed = Math.compute2D(
                edge.v1,
                camera,
                X_OFFSET,
                Y_OFFSET,
            );
            const v2_computed = Math.compute2D(
                edge.v2,
                camera,
                X_OFFSET,
                Y_OFFSET,
            );
            raylib.DrawLine(
                v1_computed.x,
                v1_computed.y,
                v2_computed.x,
                v2_computed.y,
                edge.color,
            );
        }

        const sorted_vectors = try Extras.sortVectors(camera, vectors.items);
        const smallest_distance = Math.distP(sorted_vectors[0], camera.position);
        const largest_distance = Math.distP(sorted_vectors[sorted_vectors.len - 1], camera.position);
        for (sorted_vectors) |vector| {
            const dist = Math.distP(camera.position, vector);
            //              48   -      47            /     57            -        47
            //          =        1                    /                 10
            const n = (dist - smallest_distance) / (largest_distance - smallest_distance);

            const computed = Math.compute2D(
                vector,
                camera,
                X_OFFSET,
                Y_OFFSET,
            );

            raylib.DrawCircle(
                computed.x,
                computed.y,
                @floatCast(vector.radius * n),
                vector.color,
            );
        }

        for (planets.items) |*p| {
            if (std.mem.eql(u8, p.name, "Sun")) continue;

            const planet_vector = p.getPlanet(vectors.items);
            const computed = Math.compute2D(
                planet_vector,
                camera,
                X_OFFSET,
                Y_OFFSET,
            );

            const name = p.name;
            raylib.DrawText(
                name.ptr,
                computed.x,
                computed.y - 100,
                10,
                planet_vector.color,
            );

            const dist = Math.distP(planet_vector, sun_vector);
            const r = dist * Constants.SINGLE_UNIT_TO_AU;
            const v = std.math.sqrt(Constants.GRAVITY * a_sun.mass / r);
            const speed = v / Constants.SINGLE_UNIT_TO_AU;

            const rotated = Math.rotateY(
                planet_vector,
                sun_vector,
                speed * 20,
            );
            vectors.items[p.planet_index].x = rotated.x;
            vectors.items[p.planet_index].y = rotated.y;
            vectors.items[p.planet_index].z = rotated.z;
        }

        if (raylib.IsMouseButtonDown(raylib.MOUSE_BUTTON_LEFT)) {
            const x = raylib.GetMouseX();
            const y = raylib.GetMouseY();
            if (MOUSE_CLICKED_X == null) MOUSE_CLICKED_X = @intCast(x);
            if (MOUSE_CLICKED_Y == null) MOUSE_CLICKED_Y = @intCast(y);

            var y_temp: f64 = @floatFromInt(@as(i32, @intCast(y)) - MOUSE_CLICKED_Y.?);
            y_temp *= 0.05;
            Y_OFFSET = @intFromFloat(y_temp);

            if (PREV_Y_OFFSET) |p| Y_OFFSET += p;
            var x_temp: f64 = @floatFromInt(@as(i32, @intCast(x)) - MOUSE_CLICKED_X.?);
            x_temp *= 0.05;
            X_OFFSET = @intFromFloat(x_temp);
            if (PREV_X_OFFSET) |p| X_OFFSET += p;
        }

        if (raylib.IsMouseButtonReleased(raylib.MOUSE_BUTTON_LEFT)) {
            MOUSE_CLICKED_X = null;
            MOUSE_CLICKED_Y = null;

            PREV_Y_OFFSET = Y_OFFSET;
            PREV_X_OFFSET = X_OFFSET;
        }

        if (raylib.IsKeyDown(raylib.KEY_UP)) {
            const n = Math.rotateX(camera.position, camera.target, 0.05);
            camera.position.x = n.x;
            camera.position.y = n.y;
            camera.position.z = n.z;
        }
        if (raylib.IsKeyDown(raylib.KEY_DOWN)) {
            const n = Math.rotateX(camera.position, camera.target, -0.05);
            camera.position.x = n.x;
            camera.position.y = n.y;
            camera.position.z = n.z;
        }
        if (raylib.IsKeyDown(raylib.KEY_RIGHT)) {
            const n = Math.rotateY(camera.position, camera.target, -0.05);
            camera.position.x = n.x;
            camera.position.y = n.y;
            camera.position.z = n.z;
        }
        if (raylib.IsKeyDown(raylib.KEY_LEFT)) {
            const n = Math.rotateY(camera.position, camera.target, 0.05);
            camera.position.x = n.x;
            camera.position.y = n.y;
            camera.position.z = n.z;
        }

        const wheel = raylib.GetMouseWheelMove();
        if (wheel != 0) {
            const minimized = 1 + ((-wheel) / 30);
            camera.zoom(minimized);
        }

        raylib.ClearBackground(raylib.WHITE);
        raylib.EndDrawing();
    }

    raylib.CloseWindow();
}

fn createSquare(
    center: Structs.Vector,
    width: f64,
    main_edges: *std.ArrayList(Structs.Edge),
) !void {
    const allocator = std.heap.page_allocator;
    const y = 0.0;

    const points = [_]Structs.Vector{
        .{ .x = center.x - width, .y = y, .z = center.z - width },
        .{ .x = center.x + width, .y = y, .z = center.z - width },
        .{ .x = center.x + width, .y = y, .z = center.z + width },
        .{ .x = center.x - width, .y = y, .z = center.z + width },
    };

    const colors = [_]raylib.Color{
        raylib.GRAY,
        raylib.BLACK,
        raylib.BROWN,
        raylib.LIGHTGRAY,
    };

    for (0..4) |i| {
        try main_edges.append(allocator, .{
            .color = colors[i],
            .v1 = points[i],
            .v2 = points[(i + 1) % 4],
        });
    }
}

fn createGraph(size: comptime_int, main_vectors: *std.ArrayList(Structs.Vector)) !void {
    const allocator = std.heap.page_allocator;

    const colors = [_]raylib.Color{
        raylib.GREEN,
        raylib.BLUE,
        raylib.RED,
    };

    for (0..3) |axis| {
        for (0..size) |i| {
            var v = Structs.Vector{
                .color = colors[axis],
                .radius = Constants.RADIUS,
            };

            const value = @as(f64, @floatFromInt(i)) - @as(f64, @floatFromInt(size / 2));

            switch (axis) {
                0 => v.x = value,
                1 => v.y = value,
                2 => v.z = value,
                else => unreachable,
            }

            try main_vectors.append(allocator, v);
        }
    }
}

fn createSolarSystem(
    vectors: *std.ArrayList(Structs.Vector),
    planets: *std.ArrayList(Structs.Planet),
) !void {
    _ = try createPlanet(
        0,
        raylib.YELLOW,
        1.989 * std.math.pow(f64, 10, 30),
        696342,
        250,
        7.0,
        "Sun",
        vectors,
        planets,
    );

    _ = try createPlanet(
        5.79 * std.math.pow(f64, 10, 8),
        raylib.RED,
        3.285 * std.math.pow(f64, 10, 23),
        2439.7,
        47.36,
        0.034,
        "Mercury",
        vectors,
        planets,
    );

    _ = try createPlanet(
        1.08 * std.math.pow(f64, 10, 9),
        raylib.LIGHTGRAY,
        4.867 * std.math.pow(f64, 10, 24),
        6051.8,
        35,
        2.64,
        "Venus",
        vectors,
        planets,
    );

    _ = try createPlanet(
        1.496 * std.math.pow(f64, 10, 9),
        raylib.BLUE,
        5.97 * std.math.pow(f64, 10, 24),
        6371,
        29.78,
        23.4,
        "Earth",
        vectors,
        planets,
    );

    _ = try createPlanet(
        2.28 * std.math.pow(f64, 10, 9),
        raylib.DARKPURPLE,
        6.39 * std.math.pow(f64, 10, 23),
        3389.5,
        24,
        25.0,
        "Mars",
        vectors,
        planets,
    );

    _ = try createPlanet(
        7.78 * std.math.pow(f64, 10, 9),
        raylib.BROWN,
        1.89813 * std.math.pow(f64, 10, 27),
        69911,
        59.5,
        3.13,
        "Jupiter",
        vectors,
        planets,
    );

    _ = try createPlanet(
        1.43 * std.math.pow(f64, 10, 10),
        raylib.BEIGE,
        5.683 * std.math.pow(f64, 10, 26),
        58232,
        9.87,
        27.0,
        "Saturn",
        vectors,
        planets,
    );
}

fn createPlanet(
    // from sun
    distance: f64,
    color: raylib.Color,
    mass: f64,
    radius: f64,
    velocity: f64,
    tilt: f64,

    // name of the planet
    name: []const u8,
    main_vectors: *std.ArrayList(Structs.Vector),
    main_planets: *std.ArrayList(Structs.Planet),
) !Structs.Planet {
    const allocator = std.heap.page_allocator;
    const planet_index = main_vectors.items.len;

    const vector = Structs.Vector{
        .x = distance / Constants.SINGLE_UNIT_TO_AU,
        .y = 0,
        .radius = std.math.log10(radius) * 3,
        .color = color,
    };

    try main_vectors.append(allocator, vector);

    const p = Structs.Planet.init(
        planet_index,
        mass,
        radius,
        velocity,
        tilt,
        name,
    );
    try main_planets.append(allocator, p);
    return p;
}

fn createAtom(
    pos: Structs.Vector,
    pos_electrons: []Structs.Vector,
    main_vectors: *std.ArrayList(Structs.Vector),
    main_atoms: *std.ArrayList(Structs.Atom),
) !void {
    const allocator = std.heap.page_allocator;
    const atom_index = main_vectors.items.len;
    try main_vectors.append(allocator, pos);

    const electrons = try allocator.alloc(Structs.Electron, pos_electrons.len);
    for (pos_electrons, 0..) |pe, i| {
        const electron_index = main_vectors.items.len;

        var rel = Math.diffP(pe, pos);
        rel.color = pe.color;
        rel.radius = pe.radius;

        try main_vectors.append(allocator, rel);
        const electron = Structs.Electron.init(electron_index);

        electrons[i] = electron;
    }

    const a = Structs.Atom{
        .atom_index = atom_index,
        .electrons = electrons,
    };
    try main_atoms.append(allocator, a);
}
