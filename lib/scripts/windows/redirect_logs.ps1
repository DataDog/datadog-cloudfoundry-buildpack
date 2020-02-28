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
        # Reconnect if the socket is disconnected
        # (The Datadog Agent times out the connection if it does not receive
        # logs during 1 minute)
        If ($Socket.Connected -eq $false) {
            $Socket.Close()
            $Socket, $Writer = Recreate-Socket
        }
        $line = read-host
        $Writer.WriteLine($line)
        Write-Host $line
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
