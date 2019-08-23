# Fix datadog.yaml for apm log file since it cannot be set via env vars currently
$DATADOG_DIR="C:\Users\vcap\app\datadog"
echo "apm_config:" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"
echo "  log_file: $DATADOG_DIR\trace.log" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"

$Env:LOGS_CONFIG_DIR="$DATADOG_DIR\AppData\conf.d\logs.d"
New-Item $Env:LOGS_CONFIG_DIR -ItemType "directory" -Force
Start-Process "$DATADOG_DIR\datadog agent\embedded2\python.exe" -ArgumentList "$DATADOG_DIR\scripts\create_logs_config.py" -NoNewWindow -Wait

Start-Process "$DATADOG_DIR\datadog agent\bin\agent.exe" -ArgumentList "run -c $DATADOG_DIR\AppData" -NoNewWindow
Start-Process "$DATADOG_DIR\datadog agent\bin\agent\trace-agent.exe" -ArgumentList "--config $DATADOG_DIR\AppData\datadog.yaml" -NoNewWindow
