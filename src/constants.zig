const std = @import("std");

pub const WINDOW_WIDTH = 1280;
pub const WINDOW_HEIGHT = 720;
pub const WINDOW_DIAMETER: u32 = std.math.sqrt(WINDOW_HEIGHT * WINDOW_HEIGHT + WINDOW_WIDTH * WINDOW_WIDTH);
pub const WINDOW_ASPECT = @as(f64, @floatFromInt(WINDOW_WIDTH)) / @as(f64, @floatFromInt(WINDOW_HEIGHT));

pub const WINDOW_W_CENTER = WINDOW_WIDTH / 2;
pub const WINDOW_H_CENTER = WINDOW_HEIGHT / 2;

pub const WINDOW_NAME = "3D";

pub const RADIUS = 2;
pub const DISTANCE = 10;
pub const FRAME_RATE = 20;

pub const PI = 3.14159265359;
// pub const GRAVITY = 9.81;
pub const GRAVITY = 6.674 * std.math.pow(f64, 10, -11);
pub const SINGLE_UNIT_TO_AU = 149_600_000;
