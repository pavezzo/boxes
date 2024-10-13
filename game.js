"use strict";

let app = document.getElementById("app");
let ctx = app.getContext("2d");
let wasm = null;
let buffer = null;
var memory = new WebAssembly.Memory({
    // See build.zig for reasoning
    initial: 2 /* pages */,
    maximum: 2 /* pages */,
});

function logToConsole(ptr, len) {
    const slice = new Uint8Array(memory.buffer, ptr, len);
    const text = new TextDecoder().decode(slice);
    console.log(text);
}

function drawRectangle(x, y, w, h, color) {
    let red = (color>>(0*8))&0xFF;
    let green = (color>>(1*8))&0xFF;
    let blue = (color>>(2*8))&0xFF;

    ctx.fillStyle = "rgb(" + red + "," + green + "," + blue + ")";
    ctx.fillRect(x, y, w, h);
}

let canvas = document.getElementById('app'); 
function getScreenWidth() {
    return canvas.getBoundingClientRect().width;
}
function getScreenHeight() {
    return canvas.getBoundingClientRect().height;
}


let upPressed = false;
let downPressed = false;
let leftPressed = false;
let rightPressed = false;

document.addEventListener('keydown', (e) => {
    let keycode = e.keyCode;

    if (keycode === 37) {
        leftPressed = true;
    } else if (keycode === 38) {
        upPressed = true;
    } else if (keycode === 39) {
        rightPressed = true;
    } else if (keycode === 40) {
        downPressed = true;
    }
});

document.addEventListener('keyup', (e) => {
    let keycode = e.keyCode;

    if (keycode === 37) {
        leftPressed = false;
    } else if (keycode === 38) {
        upPressed = false;
    } else if (keycode === 39) {
        rightPressed = false;
    } else if (keycode === 40) {
        downPressed = false;
    }
});


function isKeyPressed(keycode) {
    if (keycode === 37) {
        return leftPressed;
    } else if (keycode === 38) {
        return upPressed;
    } else if (keycode === 39) {
        return rightPressed;
    } else if (keycode === 40) {
        return downPressed;
    }
    return false;
}

let prev = null;
let initializedId = false;
function loop(timestamp) {
    if (prev !== null) {
        wasm.instance.exports.loop((timestamp - prev)*0.001);
    }
    if (!initializedId && myId !== null) {
        wasm.instance.exports.initMyId(myId);
        initializedId = true;
    }
    prev = timestamp;
    window.requestAnimationFrame(loop);
}

WebAssembly.instantiateStreaming(fetch("game.wasm"), {
    env: {
        drawRectangle,
        isKeyPressed,
        getScreenWidth,
        getScreenHeight,
        logToConsole,
        sendNewPosition,
        memory,
    }
}).then((w) => {
    wasm = w;
    //buffer = wasm.instance.exports.memory.buffer;
    wasm.instance.exports.initGame(getScreenWidth(), getScreenHeight());

    window.requestAnimationFrame(loop);
});


/// WEBSOCKETS ///

let ws;
let myId = null;

function connectWebSocket() {
    //ws = new WebSocket(`ws://${window.location.hostname}:5001`);
    ws = new WebSocket(`ws://joakimjoensuu.fi:5001`);

    ws.onopen = () => {
        //document.getElementById('status').innerText = "Connected to WebSocket.";
        console.log("connected");
    };

    ws.onclose = () => {
        console.log("connected");
        //document.getElementById('status').innerText = "Disconnected from WebSocket.";
    };

    ws.onerror = (error) => {
        console.error("WebSocket Error: ", error);
    };

    ws.onmessage = (event) => {
        console.log("called");
        const data = JSON.parse(event.data);
        const positions = data["positions"];
        if (myId === null) {
            const id = data["my_id"];
            myId = id;
        }
        console.log(Object.keys(positions));
        console.log(myId);
        for (const client in positions) {
            if (wasm !== null) {
                wasm.instance.exports.updatePosition(client, positions[client].x, positions[client].y);
            }
        }
    };
}

function sendNewPosition(dx, dy) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        console.log("called");
        const packet = {
            dx: dx,
            dy: dy,
        }
        const json = JSON.stringify(packet);
        console.log(json);
        ws.send(json);
    }
}

connectWebSocket(); // Initiate WebSocket connection when the page loads

// Send position updates to the server every second
//setInterval(() => {
//    if (ws && ws.readyState === WebSocket.OPEN) {
//        const movement = {
//            dx: Math.random() * 0.1 - 0.05,  // Random movement between -0.05 and 0.05
//            dy: Math.random() * 0.1 - 0.05   // Random movement between -0.05 and 0.05
//        };
//        ws.send(JSON.stringify(movement));
//    }
//}, 50);
//
