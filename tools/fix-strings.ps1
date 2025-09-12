Param(
  [string]$Root = ".",
  [string[]]$Patterns = @("*.dart","*.md","*.yaml","*.yml")
)

# Table de corrections (ajoute si tu en vois d'autres)
$replacements = @{
  "RÃ´le"        = "Rôle";
  "RÃ´les"       = "Rôles";
  "EntrÃ©e"      = "Entrée";
  "EntrÃ©es"     = "Entrées";
  "DÃ©pÃ´t"      = "Dépôt";
  "CiternÃ©"     = "Citerne";   # au cas où
  "RÃ©ceptions"  = "Réceptions";
  "RÃ©ception"   = "Réception";
  "Sorties"      = "Sorties";   # no-op s'il est ok
  "JournaliÃ¨rs" = "Journaliers";
  "RÃ©glages"    = "Réglages";
  "Connexion rÃ©ussie" = "Connexion réussie";
  "Aucun profil trouvÃ©" = "Aucun profil trouvé";
}

foreach ($pattern in $Patterns) {
  Get-ChildItem -Path $Root -Recurse -Include $pattern | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $original = $content
    foreach ($k in $replacements.Keys) {
      $content = $content -replace [Regex]::Escape($k), $replacements[$k]
    }
    if ($content -ne $original) {
      Write-Host "Fix strings: $($_.FullName)"
      Set-Content -Path $_.FullName -Value $content -NoNewline -Encoding UTF8
    }
  }
}