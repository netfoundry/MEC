# Authenticate with NetFoundry Platform
function Authenticate([string]$username, [string]$password) {
    $credPair = "$($username):$($password)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded")
    $headers.Add("Authorization", "Basic $encodedCredentials" )

    $body = "grant_type=client_credentials&scope="

    $response = Invoke-RestMethod 'https://netfoundry-production-xfjiye.auth.us-east-1.amazoncognito.com/oauth2/token' -Method 'POST' -Headers $headers -Body $body
    $response | ConvertTo-Json

    return  $response
}

# Look up all networks within the same network group
function Lookup-Networks([string]$token) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $response = Invoke-RestMethod 'https://gateway.production.netfoundry.io/core/v2/networks' -Method 'GET' -Headers $headers
    $response | ConvertTo-Json
    
    return $response
    }

# Create edge router on a given network
function Create-Edge-Router([string]$token, [string]$network_id, [string]$router_name, [string]$router_attribute) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $token")

    $body = "{`n    `"name`":`"$router_name`",`n    `"networkId`":`"$network_id`",`n    `"dataCenterId`":null,`n    `"linkListener`":false,`n    `"attributes`":[`"#$router_attribute`"],`n    `"tunnelerEnabled`": true,`n    `"noTraversal`": true`n}"

    $response = Invoke-RestMethod 'https://gateway.production.netfoundry.io/core/v2//edge-routers' -Method 'POST' -Headers $headers -Body $body
    $response | ConvertTo-Json

    return $response
}

# Get a registration key from the newly created router
function Get-Router-Reg-Key([string]$token, [string]$router_id) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $response = Invoke-RestMethod "https://gateway.production.netfoundry.io/core/v2/edge-routers/$router_id/registration-key" -Method 'POST' -Headers $headers
    $response | ConvertTo-Json
    
    return $response
}

# Authenticate with NetFoundry Platform to receive an access token using credential file stored in your home directory under ~/.netfoundry folder
$client_id = $env:CLIENT_ID
$client_secret = $env:CLIENT_SECRET
$router_name = $env:ROUTER_NAME
$router_attribute = $env:ROUTER_ATTRIBUTE
# Get a registration key from the newly created router
#$cred_data = Get-Content ~/.netfoundry/credentials.json | Out-String | ConvertFrom-Json
$data = Authenticate -username $client_id -password $client_secret
# Look up all networks within the same network group and filter for a given network name
$networks = Lookup-Networks -token $data.access_token
$network = $networks._embedded.networkList | Where-Object  {$_.name -Eq 'privatedcmgmt'}
# create edge router on a given network
$router = Create-Edge-Router -token $data.access_token -network_id $network.id -router_name $router_name -router_attribute $router_attribute
# Get a registration key from the newly created router
Start-Sleep -Seconds 10
$reg_key = Get-Router-Reg-Key -token $data.access_token -router_id $router.id
# Output the registration key
Write-Output $reg_key.registrationKey
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['text'] = $reg_key.registrationKey