// const std = @import("std");
const std = @import("std");
export var buffer: [4096]u8 = undefined;

extern fn isKeyPressed(key: i32) bool;
extern fn drawRectangle(posX: i32, posY: i32, width: i32, height: i32, color: Color) void;
extern fn getScreenWidth() i32;
extern fn getScreenHeight() i32;
extern fn logToConsole(ptr: [*]const u8, len: u32) void;
extern fn sendNewPosition(dx: f64, dy: f64) void;

fn log(str: []const u8) void {
    // @memcpy(&buffer, str);
    logToConsole(str.ptr, str.len);
}

fn logF64(val: f64) void {
    const str = (std.fmt.bufPrint(&buffer, "{}", .{val})) catch "";
    logToConsole(str.ptr, str.len);
}

fn logI32(val: i32) void {
    const str = (std.fmt.bufPrint(&buffer, "{}", .{val})) catch "";
    logToConsole(str.ptr, str.len);
}

const KeyCode = enum(i32) {
    left = 37,
    up = 38,
    right = 39,
    down = 40,
};
const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,
    _: u8 = 0,
};

const Player = struct {
    id: i32,
    posX: i32,
    posY: i32,
};

var players: [100]Player = undefined;
var playersLen: usize = 0;
fn findPlayer(id: i32) ?*Player {
    var i: usize = 0;
    while (i < playersLen) {
        const player = &players[i];
        if (player.id == id) {
            return player;
        }
        i += 1;
    }

    return null;
}
fn allocatePlayer(id: i32) *Player {
    const player: Player = .{ .id = id, .posX = 0, .posY = 0 };
    players[playersLen] = player;
    playersLen += 1;

    return &players[playersLen - 1];
}

var screenWidth: i32 = 1280;
var screenHeight: i32 = 720;

export fn initGame(width: i32, height: i32) void {
    // screenWidth = width;
    // screenHeight = height;
    _ = width;
    _ = height;
}

var boxWidth: i32 = @divTrunc(1280, 40);
var boxHeight: i32 = @divTrunc(720, 40);

var lastFrame: f64 = 0;

var myId: i32 = -1;
export fn initMyId(id: i32) void {
    myId = id;
}

export fn loop(deltatime: f64) void {
    lastFrame += deltatime;
    if (lastFrame < 16e-3) {
        return;
    }
    lastFrame = 0;
    // if ((lastFrame - deltatime < 16.67) or (lastFrame == 0.0)) {
    //     return;
    // }
    // lastFrame += deltatime;
    // _ = deltatime;

    // screenWidth = getScreenWidth();
    // screenHeight = getScreenHeight();
    // const screenPointX = @divTrunc(screenWidth, 1000);
    // const screenPointY = @divTrunc(screenHeight, 1000);

    const screenPointX = 4;
    const screenPointY = 4;

    drawRectangle(0, 0, screenWidth, screenHeight, .{ .r = 0, .g = 0, .b = 0 });

    const keys = [_]KeyCode{ KeyCode.up, KeyCode.down, KeyCode.left, KeyCode.right };
    keyhandling: for (keys) |key| {
        if (isKeyPressed(@intFromEnum(key))) {
            const player = findPlayer(myId) orelse break :keyhandling;
            const oldX = player.posX;
            const oldY = player.posY;
            switch (key) {
                KeyCode.right => player.posX += screenPointX,
                KeyCode.left => player.posX -= screenPointX,
                KeyCode.up => player.posY -= screenPointY,
                KeyCode.down => player.posY += screenPointY,
            }
            log("Player moving to (x, y):");
            logI32(player.id);
            logI32(player.posX);
            logI32(player.posY);

            const diffX: f64 = @floatFromInt(@abs(oldX - player.posX));
            var dx: f64 = diffX / @as(f64, @floatFromInt(screenWidth));
            const diffY: f64 = @floatFromInt(@abs(oldY - player.posY));
            var dy: f64 = diffY / @as(f64, @floatFromInt(screenHeight));

            if (oldX > player.posX) {
                dx *= -1;
            }
            if (oldY > player.posY) {
                dy *= -1;
            }

            sendNewPosition(dx, dy);
        }
    }

    var i: usize = 0;
    while (i < playersLen) {
        drawRectangle(players[i].posX, players[i].posY, boxWidth, boxHeight, .{ .r = 255, .g = 0, .b = 0 });
        i += 1;
    }
}

export fn updatePosition(id: i32, posX: f64, posY: f64) void {
    const player = findPlayer(id) orelse allocatePlayer(id);
    // log("Updating player with id:");
    // logI32(id);

    const w: f64 = @floatFromInt(screenWidth);
    const h: f64 = @floatFromInt(screenHeight);

    const newX: i32 = @intFromFloat(w * posX);
    const newY: i32 = @intFromFloat(h * posY);

    player.posX = newX;
    player.posY = newY;
}
