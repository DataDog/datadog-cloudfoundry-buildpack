#!/usr/bin/env python

import os
import socket
import sys
import threading


class Sender(threading.Thread):
    def __init__(self, sock):
        super(Sender, self).__init__()
        self.sock = sock

    def run(self):
        line = sys.stdin.readline()
        while line:
            try:
                sock.sendall(line)
            except Exception as e:
                try:
                    sock.shutdown(socket.SHUT_RDWR)
                    sock.close()
                except Exception:
                    pass
                exit(1)
            line = sys.stdin.readline()


try:
    sock = socket.create_connection(("localhost", sys.argv[1]), timeout=None)
except Exception as e:
    exit(1)

sender = Sender(sock)
sender.daemon = True
sender.start()

# HACK: Try to read from the socket, which will block as long as the connection is OK since
# the agent isn't sending anything on the connection. As soon as this returns, it means the
# connection was closed on the other end (agent times out the connection if it does not receive
# logs during 1 minute). This is to prevent losing logs because after such a disconnect, the first
# message sent on the socket will succeed, even though it cannot possibly have been received.
try:
    sock.recv(1)
    sock.shutdown(socket.SHUT_RDWR)
    sock.close()
except Exception:
    pass
exit(1)
