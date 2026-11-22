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

echo "=========================================================="
echo " Traceback Android Release Keystore Generator"
echo "=========================================================="
echo ""

read -sp "Enter Keystore Password [e.g. traceback123]: " STOREPASS
echo ""
read -p "Enter Key Alias [default: traceback-key]: " ALIAS
ALIAS=${ALIAS:-traceback-key}

if command -v keytool &> /dev/null; then
    echo "Generating keystore with keytool..."
    keytool -genkey -v \
      -keystore "$KEYSTORE_PATH" \
      -alias "$ALIAS" \
      -keyalg RSA \
      -keysize 2048 \
      -validity 10000 \
      -storepass "$STOREPASS" \
      -keypass "$STOREPASS" \
      -dname "CN=Traceback Security, OU=Cyber Defense, O=Traceback Open Source, L=New Delhi, ST=Delhi, C=IN"
elif command -v openssl &> /dev/null; then
    echo "keytool not found; generating standard PKCS12 keystore with OpenSSL..."
    TMP_KEY=$(mktemp)
    TMP_CERT=$(mktemp)
    
    openssl req -new -x509 -newkey rsa:2048 -nodes \
      -keyout "$TMP_KEY" \
      -out "$TMP_CERT" \
      -days 10000 \
      -subj "/CN=Traceback Security/OU=Cyber Defense/O=Traceback Open Source/L=New Delhi/ST=Delhi/C=IN" > /dev/null 2>&1
      
    openssl pkcs12 -export \
      -out "$KEYSTORE_PATH" \
      -inkey "$TMP_KEY" \
      -in "$TMP_CERT" \
      -name "$ALIAS" \
      -passout "pass:$STOREPASS" > /dev/null 2>&1
      
    rm -f "$TMP_KEY" "$TMP_CERT"
else
    echo "Error: Neither keytool nor openssl was found on this system."
    echo "Please install OpenJDK: sudo apt install -y openjdk-17-jre-headless"
    exit 1
fi

cat <<EOF > "$KEY_PROPS"
storePassword=$STOREPASS
keyPassword=$STOREPASS
keyAlias=$ALIAS
storeFile=traceback-release.jks
EOF

echo ""
echo "✓ Keystore generated at: $KEYSTORE_PATH"
echo "✓ Properties file created: $KEY_PROPS"
echo ""
echo "=========================================================="
echo " GitHub Secrets Setup for Automated Release Builds:"
echo "=========================================================="
echo "1. ANDROID_KEYSTORE_PASSWORD: $STOREPASS"
echo "2. ANDROID_KEY_ALIAS:        $ALIAS"
echo "3. ANDROID_KEY_PASSWORD:     $STOREPASS"
echo "4. ANDROID_KEYSTORE_BASE64:  Copy the base64 string below:"
echo "----------------------------------------------------------"
base64 -w 0 "$KEYSTORE_PATH"
echo ""
echo "----------------------------------------------------------"
