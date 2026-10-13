$ErrorActionPreference = 'Stop'

$coverrSecret = Read-Host 'Clave de Coverr' -AsSecureString
$pixabaySecret = Read-Host 'Clave de Pixabay' -AsSecureString

try {
  $coverrValue = [System.Net.NetworkCredential]::new('', $coverrSecret).Password
  $pixabayValue = [System.Net.NetworkCredential]::new('', $pixabaySecret).Password

  if ([string]::IsNullOrWhiteSpace($coverrValue) -or [string]::IsNullOrWhiteSpace($pixabayValue)) {
    throw 'Debes ingresar ambas claves.'
  }

  $keyData = [ordered]@{
    COVERR_API_KEY = $coverrValue
    PIXABAY_API_KEY = $pixabayValue
  }
  $json = ConvertTo-Json -InputObject $keyData
  $projectRoot = Split-Path -Parent $PSScriptRoot
  $keyFile = Join-Path $projectRoot 'api_keys.json'
  [System.IO.File]::WriteAllText($keyFile, $json, [System.Text.UTF8Encoding]::new($false))

  Write-Host 'Claves guardadas localmente en api_keys.json.'
} finally {
  $coverrValue = $null
  $pixabayValue = $null
  $coverrSecret.Dispose()
  $pixabaySecret.Dispose()
}