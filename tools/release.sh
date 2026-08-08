#!/usr/bin/env bash
# ============================================================
#  Script de release para Cuentas Claras
#  Uso:  ./tools/release.sh [1.0.0]
#  Ej:   ./tools/release.sh 1.1.0
#  Efecto: sube la version en pubspec.yaml, hace commit + tag
#          y te deja listo para compilar el APK.
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

NUEVA_VERSION="${1:-}"
if [ -z "$NUEVA_VERSION" ]; then
  echo "Error: pasa la version nueva. Ej: ./tools/release.sh 1.1.0"
  exit 1
fi

# Valida formato x.y.z
if ! [[ "$NUEVA_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: formato invalido '$NUEVA_VERSION'. Debe ser x.y.z (ej: 1.1.0)"
  exit 1
fi

# Obtiene el build number actual y lo sube en 1
BUILD_ACTUAL=$(grep -oP '^\s*version:\s+[0-9.+]+\+\K[0-9]+' pubspec.yaml || echo 1)
BUILD_NUEVO=$((BUILD_ACTUAL + 1))

# Reemplaza la version en pubspec.yaml
sed -i "s/^version: .*/version: $NUEVA_VERSION+$BUILD_NUEVO/" pubspec.yaml

echo "Version actualizada: $NUEVA_VERSION+$BUILD_NUEVO"
echo ""
echo "1) Revisa que pubspec.yaml quedo bien."
echo "2) Compila el APK (Android Studio o flutter build apk)."
echo "3) Cuando estes listo para publicar, corre:"
echo "   git add pubspec.yaml"
echo "   git commit -m 'release: v$NUEVA_VERSION'"
echo "   git tag v$NUEVA_VERSION"
echo "   git push origin main --tags"
