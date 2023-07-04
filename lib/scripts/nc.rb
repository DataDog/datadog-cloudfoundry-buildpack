#!/usr/bin/env ruby

require 'socket'

class Sender < Thread
  def initialize(sock)
    super()
    @sock = sock
  end

  def run
    line = $stdin.readline
    while line
      begin
        @sock.send(line, 0)
      rescue Exception => e
        begin
          @sock.shutdown(Socket::SHUT_RDWR)
          @sock.close
        rescue Exception
        end
        exit(1)
      end
      line = $stdin.readline
    end
  end
end

begin
  sock = TCPSocket.new("localhost", ARGV[0])
rescue Exception => e
  exit(1)
end

sender = Sender.new(sock)
sender.daemon = true
sender.start

# HACK: Try to read from the socket, which will block as long as the connection is OK since
# the agent isn't sending anything on the connection. As soon as this returns, it means the
# connection was closed on the other end (agent times out the connection if it does not receive
# logs during 1 minute). This is to prevent losing logs because after such a disconnect, the first
# message sent on the socket will succeed, even though it cannot possibly have been received.
begin
  sock.recv(1)
  sock.shutdown(Socket::SHUT_RDWR)
  sock.close
rescue Exception
end
exit(1)
