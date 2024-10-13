
import socket
from http.server import HTTPServer, SimpleHTTPRequestHandler

import psutil


def get_local_ip():
    for interface, addrs in psutil.net_if_addrs().items():
        for addr in addrs:
            if addr.family == socket.AF_INET and not addr.address.startswith(
                "127."
            ):
                return addr.address
    raise Exception("No valid IP address found")




def start_http_server():
    http_server = HTTPServer((get_local_ip(), 5000), SimpleHTTPRequestHandler)
    http_server.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    http_server.serve_forever()


if __name__ == "__main__":
    
    print("Starting HTTP server")
    start_http_server()
