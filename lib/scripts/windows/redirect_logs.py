import os
import socket
import sys
import time
import threading


class Connection(threading.Thread):
    def __init__(self, host, port, timeout):
        super(Connection, self).__init__()
        self._lock = threading.RLock()
        self.host = host
        self.port = port
        self.timeout = timeout
        self._running = True

    def connect(self, host, port, timeout):
        self.sock = socket.create_connection((host, port), timeout=timeout)

    def stop(self):
        self._running = False
        self.sock.shutdown(socket.SHUT_RDWR)
        self.sock.close()

    def run(self):
        while self._running:
            try:
                self._lock.acquire()
                self.connect(self.host, self.port, self.timeout)
            except socket.error as e:
                sys.stdout.write("Cannot connect to {}:{}: {}\n".format(self.host, self.port, e))
                sys.stdout.flush()
                time.sleep(1)
                continue
            finally:
                self._lock.release()

            sys.stdout.write("receiveing\n")
            sys.stdout.flush()
            self.sock.recv(1)
            sys.stdout.write("Resetting connection to {}:{}\n".format(self.host, self.port))
            sys.stdout.flush()


def redirect():
    port = int(os.environ.get("STD_LOG_COLLECTION_PORT"))
    host = "localhost"
    conn = Connection(host, port, None)
    sys.stdout.write("Connecting to {}:{}\n".format(host, port))
    sys.stdout.flush()
    conn.start()
    sys.stdout.write("Connected to {}:{}\n".format(host, port))
    sys.stdout.flush()

    line = sys.stdin.readline()
    sys.stdout.write("line read\n")
    sys.stdout.flush()
    sys.stdout.write(line)
    sys.stdout.flush()
    sys.stdout.write("line flushed\n")
    sys.stdout.flush()
    while line:
        sys.stdout.write("while\n")
        sys.stdout.flush()
        try:
            sys.stdout.write("aquiring\n")
            sys.stdout.flush()
            conn._lock.acquire()
            sys.stdout.write("acquired\n")
            sys.stdout.flush()
            conn.sock.sendall(line)
        except socket.error:
            sys.stdout.write("Error forwarding log to {}:{}\n".format(host, port))
            sys.stdout.flush()
            # Break here so we don't read the next line but rather retry sending once the connection is reestablished
            break
        finally:
            sys.stdout.write("release\n")
            sys.stdout.flush()
            conn._lock.release()
            sys.stdout.write("released\n")
            sys.stdout.flush()
        sys.stdout.write("next line\n")
        sys.stdout.flush()
        line = sys.stdin.readline()
        sys.stdout.write(line)
        sys.stdout.flush()

    sys.stdout.write("stoppingue\n")
    sys.stdout.flush()
    conn.stop()


if os.environ.get("DD_LOGS_ENABLED") == "true":
    if not os.environ.get("LOGS_CONFIG"):
        sys.stdout.write("can't collect logs, LOGS_CONFIG is not set\n")
        sys.stdout.flush()
    else:
        sys.stdout.write("collect all logs for config {}\n".format(os.environ.get("LOGS_CONFIG")))
        if os.environ.get("STD_LOG_COLLECTION_PORT"):
            sys.stdout.write(
                "forward all logs from stdout/err to agent port {}\n".format(os.environ.get("STD_LOG_COLLECTION_PORT"))
            )
            sys.stdout.flush()
            redirect()
