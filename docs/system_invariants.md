## 🔒 Invariant VOL15 (critique)

- Le volume canonique est `volume_15c`
- `volume_corrige_15c` est un champ legacy uniquement
- Toute lecture frontend doit utiliser:
  `volume_15c ?? volume_corrige_15c`
- Aucun calcul volumétrique métier ne doit exister côté frontend
- Toute valeur officielle @15°C provient de la DB uniquement
- Toute estimation locale doit être explicitement marquée:
  "non canonique"

---

# 4. PIPELINE LOGISTIQUE

# 4.1 CDR STATE INVARIANT

- Le CDR est piloté uniquement par la colonne `statut`
- Les valeurs autorisées sont contrôlées en base (CHECK constraint)
- Aucune machine d’état parallèle n’est autorisée côté application
- Le passage à DECHARGE ne peut se faire que via une réception validée

Interdit :
- ajouter un champ etat
- gérer un workflow parallèle côté frontend
- bypass la règle réception → DECHARGE
