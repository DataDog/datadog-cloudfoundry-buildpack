# This script retrieves some expected tags from various CF provided environment variables
# as well as some custom tags provided by the user.
$vcapApp = $env:VCAP_APPLICATION
$vcapApp = $vcapApp | ConvertFrom-JSON

# Collect host tags about the application
$vcap_variables = "application_id", "name", "instance_index", "space_name"

$tags = @()

# Documentation for the VCAP_APPLICATION env var - https://docs.run.pivotal.io/devguide/deploy-apps/environment-variable.html#VCAP-APPLICATION
# Pull out expected key/values to use as tags.
foreach ($element in $vcap_variables) {
    $vcap_var = $vcapApp.$element
    If ($vcap_var -ne $null) {
        $key = $element
        If($key -eq "name") {
            $key = "application_name"
        }
        $tags += "${key}:${vcap_var}"
    }
}

$uris = $vcapApp.uris
If ($vcap_var -ne $null) {
    foreach ($element in $uris) {
        $tags += "uri:${element}"
    }
}

# Require user tags on windows to be a list of tags, i.e. $TAGS=@(env:staging, app:web)
$user_tags = $env:TAGS
If ($user_tags -ne $null) {
    foreach ($element in $user_tags) {
        $tags += $element
    }
}

# Support the same for the DD_TAGS environment variable
$user_tags = $env:DD_TAGS
If ($user_tags -ne $null) {
    foreach ($element in $user_tags) {
        $tags += $element
    }
}

# Print tags
return $tags
