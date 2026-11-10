#!/usr/bin/env bash
# Ajustes SOLO para el build de Google Play (.aab). Se ejecuta DESPUES de compilar el APK
# (sideload), asi el APK de Releases queda igual que siempre.
# Quita permisos que Play restringe y que la app maneja sin problema si faltan:
#  - MANAGE_EXTERNAL_STORAGE: PermissionUtil.manifestHasAllFilesPermission() -> cae a
#    READ_MEDIA_IMAGES/VIDEO (subida automatica de fotos y videos sigue funcionando).
#  - REQUEST_INSTALL_PACKAGES: upstream tambien lo quita en su flavor gplay.
# Uso: branding/play.sh <dir-upstream>
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
UP="${1:?uso: play.sh <dir-upstream>}"
MF="$UP/app/src/generic/AndroidManifest.xml"
[ -f "$MF" ] && { echo "ERROR: ya existe $MF (upstream cambio?), revisar a mano"; exit 1; }
mkdir -p "$(dirname "$MF")"
cat > "$MF" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<!-- Inteliworks Cloud: build Google Play (generado por branding/play.sh) -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" tools:node="remove" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" tools:node="remove" />
</manifest>
XML
echo "Ajustes Play aplicados ($MF)"
