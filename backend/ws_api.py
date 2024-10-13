import asyncio
import json
import math
import random
import socket
import traceback

import psutil
import websockets

clients = {}
client_id_to_number = {}

counter = 0


def get_local_ip():
    for interface, addrs in psutil.net_if_addrs().items():
        for addr in addrs:
            if addr.family == socket.AF_INET and not addr.address.startswith(
                "127."
            ):
                return addr.address
    raise Exception("No valid IP address found")


CLIENT_SIZE = 0.05
HALF_CLIENT_SIZE = CLIENT_SIZE / 2


def normalize_vector(x, y):
    length = math.sqrt(x**2 + y**2)
    if length == 0:
        return 0, 0
    return x / length, y / length


def random_unit_vector():
    angle = random.uniform(0, 2 * math.pi)
    return math.cos(angle), math.sin(angle)


def resolve_collision(x1, y1, x2, y2):
    if x1 == x2 and y1 == y2:
        direction_x, direction_y = random_unit_vector()
    else:
        direction_x, direction_y = normalize_vector(x2 - x1, y2 - y1)

    move_distance = CLIENT_SIZE
    new_x = x2 + direction_x * move_distance
    new_y = y2 + direction_y * move_distance

    # Clamp new position within [0, 1] boundaries
    new_x = clamp_position(new_x)
    new_y = clamp_position(new_y)

    return new_x, new_y


def clamp_position(position):
    return max(0, min(1, position))


def is_colliding(client1, client2):
    """Check if two clients are colliding based on their positions and size."""
    return (
        abs(client1["x"] - client2["x"]) < CLIENT_SIZE
        and abs(client1["y"] - client2["y"]) < CLIENT_SIZE
    )


def move_client(client_id, dx, dy, clients):
    """Move the client with the given id and resolve any collisions with other clients."""
    # Step 1: Move the given client
    client = clients[client_id]
    new_x = clamp_position(client["x"] + dx)
    new_y = clamp_position(client["y"] + dy)

    # Update the moving client's position
    clients[client_id]["x"] = new_x
    clients[client_id]["y"] = new_y

    # Step 2: Check for collisions and resolve them
    resolved_clients = set()

    def resolve_chain_collisions(client_id):
        for other_id, other_client in clients.items():
            if other_id != client_id and is_colliding(
                clients[client_id], other_client
            ):
                if other_id not in resolved_clients:
                    resolved_clients.add(other_id)
                    new_other_x, new_other_y = resolve_collision(
                        clients[client_id]["x"],
                        clients[client_id]["y"],
                        other_client["x"],
                        other_client["y"],
                    )
                    # Update the other client's position
                    clients[other_id]["x"] = new_other_x
                    clients[other_id]["y"] = new_other_y

                    # Recursively resolve collisions for the other client
                    resolve_chain_collisions(other_id)

    # Initial call to resolve collisions for the moved client
    resolve_chain_collisions(client_id)

    return clients


async def websocket_handler(websocket, path):
    global clients
    global counter

    client_id = f"{websocket.remote_address}"
    client_number = counter
    counter += 1

    client_id_to_number[client_id] = client_number

    # Store the WebSocket object and initial client position
    clients[client_number] = {"ws": websocket, "x": 0.5, "y": 0.5}

    move_client(client_number, 0, 0, clients)

    await broadcast_positions(clients)

    try:
        while True:
            data = await websocket.recv()

            movement = json.loads(data)

            move_client(client_number, movement["dx"], movement["dy"], clients)

            # Broadcast the updated positions to all clients
            await broadcast_positions(clients)
    except websockets.exceptions.ConnectionClosedOK:
        del clients[client_number]
        del client_id_to_number[client_id]
        print(f"Client {client_id} {client_number} disconnected")
        return
    except BaseException as e:
        print(f"Error handling message: {e}")
        traceback.print_exc()
    print("Dunno what happened")


async def broadcast_positions(clients):
    positions = {
        client_id: {
            key: value for key, value in client_info.items() if key != "ws"
        }
        for client_id, client_info in clients.items()
    }

    # Broadcast to all connected clients
    for client_number, client_info in clients.items():
        websocket = client_info["ws"]
        info = {"my_id": client_number, "positions": positions}
        info_json = json.dumps(info, indent=2)

        try:
            await websocket.send(info_json)
        except Exception as e:
            print(f"Failed to send positions to {client_number}: {e}")


def start_ws_server():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    server = loop.run_until_complete(
        websockets.serve(
            websocket_handler, get_local_ip(), 5001, reuse_address=True
        )
    )
    print("WebSocket server started.")
    loop.run_forever()


if __name__ == "__main__":
    start_ws_server()
