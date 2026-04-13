param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$networkName = "supabase-localhost-network"

# Create a Docker bridge network that binds exposed ports to 127.0.0.1.
docker network inspect $networkName *> $null
if ($LASTEXITCODE -ne 0) {
    docker network create -o "com.docker.network.bridge.host_binding_ipv4=127.0.0.1" $networkName *> $null
}

supabase start --network-id $networkName @Args
