const std = @import("std");

const cubeWidth: f32 = 20.0;
const frameWidth = 160;
const frameHeight = 44;
const distanceFromCamera: f32 = 100.0;
const projectionScale: f32 = 40.0;
const sideResolution: f32 = 0.5;
const yScale: f32 = 0.8;

// Rotation values
var A: f32 = 0.0;
var B: f32 = 0.0;
var C: f32 = 0.0;

var zBuff: [frameWidth * frameHeight]f32 = undefined;
var buff: [frameWidth * frameHeight]u8 = undefined;

const backgroundASCIICode: u8 = ' ';

fn calcX(i: f32, j: f32, k: f32) f32 {
    return j * @sin(A) * @sin(B) * @cos(C)
        - k * @cos(A) * @sin(B) * @cos(C)
        + j * @cos(A) * @sin(C)
        + k * @sin(A) * @sin(C)
        + i * @cos(B) * @cos(C);
}

fn calcY(i: f32, j: f32, k: f32) f32 {
    return j * @cos(A) * @cos(C)
        + k * @sin(A) * @cos(C)
        - j * @sin(A) * @sin(B) * @sin(C)
        + k * @cos(A) * @sin(B) * @sin(C)
        - i * @cos(B) * @sin(C);
}

fn calcZ(i: f32, j: f32, k: f32) f32 {
    return k * @cos(A) * @cos(B)
        - j * @sin(A) * @cos(B)
        + i * @sin(B);
}

// 3D to 2D projection and filling the buffers
fn calculateForSurface(cubeX: f32, cubeY: f32, cubeZ: f32, character: u8) void {
    const x = calcX(cubeX, cubeY, cubeZ);
    const y = calcY(cubeX, cubeY, cubeZ);
    const z = calcZ(cubeX, cubeY, cubeZ) + distanceFromCamera;

    const ooz = 1.0 / z;
    const xf = frameWidth / 2 + projectionScale * ooz * x;
    const yf = frameHeight / 2 + projectionScale * ooz * (y * yScale);

    if (xf < 0 or yf < 0) return;
    if (xf >= @as(f32, @floatFromInt(frameWidth)) or yf >= @as(f32, @floatFromInt(frameHeight))) return;

    const xp: usize = @intFromFloat(xf);
    const yp: usize = @intFromFloat(yf);
    const idx = xp + yp * frameWidth;

    if (idx < zBuff.len and ooz > zBuff[idx]) {
        zBuff[idx] = ooz;
        buff[idx] = character;
    }
}

pub fn main() !void {
    std.debug.print("\x1b[2J\x1b[H\x1b[?25l", .{});

    while (true) {
        // clear buffers
        for (&buff) |*b| b.* = backgroundASCIICode;
        for (&zBuff) |*z| z.* = 0.0;

        // Calculte 6 faces
        var cubeX: f32 = -cubeWidth;
        while (cubeX < cubeWidth) : (cubeX += sideResolution) {
            var cubeY: f32 = -cubeWidth;
            while (cubeY < cubeWidth) : (cubeY += sideResolution) {
                calculateForSurface(cubeX, cubeY, -cubeWidth, '@');
                calculateForSurface(cubeWidth, cubeY, cubeX, '$');
                calculateForSurface(-cubeWidth, cubeY, -cubeX, '-');
                calculateForSurface(-cubeX, cubeY, cubeWidth, '#');
                calculateForSurface(cubeX, -cubeWidth, -cubeY, ';');
                calculateForSurface(cubeX, cubeWidth, cubeY, '+');
            }
        }

        // Hide cursor and draw frame
        std.debug.print("\x1b[H", .{});
        for (buff, 0..) |b, i| {
            if (i % frameWidth == 0) std.debug.print("\n", .{});
            std.debug.print("{c}", .{b});
        }

        // rotation x axis x frame
        A += 0.003;
        B += 0.02;
        C += 0.00;

        std.Thread.sleep(16 * std.time.ns_per_ms);
  }
}
