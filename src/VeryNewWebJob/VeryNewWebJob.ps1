$token = 'egp7tq82pys3pr6ymy0u'

$headers = @{
  "Authorization" = "Bearer $token"
  "Content-type" = "application/json"
}

$body = @{
    accountName="IlyaFinkelshteyn"
    projectSlug="WebApplication1"
    branch="master"
    commitId="f71af9bd"
}
$body = $body | ConvertTo-Json

Invoke-RestMethod -Uri 'https://ci.appveyor.com/api/builds' -Headers $headers  -Body $body -Method POST

