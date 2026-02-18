const std = @import("std");
const rl = @import("raylib.zig");
const raylib = rl.raylib;

const Constants = @import("constants.zig");

pub const Camera = struct {
    position: Vector,
    target: Vector,

    pub fn init(v1: Vector, v2: Vector) Camera {
        return .{
            .position = v1,
            .target = v2,
        };
    }

    pub fn zoom(
        self: *Camera,
        z: f64,
    ) void {
        const v = self.position;

        self.position.x = v.x * z;
        self.position.y = v.y * z;
        self.position.z = v.z * z;
    }
};

pub const Vector = struct {
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,
    distance: f64 = 0,
    color: raylib.Color = raylib.WHITE,
    radius: f64 = Constants.RADIUS,

    pub fn init(
        x: f64,
        y: f64,
        z: f64,
        color: raylib.Color,
    ) Vector {
        return .{
            .x = x,
            .y = y,
            .z = z,
            .color = color,
        };
    }

    pub fn move(self: *Vector, x: f64, y: f64, z: f64) void {
        self.x = x;
        self.y = y;
        self.z = z;
    }
};

pub const Edge = struct {
    v1: Vector,
    v2: Vector,
    color: raylib.Color,

    pub fn init(
        v1: Vector,
        v2: Vector,
        color: raylib.Color,
    ) Vector {
        return .{
            .v1 = v1,
            .v2 = v2,
            .color = color,
        };
    }
};

pub const Planet = struct {
    planet_index: usize,
    mass: f64, // kg
    radius: f64, // km
    velocity: f64, // km/s
    tilt: f64, // degrees

    angle: f64 = 0, // current orbital angle
    speed: f64 = 0.02, // angular speed

    g: f64, // m/s^2

    name: []const u8,

    pub fn init(
        planet_index: usize,
        mass: f64,
        radius: f64,
        velocity: f64,
        tilt: f64,
        name: []const u8,
    ) Planet {
        const g: f64 = (Constants.GRAVITY * mass) / (radius * radius);

        return .{
            .planet_index = planet_index,
            .mass = mass,
            .velocity = velocity,
            .radius = radius,
            .tilt = tilt,
            .g = g,
            .name = name,
        };
    }

    pub fn getPlanet(self: *Planet, vs: []Vector) Vector {
        return vs[self.planet_index];
    }
};

// pub const Electron = struct {
//     electron_index: usize,
//     m: u8 = 0,

//     angle: f64 = 0, // current orbital angle
//     tilt: f64 = 0.5, // tilt of the orbital plane
//     speed: f64 = 0.02, // angular speed
//     radius: f64 = 2, // orbital radius

//     pub fn init(electron_index: usize) Electron {
//         var prng = std.Random.DefaultPrng.init(std.crypto.random.int(u64)); // single PRNG

//         const tilt = prng.random().float(f64);
//         const speed = prng.random().float(f64);
//         const radius = prng.random().float(f64);

//         return .{
//             .electron_index = electron_index,
//             .tilt = tilt,
//             .speed = speed * 0.1,
//             .radius = radius * 10,
//         };
//     }

//     pub fn getElectron(self: *Electron, vs: []Vector) Vector {
//         return vs[self.electron_index];
//     }
// };

// pub const Atom = struct {
//     atom_index: usize,
//     electrons: []Electron,

//     n: u8 = 0, // size of the wave function
//     // aka its energy level
//     //
//     l: u8 = 0, // angular momentum of the orbital => If an orbital has no angular momentum, it behvaes in a spherical way
//     // affects the orbital shape of the function
//     //
//     m: u8 = 0, // orientation / rotation, or simply the spin

//     // radial nodes = n - l - 1
//     // angular nodes = l

//     pub fn init(v: Vector) Atom {
//         return .{
//             .v = v,
//         };
//     }

//     pub fn getAtom(self: *Atom, vs: []Vector) Vector {
//         return vs[self.atom_index];
//     }

//     pub fn getElectrons(self: *Atom, vs: []Vector) []Vector {
//         const allocator = std.heap.page_allocator;
//         const electrons = try allocator.alloc(Electron, self.electrons.len);
//         for (self.electrons, 0..) |e, i| {
//             electrons[i] = e.getElectron(vs);
//         }

//         return electrons;
//     }
// };
