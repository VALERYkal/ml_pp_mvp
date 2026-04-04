## 🔒 Invariant VOL15 (critique)

- Le volume canonique est `volume_15c`
- `volume_corrige_15c` est un champ legacy uniquement
- Toute lecture frontend doit utiliser:
  `volume_15c ?? volume_corrige_15c`
- Aucun calcul volumétrique métier ne doit exister côté frontend
- Toute valeur officielle @15°C provient de la DB uniquement
- Toute estimation locale doit être explicitement marquée:
  "non canonique"
