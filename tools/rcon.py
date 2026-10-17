#!/usr/bin/env python3
"""Minimaler Source-RCON-Client (nur Standardbibliothek).

Nutzung:  tools/rcon.py "lua_run print(physenv.GetGravity())"
Env:      RCON_HOST (127.0.0.1), RCON_PORT (27015), RCON_PASSWORD (devonly)
"""
import os
import socket
import struct
import sys

SERVERDATA_AUTH = 3
SERVERDATA_AUTH_RESPONSE = 2
SERVERDATA_EXECCOMMAND = 2
SERVERDATA_RESPONSE_VALUE = 0


def send(sock, req_id, kind, body):
    payload = struct.pack("<ii", req_id, kind) + body.encode() + b"\x00\x00"
    sock.sendall(struct.pack("<i", len(payload)) + payload)


def recv_exact(sock, n):
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("RCON-Verbindung geschlossen")
        buf += chunk
    return buf


def recv(sock):
    (size,) = struct.unpack("<i", recv_exact(sock, 4))
    data = recv_exact(sock, size)
    req_id, kind = struct.unpack("<ii", data[:8])
    return req_id, kind, data[8:-2].decode(errors="replace")


def main():
    if len(sys.argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        return 64

    host = os.environ.get("RCON_HOST", "127.0.0.1")
    port = int(os.environ.get("RCON_PORT", "27015"))
    password = os.environ.get("RCON_PASSWORD", "devonly")
    command = " ".join(sys.argv[1:])

    with socket.create_connection((host, port), timeout=5) as sock:
        send(sock, 1, SERVERDATA_AUTH, password)
        while True:
            req_id, kind, _ = recv(sock)
            if kind == SERVERDATA_AUTH_RESPONSE:
                break
        if req_id == -1:
            print("RCON-Authentifizierung fehlgeschlagen", file=sys.stderr)
            return 1

        send(sock, 2, SERVERDATA_EXECCOMMAND, command)
        # Leeres Paket als Endmarker: dessen Echo kommt nach der vollständigen Antwort
        send(sock, 3, SERVERDATA_RESPONSE_VALUE, "")

        out = []
        while True:
            req_id, _, body = recv(sock)
            if req_id == 3:
                break
            out.append(body)

    sys.stdout.write("".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
