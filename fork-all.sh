#!/usr/bin/env bash
# Forke automatiquement les repos storytold/Craft Apps vers ton compte.
# Necessite : gh auth login (gh >= 2.102, dans ~/.local/bin)
#
#   ./fork-all.sh            forke ce qui manque, puis bascule .gitmodules
#   ./fork-all.sh --dry-run  affiche le plan, ne fait rien

set -uo pipefail
cd "$(dirname "$0")"

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

export PATH="$HOME/.local/bin:$PATH"
export GH_PAGER=cat
export GH_PROMPT_DISABLED=1

UPSTREAM=storytold
OWNER=$(gh api user --jq .login 2>/dev/null)

if [ -z "$OWNER" ]; then
  echo "gh non authentifie. Lance d'abord :"
  echo "  export PATH=\$HOME/.local/bin:\$PATH"
  echo "  gh auth login --hostname github.com --git-protocol ssh --web"
  exit 1
fi

echo "Compte cible : $OWNER"
echo

REPOS=$(
  git config -f .gitmodules --get-regexp '^submodule\..*\.path' \
    | awk '{print $2}' \
    | while read -r p; do basename "$p"; done \
    | sort -u
)

todo=(); skipped=(); failed=()

for r in $REPOS; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://api.github.com/repos/$OWNER/$r")
  if [ "$code" = "200" ]; then
    skipped+=("$r"); continue
  fi

  if [ "$DRY" -eq 1 ]; then
    todo+=("$r"); printf '  %-16s %s %s\n' "$r" "a forker" "$UPSTREAM/$r"
    continue
  fi

  if gh api -X POST "repos/$UPSTREAM/$r/forks" >/dev/null 2>&1; then
    todo+=("$r"); printf '  %-16s fork OK\n' "$r"
  else
    failed+=("$r"); printf '  %-16s ECHEC\n' "$r"
  fi
done

echo
printf 'deja fork : %d | a forker : %d | echecs : %d\n' \
  "${#skipped[@]}" "${#todo[@]}" "${#failed[@]}"

[ "$DRY" -eq 1 ] && { echo; echo "(dry-run, rien n a ete fait)"; exit 0; }
[ "${#failed[@]}" -gt 0 ] && { printf 'echecs : %s\n' "${failed[*]}"; exit 1; }

# Recopie les gitlinks dans .gitmodules puis resynchronise.
sed -i "s#github.com/$UPSTREAM/#github.com/$OWNER/#g" .gitmodules

if [ "${#todo[@]}" -gt 0 ] || [ "${#skipped[@]}" -gt 0 ]; then
  ./sync.sh
fi

echo
echo "Termine. Verifie avec : ./sync.sh --check"
