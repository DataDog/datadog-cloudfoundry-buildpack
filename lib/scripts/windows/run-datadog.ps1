# Fix datadog.yaml for apm log file since it cannot be set via env vars currently
$DATADOG_DIR="C:\Users\vcap\app\datadog"
echo "apm_config:" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"
echo "  log_file: $DATADOG_DIR\trace.log" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"

# Write the DD tags we detect out to the datadog.yaml file
$tags = & "$DATADOG_DIR\scripts\get_tags.ps1"
$tags_out = "tags:`n"
foreach ($element in $tags) {
    $tags_out += "    - $element`n"
}
echo "$tags_out" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"

# Update the path to the check configuration files
echo "confd_path: $DATADOG_DIR\AppData\datadog-agent\conf.d" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"

# Remove the core checks that aren't available as Go checks
# Currently: network, load, disk. These are only available as python checks
# and can't be run via the puppy
Remove-Item -Path "$DATADOG_DIR\AppData\datadog-agent\conf.d\disk.d" -Recurse
Remove-Item -Path "$DATADOG_DIR\AppData\datadog-agent\conf.d\load.d" -Recurse
Remove-Item -Path "$DATADOG_DIR\AppData\datadog-agent\conf.d\network.d" -Recurse

# Remove the core checks if DD_ENABLE_CHECKS is false
# This needs to happen before we setup the logs config file
If ("$Env:DD_ENABLE_CHECKS" -ne $true  -and "$Env:DD_ENABLE_CHECKS" -ne "true" ) {
    echo "Removing Checks config based on DD_ENABLED_CHECKS being set to: $Env:DD_ENABLED_CHECKS"
    Remove-Item -Path "$DATADOG_DIR\AppData\datadog-agent\conf.d\*" -Recurse
}

# Write the config for the logs
$LOGS_CONFIG_DIR="$DATADOG_DIR\AppData\datadog-agent\conf.d\logs.d"
New-Item $LOGS_CONFIG_DIR -ItemType "directory" -Force
echo "{`"logs`":$Env:LOGS_CONFIG}" | Out-File $LOGS_CONFIG_DIR\logs.yaml

# Logs, core checks, and dogstatsd
Start-Process "$DATADOG_DIR\bin\agent.exe" -ArgumentList "run -c $DATADOG_DIR\AppData" -NoNewWindow

# Traces
Start-Process "$DATADOG_DIR\bin\agent\trace-agent.exe" -ArgumentList "--config $DATADOG_DIR\AppData\datadog.yaml" -NoNewWindow
