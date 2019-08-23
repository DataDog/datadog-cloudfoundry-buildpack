import os
import socket
import sys
import time
import threading


class Connection(threading.Thread):
    def __init__(self, host, port, timeout, ready):
        super(Connection, self).__init__()
        self._lock = threading.RLock()
        self.host = host
        self.port = port
        self.timeout = timeout
        self.ready = ready
        self._running = True
        self.sock = None

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

            self.ready.set()
            # HACK: Try to read from the socket, which will block as long as the connection is OK since
            # the agent isn't sending anything on the connection. As soon as this returns, it means the
            # connection was closed on the other end (agent times out the connection if it does not receive
            # logs during 1 minute). This is to prevent losing logs because after such a disconnect, the first
            # message sent on the socket will succeed, even though it cannot possibly have been received.
            self.sock.recv(1)
            sys.stdout.write("Resetting connection to {}:{}\n".format(self.host, self.port))
            sys.stdout.flush()


def redirect():
    port = int(os.environ.get("STD_LOG_COLLECTION_PORT"))
    host = "localhost"
    conn_ready = threading.Event()
    conn = Connection(host, port, None, conn_ready)
    sys.stdout.write("Connecting to {}:{}\n".format(host, port))
    sys.stdout.flush()
    conn.start()
    conn_ready.wait()
    sys.stdout.write("Connected to {}:{}\n".format(host, port))
    sys.stdout.flush()

    # Read input and write line to stdout so that it can be received downstream, by loggregator for example
    line = sys.stdin.readline()
    sys.stdout.write(line)
    sys.stdout.flush()
    while line:
        try:
            conn._lock.acquire()
            conn.sock.sendall(line)
        except socket.error as e:
            sys.stdout.write("Error forwarding log to {}:{}: {}\n".format(host, port, e))
            sys.stdout.flush()
            # continue so we don't read the next line but rather retry sending once the connection is reestablished
            continue
        except Exception as e:
            sys.stdout.write("Unexpected error: {}\n".format(e))
            sys.stdout.flush()
            continue
        finally:
            conn._lock.release()
        # Read input and write line to stdout so that it can be received downstream, by loggregator for example
        line = sys.stdin.readline()
        sys.stdout.write(line)
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
