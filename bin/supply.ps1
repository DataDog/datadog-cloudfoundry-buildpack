echo "-----> DatadogBuildpack/supply"

$BIN_DIR=Split-Path -Path $PSCOMMANDPATH
$ROOT_DIR=Split-Path -Path $BIN_DIR
$BUILD_DIR=$ARGS[0]
$CACHE_DIR=$ARGS[1]
$ENV_DIR=$ARGS[2]

echo "       Installing Datadog Agent"


New-Item -Path "$BUILD_DIR\datadog\scripts" -ItemType Directory
New-Item -Path "$BUILD_DIR\datadog\extracted-agent" -ItemType Directory
New-Item -Path "$BUILD_DIR\.profile.d" -ItemType Directory

# Extract agent
Start-Process "MSIEXEC" -ArgumentList "/a $ROOT_DIR\lib\datadog-agent.msi /qn TARGETDIR=$BUILD_DIR\datadog\extracted-agent" -Wait -NoNewWindow
Move-Item -Path "$BUILD_DIR\datadog\extracted-agent\Datadog\Datadog Agent" -Destination "$BUILD_DIR\datadog\"
Move-Item -Path "$BUILD_DIR\datadog\extracted-agent\CommonAppData\Datadog" -Destination "$BUILD_DIR\datadog\AppData"
Remove-Item -Force -Recurse -Path "$BUILD_DIR\datadog\extracted-agent"

# # Extract .NET tracer
# Start-Process "MSIEXEC" -ArgumentList "/a $ROOT_DIR\lib\dotnet-tracer.msi /qn TARGETDIR=$BUILD_DIR\datadog\extracted-dotnet-tracer" -Wait -NoNewWindow
# Move-Item -Path "$BUILD_DIR\datadog\extracted-dotnet-tracer\Datadog\.NET Tracer" -Destination "$BUILD_DIR\datadog\"
# Remove-Item -Force -Recurse -Path "$BUILD_DIR\datadog\extracted-dotnet-tracer"

Copy-Item -Path "$ROOT_DIR\lib\scripts\get_tags.py" -Destination "$BUILD_DIR\datadog\scripts\get_tags.py"
Copy-Item -Path "$ROOT_DIR\lib\scripts\create_logs_config.py" -Destination "$BUILD_DIR\datadog\scripts\create_logs_config.py"
Copy-Item -Path "$ROOT_DIR\lib\scripts\windows\run-datadog.ps1" -Destination "$BUILD_DIR\datadog\scripts\run-datadog.ps1"
# Copy-Item -Path "$ROOT_DIR\lib\test-endpoint.sh" -Destination "$BUILD_DIR\.profile.d\00-test-endpoint.sh" # Make sure this is sourced first
# Copy-Item -Path "$ROOT_DIR\lib\redirect-logs.sh" -Destination "$BUILD_DIR\.profile.d\01-redirect-logs.sh"
Copy-Item -Path "$ROOT_DIR\lib\scripts\windows\run-datadog.bat" -Destination "$BUILD_DIR\.profile.d\02-run-datadog.bat"

# chmod +x $BUILD_DIR/.profile.d/00-test-endpoint.sh
# chmod +x $BUILD_DIR/.profile.d/01-redirect-logs.sh
# chmod +x $BUILD_DIR/.profile.d/02-run-datadog.sh
# chmod +x $BUILD_DIR/datadog/datadog-agent
# chmod +x $BUILD_DIR/datadog/scripts/setup.sh
