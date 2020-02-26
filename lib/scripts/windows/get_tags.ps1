$vcapApp = $env:VCAP_APPLICATION
$vcapApp = $vcapApp | ConvertFrom-JSON

$vcap_variables = "application_id", "name", "instance_index", "space_name"

$tags = @()

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

# Require user tags on windows to be a list of tags @()
$user_tags = $env:TAGS
If ($user_tags -ne $null) {
    foreach ($element in $user_tags) {
        $tags += $element
    }
}

$user_tags = $env:DD_TAGS
If ($user_tags -ne $null) {
    foreach ($element in $user_tags) {
        $tags += $element
    }
}

# Print tags
return $tags
