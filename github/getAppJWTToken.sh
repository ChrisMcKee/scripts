#!/bin/bash

# Replace these values
APP_ID="999999" # the apps app id
INSTALLATION_ID="000000" # Your app installation id on the org
PRIVATE_KEY_PATH="some.pem" # your apps pricate pem

# Create JWT header
JWT_HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 -w0 | tr -d '=' | tr '/+' '_-')

# Create JWT payload
NOW=$(date +%s)
EXPIRE=$((NOW + 600)) # 10 minutes from now
JWT_PAYLOAD=$(echo -n "{\"iat\":$NOW,\"exp\":$EXPIRE,\"iss\":$APP_ID}" | base64 -w0 | tr -d '=' | tr '/+' '_-')

# Create JWT signature
JWT_SIGNATURE=$(echo -n "$JWT_HEADER.$JWT_PAYLOAD" | openssl dgst -binary -sha256 -sign $PRIVATE_KEY_PATH | base64 -w0 | tr -d '=' | tr '/+' '_-')

# Combine to form JWT
JWT="$JWT_HEADER.$JWT_PAYLOAD.$JWT_SIGNATURE"

# Get installation token
curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | grep -o '"token": "[^"]*' | cut -d'"' -f4
