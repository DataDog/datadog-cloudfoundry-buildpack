$hostname = "localhost"
$port = $Env:STD_LOG_COLLECTION_PORT # 10514

# Recreate the socket, writer objects in the case that the connection was closed
# https://docs.microsoft.com/en-us/dotnet/api/system.net.sockets.tcpclient?view=netframework-4.8
function Recreate-Socket {
    Write-Host "Connecting to $hostname $port"
    try {
        $Socket = New-Object System.Net.Sockets.TCPClient($hostname,$port)
        $Stream = $Socket.GetStream()
        $Writer = New-Object System.IO.StreamWriter($Stream)
        $Writer.AutoFlush = $true;
        return $Socket, $Writer
    } catch {
        Write-Host "Couldn't connect to $hostname $port"
    }
}

function Run {
    $Socket, $Writer = Recreate-Socket
    while($true)
    {
        # Read-Host waits for the input from the piped process, so it also writes to screen.
        # So we don't need to explicitly rewrite the line back out via Write-Host
        $line = Read-Host

        # (The Agent closes this connection after a period of receiving no logs)
        # IF the connection is closed, the first message sent won't send but won't trigger an exception
        # Then when the second message tries to send, it gets an exceoption, and marks the Socket.Connected as false
        try{
            $Writer.WriteLine($line)
            # Set this if only if we were successfully able to send the message to the socket
            $previous_line = $line
        } catch {
            $Socket.Close()
            $Socket, $Writer = Recreate-Socket
            $Writer.WriteLine($previous_line)
            $Writer.WriteLine($line)
        }
    }
}

# Ensure that the user chooses to collect logs and the proper variables are set
If ($Env:DD_LOGS_ENABLED -eq $true) {
    if (!(Test-Path 'env:LOGS_CONFIG') -Or !(Test-Path 'env:STD_LOG_COLLECTION_PORT')) {
        Write-Host "Can't collect logs; LOGS_CONFIG and/or STD_LOG_COLLECTION_PORT is not set"
    } else {
        Write-Host "Collecing logs for config: $LOGS_CONFIG"
        Run
    }
}
