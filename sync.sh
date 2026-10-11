#!/usr/bin/env bash
# Recalcule les commits epingles des sous-modules depuis l'upstream.
#
#   ./sync.sh           restaure les gitlinks manquants puis met a jour les epingles
#   ./sync.sh --check   rapport seulement, aucune ecriture

set -uo pipefail

cd "$(dirname "$0")"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# ---- restauration ---------------------------------------------------------
# Les repertoires des sous-modules sont vides tant que `git submodule update`
# n'a pas ete lance. `git commit -am` les voit alors comme des suppressions et
# supprime les gitlinks (mode 160000). On les remet d'apres pins.txt.

restored=0
while IFS=$'\t' read -r path pinned; do
  case "$path" in ''|\#*) continue ;; esac
  [ -d "$path" ] || { [ "$CHECK_ONLY" -eq 0 ] && mkdir -p "$path"; }

  indexed=$(git ls-files --stage -- "$path" | awk '{print $1" "$2}')
  [ "$indexed" = "160000 $pinned" ] || restored=$((restored + 1))
  [ -d "$path" ] || printf '  r %-28s repertoire cree\n' "$path"
  [ "$indexed" = "160000 $pinned" ] && continue

  printf '  r %-28s gitlink restaure (%s)\n' "$path" "${pinned:0:8}"
  [ "$CHECK_ONLY" -eq 0 ] && git update-index --add --cacheinfo 160000,"$pinned","$path"
done < pins.txt

# ---- mise a jour ----------------------------------------------------------

changed=0
: > .pins.tmp

while IFS=$'\t' read -r path _pinned; do
  case "$path" in ''|\#*) continue ;; esac

  url=$(git config -f .gitmodules "submodule.$path.url")
  [ -z "$url" ] && { printf '  ! %-28s absent de .gitmodules\n' "$path"; continue; }

  remote=$(git ls-remote "$url" HEAD 2>/dev/null | awk '{print $1}')
  if [ -z "$remote" ]; then
    printf '  ! %-28s upstream injoignable (%s)\n' "$path" "$url"
    remote=$_pinned
  fi

  printf '%s\t%s\n' "$path" "$remote" >> .pins.tmp

  current=$(git ls-files --stage -- "$path" | awk '{print $2}')
  [ "$current" = "$remote" ] && continue

  printf '  %s %-28s %s -> %s\n' "$([ "$CHECK_ONLY" -eq 1 ] && echo '~' || echo '+')" \
    "$path" "${current:0:8}" "${remote:0:8}"
  changed=$((changed + 1))
  [ "$CHECK_ONLY" -eq 0 ] && git update-index --add --cacheinfo 160000,"$remote","$path"
done < pins.txt

if [ "$CHECK_ONLY" -eq 0 ] && { [ "$changed" -gt 0 ] || [ "$restored" -gt 0 ]; }; then
  mv .pins.tmp pins.txt
  git add -- .gitmodules pins.txt
  git diff --cached --quiet || \
    git commit -q -m "chore: bump $changed submodule pin(s) to upstream HEAD"
  echo "$changed epingle(s) mise(s) a jour, $restored restauree(s)."
else
  rm -f .pins.tmp
  [ "$changed" -eq 0 ] && echo "Tout est a jour."
fi
