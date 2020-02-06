echo "-----> DatadogBuildpack/supply"

$BIN_DIR=Split-Path -Path $PSCOMMANDPATH
$ROOT_DIR=Split-Path -Path $BIN_DIR
$BUILD_DIR=$ARGS[0]
# $CACHE_DIR=$ARGS[1]
# $ENV_DIR=$ARGS[2]

echo "       Extracting Datadog Agent"


New-Item -Path "$BUILD_DIR\datadog\scripts" -ItemType Directory
New-Item -Path "$BUILD_DIR\.profile.d" -ItemType Directory
New-Item -Path "$BUILD_DIR\datadog\AppData" -ItemType Directory

# Extract agent
Expand-Archive -LiteralPath $ROOT_DIR\lib\cf-windows-7.17.0-buildpack.zip -DestinationPath $BUILD_DIR\datadog
Get-ChildItem -Path "$BUILD_DIR\datadog\cf-*" -Recurse | Move-Item -Destination "$BUILD_DIR\datadog"
Get-ChildItem -Path "$BUILD_DIR\datadog\etc" -Recurse | Move-Item -Destination "$BUILD_DIR\datadog\AppData"

# Extract .NET tracer
Start-Process "MSIEXEC" -ArgumentList "/a $ROOT_DIR\lib\dotnet-tracer.msi /qn TARGETDIR=$BUILD_DIR\datadog\extracted-dotnet-tracer" -Wait -NoNewWindow
Move-Item -Path "$BUILD_DIR\datadog\extracted-dotnet-tracer\Datadog\.NET Tracer" -Destination "$BUILD_DIR\datadog\dotNetTracer"
Remove-Item -Force -Recurse -Path "$BUILD_DIR\datadog\extracted-dotnet-tracer"

# Copy-Item -Path "$ROOT_DIR\lib\scripts\get_tags.py" -Destination "$BUILD_DIR\datadog\scripts\get_tags.py"
# Copy-Item -Path "$ROOT_DIR\lib\scripts\create_logs_config.py" -Destination "$BUILD_DIR\datadog\scripts\create_logs_config.py"
Copy-Item -Path "$ROOT_DIR\lib\scripts\windows\run-datadog.ps1" -Destination "$BUILD_DIR\datadog\scripts\run-datadog.ps1"

# Copy-Item -Path "$ROOT_DIR\lib\scripts\windows\redirect_logs.py" -Destination "$BUILD_DIR\datadog\scripts\redirect_logs.py"

Copy-Item -Path "$ROOT_DIR\lib\scripts\windows\run-datadog.bat" -Destination "$BUILD_DIR\.profile.d\02-run-datadog.bat"
