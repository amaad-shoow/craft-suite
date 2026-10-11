# craft-suite

Mono-repo de référence pour l'ecosystème **ArtCraft / Crafting Apps** de
[`storytold`](https://github.com/storytold) — des *clean-room reimplementations*
d'Adobe / Microsoft / Avid écrites en Rust pur.

Ce depot ne contient **aucun code** : chaque application est un *gitlink*
(sous-module) pointe vers un commit precis. Cloner cette suite ne telecharge
rien tant que tu ne fais pas `git submodule update`.

## Applications

| chemin | cible | etat |
| --- | --- | --- |
| `apps/photocraft` | Adobe Photoshop | early alpha |
| `apps/vectorcraft` | Adobe Illustrator | en dev |
| `apps/filmcraft` | Adobe Premiere Pro | en dev |
| `apps/lightcraft` | Adobe Lightroom | en dev |
| `apps/pdfcraft` | Adobe Acrobat | early alpha |
| `apps/effectcraft` | Adobe After Effects | en dev |
| `apps/designcraft` | Adobe InDesign | en dev |
| `apps/wordcraft` | Microsoft Word | en dev |
| `apps/gridcraft` | Microsoft Excel | en dev |
| `apps/deckcraft` | Microsoft PowerPoint | en dev |
| `apps/cadcraft` | AutoCAD | en dev |
| `apps/soundcraft` | Avid Pro Tools | en dev |
| `apps/artcraft` | Studio IA (62 modeles) | v0.41.0 |
| `apps/craft-launcher` | Installateur de la suite | v0.2.0 |

## Librairies partagees

| chemin | role |
| --- | --- |
| `shared/craft-libs` | crates Rust communes aux Craft Apps |
| `shared/craft-fonts` | polices des Craft Apps |

Toutes sont sous **Apache-2.0** (ArtCraft IA : MIT **ou** Apache-2.0).

## Utilisation

```bash
# initialiser la suite
git clone --recurse-submodules <url>

# ou, dans un depot deja clone
git submodule update --init --recursive

# un seul projet
git submodule update --init apps/photocraft

# sans les sous-modules (index seul, ~1 Mo)
git clone <url>
```

## Recalculer les commits epingles

`./sync.sh` va chercher `HEAD` de chaque branche par defaut sur l'upstream et
met a jour les epingles sans toucher aux fichiers.

```bash
./sync.sh          # met a jour
./sync.sh --check  # affiche les derives, ne modifie rien
```

## Reconnecter les forks

Les sous-modules pointent par defaut sur l'upstream. Pour pointer sur tes
propres forks :

```bash
sed -i 's#github.com/storytold/#github.com/<TON-PSEUDO>/#g' .gitmodules
git submodule sync --recursive
```

Les forks partageant l'historique, les commits epingles restent valides.
