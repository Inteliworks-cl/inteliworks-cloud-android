#!/usr/bin/env bash
# Aplica la personalizacion "Inteliworks Cloud" sobre un checkout del cliente
# Android de Nextcloud (https://github.com/nextcloud/android) en el tag de UPSTREAM_TAG.
# Uso: branding/apply.sh <dir-upstream>
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
UP="${1:?uso: apply.sh <dir-upstream>}"
APP_ID="cl.inteliworks.cloud"
REV="$(tr -dc '0-9' < "$ROOT/BRANDING_REVISION")"
GRADLE="$UP/app/build.gradle.kts"

[ -f "$GRADLE" ] || { echo "No encuentro $GRADLE"; exit 1; }

# 1) Recursos de marca encima del flavor "generic" (F-Droid, sin servicios de Google)
mkdir -p "$UP/app/src/generic/res"
cp -r "$HERE/res/." "$UP/app/src/generic/res/"

# 2) applicationId propio en el flavor generic (convive con la app oficial)
perl -0pi -e 's/(register\("generic"\)\s*\{\s*applicationId\s*=\s*)"[^"]+"/$1"'"$APP_ID"'"/' "$GRADLE"
grep -q "applicationId = \"$APP_ID\"" "$GRADLE" || { echo "ERROR: no se pudo cambiar applicationId (cambio la estructura upstream?)"; exit 1; }

# 3) versionCode/versionName: upstream + revision de marca (permite re-publicar la misma version upstream)
#    upstream usa los 2 ultimos digitos para el build (90 = estable), asi que REV debe ser 0..9
[ "$REV" -le 9 ] || { echo "ERROR: BRANDING_REVISION debe ser 0..9"; exit 1; }
cat >> "$GRADLE" <<KTS

// --- Inteliworks Cloud: versionado de la personalizacion ---
androidComponents {
    onVariants(selector().withFlavor("default" to "generic")) { variant ->
        variant.outputs.forEach { out ->
            out.versionCode.set((out.versionCode.orNull ?: 0) + $REV)
            out.versionName.set((out.versionName.orNull ?: "") + "-iw$REV")
        }
    }
}
KTS

echo "Personalizacion aplicada: applicationId=$APP_ID rev=$REV"
