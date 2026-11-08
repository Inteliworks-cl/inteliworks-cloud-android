# Inteliworks Cloud — Android

App Android **Inteliworks Cloud**: el cliente oficial de [Nextcloud para Android](https://github.com/nextcloud/android)
con la marca de Inteliworks. Cada empresa cliente se conecta a **su propio servidor**
(`https://cloud.<empresa>.cl`, p. ej. `https://cloud.inteliworks.cl`), que se escribe en la pantalla de inicio.

- `applicationId`: `cl.inteliworks.cloud` (cuenta y *authorities* propias → convive con la app oficial de Nextcloud).
- Distribución: APK firmado en [Releases](https://github.com/Inteliworks-cl/inteliworks-cloud-android/releases) (instalación directa / *sideload*; no Google Play por ahora).
- Ayuda: https://inteliworks.cl · Soporte: soporte@inteliworks.cl

## Cómo funciona (overlay)

Este repo **no copia** el código de Nextcloud. El workflow `.github/workflows/build.yml`:

1. descarga `nextcloud/android` en el tag de `UPSTREAM_TAG` (versión estable fijada),
2. ejecuta `branding/apply.sh`, que
   - copia `branding/res/` encima del *flavor* `generic` (el de F-Droid, sin servicios de Google):
     nombre, colores, íconos, logo, cuenta/authorities, enlaces de ayuda/privacidad/soporte;
   - cambia el `applicationId` del flavor `generic` a `cl.inteliworks.cloud`;
   - suma `BRANDING_REVISION` al `versionCode` y agrega `-iwN` al `versionName`;
3. compila `assembleGenericRelease` y sube el APK **sin firmar** como artefacto.

La firma se hace en el servidor condor3033 (el keystore nunca sale de ahí), ver abajo.

| Archivo | Qué es |
|---|---|
| `UPSTREAM_TAG` | tag estable de Nextcloud Android usado (ej. `stable-35.0.2`) |
| `BRANDING_REVISION` | 0..9, revisión de la marca sobre ese upstream |
| `branding/res/values/setup.xml` | nombre, colores, cuenta, URLs |
| `branding/res/...` | íconos/logo generados |
| `branding/source/icono.png` | logo fuente (azul sobre círculo blanco, 512×512) |
| `tools/GenerarIconos.java` | regenera los PNG desde el logo fuente |
| `tools/firmar-y-publicar.sh` | descarga el APK de CI, lo firma y crea el Release |

## Actualizar a una nueva versión de Nextcloud

1. Ver la última estable: https://github.com/nextcloud/android/releases (tags `stable-X.Y.Z`).
2. Editar `UPSTREAM_TAG` (ej. `stable-35.0.3`) y poner `BRANDING_REVISION` en `1`.
3. Commit + push a `main` → Actions compila. Si falla `apply.sh` es porque upstream cambió
   la estructura de `app/build.gradle.kts` o de `setup.xml`: revisar y ajustar.
4. En condor3033: `tools/firmar-y-publicar.sh` (toma la última corrida exitosa de `main`).

Para re-publicar la **misma** versión upstream con cambios de marca, subir `BRANDING_REVISION`
(1→2…; máximo 9) para que Android acepte la actualización (el `versionCode` debe crecer).

## Cambiar íconos / logo

Reemplazar `branding/source/icono.png` y ejecutar:

```bash
java tools/GenerarIconos.java branding/source/icono.png branding/res
```

## Firma

- **Actual (servidor):** keystore de release en condor3033, `/root/apps-cloud/android/keystore/`
  (dir 700, archivos 600; contraseñas en `keystore.env`). Build-tools Android en
  `/root/apps-cloud/android/sdk`. Ejecutar `tools/firmar-y-publicar.sh [run_id]`.
- **Opcional (CI):** si se crean estos *secrets* en el repo, el workflow firma solo:
  `IW_KEYSTORE_BASE64` (keystore en base64), `IW_KEYSTORE_PASSWORD`, `IW_KEY_ALIAS`, `IW_KEY_PASSWORD`.

> ⚠️ **No perder el keystore**: todas las actualizaciones deben firmarse con la misma llave;
> si se pierde, los usuarios tendrían que desinstalar y reinstalar. Respaldarlo fuera del servidor.

## Licencia

Basado en Nextcloud Android © Nextcloud GmbH y colaboradores, licencia **GPL-2.0-or-later**
(ver `LICENSE.txt`). Las modificaciones de este repositorio se distribuyen bajo la misma licencia.
El código fuente correspondiente a cada APK es este repositorio en el commit del release más
`nextcloud/android` en el tag indicado en `UPSTREAM_TAG`.
