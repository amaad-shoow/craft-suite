#!/usr/bin/env bash
# Recalcule les commits epingles des sous-modules depuis l'upstream.
#
#   ./sync.sh           met a jour les epingles
#   ./sync.sh --check   rapport seulement, aucune ecriture

set -uo pipefail

cd "$(dirname "$0")"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

changed=0

while IFS= read -r line; do
  path=${line#submodule }
  path=${path#\"}
  path=${path%%\"}
  [ -z "$path" ] && continue

  url=$(git config -f .gitmodules "submodule.$path.url") || continue
  current=$(git ls-tree HEAD -- "$path" | awk '{print $3}')

  remote=$(git ls-remote "$url" HEAD 2>/dev/null | awk '{print $1}')
  if [ -z "$remote" ]; then
    printf '  ! %-28s upstream injoignable\n' "$path"
    continue
  fi

  if [ "$current" = "$remote" ]; then
    printf '  = %-28s a jour\n' "$path"
    continue
  fi

  short=${remote:0:8}
  printf '  %s %-28s %s -> %s\n' "$([ "$CHECK_ONLY" -eq 1 ] && echo '~' || echo '+')" "$path" "${current:0:8}" "$short"
  changed=$((changed + 1))

  [ "$CHECK_ONLY" -eq 0 ] && git update-index --add --cacheinfo 160000,"$remote","$path"
done < <(git config -f .gitmodules --get-regexp '^submodule\.' | awk '{print $1}')

if [ "$CHECK_ONLY" -eq 0 ] && [ "$changed" -gt 0 ]; then
  git add .gitmodules
  git commit -q -m "chore: bump $changed submodule pin(s) to upstream HEAD"
  echo "$changed epingle(s) mise(s) a jour."
elif [ "$changed" -eq 0 ]; then
  echo "Tout est a jour."
fi
