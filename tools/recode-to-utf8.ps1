Param(
  [string]$Root = ".",
  [string[]]$Patterns = @("*.dart","*.yaml","*.yml","*.md","*.json")
)

function Convert-ToUtf8NoBom($path) {
  $bytes = [System.IO.File]::ReadAllBytes($path)

  # Heuristique : essayer UTF-8 d'abord ; si exception → fallback 1252
  try {
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    # Re-encode exactement en UTF-8 sans BOM
    [System.IO.File]::WriteAllBytes($path, [System.Text.Encoding]::UTF8.GetBytes($text))
    return
  } catch {}

  # Fallback Windows-1252
  $enc1252 = [System.Text.Encoding]::GetEncoding(1252)
  $text1252 = $enc1252.GetString($bytes)
  [System.IO.File]::WriteAllBytes($path, [System.Text.Encoding]::UTF8.GetBytes($text1252))
}

foreach ($pattern in $Patterns) {
  Get-ChildItem -Path $Root -Recurse -Include $pattern | ForEach-Object {
    Write-Host "Recode to UTF-8: $($_.FullName)"
    Convert-ToUtf8NoBom $_.FullName
  }
}