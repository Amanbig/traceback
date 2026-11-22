#!/usr/bin/env bash
set -e

# ==============================================================================
# Traceback Release Keystore Generator Helper
# ==============================================================================

KEYSTORE_PATH="android/app/traceback-release.jks"
KEY_PROPS="android/key.properties"

if [ -f "$KEYSTORE_PATH" ]; then
    echo "Keystore already exists at $KEYSTORE_PATH."
    exit 0
fi

echo "Generating release keystore at $KEYSTORE_PATH..."
read -sp "Enter Keystore Password: " STOREPASS
echo ""
read -p "Enter Key Alias [default: traceback-key]: " ALIAS
ALIAS=${ALIAS:-traceback-key}

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "$STOREPASS" \
  -keypass "$STOREPASS" \
  -dname "CN=Traceback Security, OU=Cyber Defense, O=Traceback Open Source, L=New Delhi, ST=Delhi, C=IN"

cat <<EOF > "$KEY_PROPS"
storePassword=$STOREPASS
keyPassword=$STOREPASS
keyAlias=$ALIAS
storeFile=traceback-release.jks
EOF

echo "✓ Keystore created successfully!"
echo "✓ android/key.properties created successfully!"
echo ""
echo "To add to GitHub Secrets for CI automated release builds:"
echo "1. Secret ANDROID_KEYSTORE_BASE64: Run 'base64 -w 0 $KEYSTORE_PATH' and copy output."
echo "2. Secret ANDROID_KEYSTORE_PASSWORD: $STOREPASS"
echo "3. Secret ANDROID_KEY_ALIAS: $ALIAS"
echo "4. Secret ANDROID_KEY_PASSWORD: $STOREPASS"
