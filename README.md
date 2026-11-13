# Intranet Marabunta R.L. — App Móvil (Flutter)

Aplicación móvil nativa conectada a **Authentik OIDC (Authorization Code + PKCE)** y a la API de `https://homepage.marabuntarl.com`.

## Características implementadas
- **OIDC Authorization Code + PKCE** contra `Intranet Móvil OIDC` (`marabunta-intranet-mobile`).
- **Almacenamiento seguro** de `access_token`, `refresh_token` e `id_token` con `flutter_secure_storage` (Android Keystore / iOS Keychain).
- **Protección biométrica** con `local_auth` antes de desbloquear y renovar la sesión guardada.
- **Consumo de API** (`/api/me`, `/api/cards`, `/api/notices`) con `Authorization: Bearer <token>` y renovación automática vía `refresh_token`.
- **Apertura de módulos web con SSO** mediante Chrome Custom Tabs / `SFSafariViewController` (`flutter_custom_tabs`) sin pasar tokens en la URL.

## Cómo compilar en tu equipo con Flutter SDK
1. Copia o clona `/opt/intranet-marabunta-mobile` en tu máquina con Flutter instalado (`>= 3.3.0`).
2. Genera los archivos base nativos de Android/iOS sin sobrescribir `lib/` ni `pubspec.yaml`:
   ```bash
   flutter create --org com.marabuntarl --project-name intranet_marabunta .
   ```
3. Verifica en `android/app/build.gradle` (o `.kts`) los valores de `android/app/build.gradle.snippet` (`minSdk = 23`, `appAuthRedirectScheme = "com.marabuntarl.intranet"`) y en `ios/Runner/Info.plist` los de `ios/Runner/Info.plist.snippet`.
4. Instala dependencias y ejecuta:
   ```bash
   flutter pub get
   flutter run
   ```

