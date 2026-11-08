#!/usr/bin/env bash
# Descarga el APK sin firmar de la ultima corrida exitosa de CI, lo firma con el
# keystore de release que vive SOLO en el servidor y lo publica como GitHub Release.
# Uso (en condor3033, como root):  tools/firmar-y-publicar.sh [run_id]
# Requiere: gh, /root/.gh_token_iw, Android build-tools en $SDK, keystore en $KS_DIR.
set -euo pipefail
REPO="Inteliworks-cl/inteliworks-cloud-android"
BASE=/root/apps-cloud/android
SDK="${SDK:-$BASE/sdk}"
KS_DIR="$BASE/keystore"
KS="$KS_DIR/inteliworks-cloud-release.jks"
# shellcheck disable=SC1091
source "$KS_DIR/keystore.env"   # define KS_PASS, KEY_ALIAS, KEY_PASS (archivo 600, nunca a git)
export KS_PASS KEY_PASS
GH_TOKEN="$(cat /root/.gh_token_iw)"; export GH_TOKEN
BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -n1)"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG_UP="$(tr -d '[:space:]' < "$ROOT/UPSTREAM_TAG")"
REV="$(tr -dc '0-9' < "$ROOT/BRANDING_REVISION")"
VER="${TAG_UP#stable-}-iw$REV"

RUN="${1:-$(gh run list -R "$REPO" -w build.yml -b main -s success -L 1 --json databaseId -q '.[0].databaseId')}"
[ -n "$RUN" ] || { echo "No hay corridas exitosas"; exit 1; }
WORK="$BASE/out/$VER"; rm -rf "$WORK"; mkdir -p "$WORK"
gh run download "$RUN" -R "$REPO" -n inteliworks-cloud-apk -D "$WORK"
IN="$(ls "$WORK"/*-unsigned.apk)"
OUT="$WORK/inteliworks-cloud-$VER.apk"

"$BT/zipalign" -p -f 4 "$IN" "$WORK/aligned.apk"
"$BT/apksigner" sign --ks "$KS" --ks-pass env:KS_PASS --ks-key-alias "$KEY_ALIAS" \
    --key-pass env:KEY_PASS --out "$OUT" "$WORK/aligned.apk"
"$BT/apksigner" verify --verbose "$OUT" | head -5
"$BT/aapt2" dump badging "$OUT" | grep -E "^package:|^application-label:|^application:" || true
sha256sum "$OUT" | tee "$OUT.sha256"

TAG="v$VER"
if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
  gh release upload "$TAG" "$OUT" "$OUT.sha256" -R "$REPO" --clobber
else
  gh release create "$TAG" "$OUT" "$OUT.sha256" -R "$REPO" \
     --title "Inteliworks Cloud Android $VER" \
     --notes "Basado en Nextcloud Android $TAG_UP (GPL-2.0-or-later). APK firmado para instalacion directa (sideload). Codigo fuente: este repositorio + https://github.com/nextcloud/android/tree/$TAG_UP"
fi
echo "Publicado: https://github.com/$REPO/releases/tag/$TAG"
