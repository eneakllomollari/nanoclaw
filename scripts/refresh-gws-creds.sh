#!/bin/bash
# Decrypt gws credentials from macOS keychain and write to data/gws-config/credentials.json
# Run this after `gws auth login` to update container credentials.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUT="$PROJECT_DIR/data/gws-config/credentials.json"

mkdir -p "$(dirname "$OUT")"

node -e "
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const key = Buffer.from(
  execSync('security find-generic-password -s gws-cli -w', { encoding: 'utf8' }).trim(),
  'base64'
);
const encData = fs.readFileSync(path.join(os.homedir(), '.config/gws/credentials.enc'));

const iv = encData.slice(0, 12);
const authTag = encData.slice(encData.length - 16);
const ciphertext = encData.slice(12, encData.length - 16);

const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
decipher.setAuthTag(authTag);
let dec = decipher.update(ciphertext, null, 'utf8');
dec += decipher.final('utf8');

const creds = JSON.parse(dec);
const cs = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config/gws/client_secret.json'), 'utf8'));
const installed = cs.installed || cs.web;

const result = {
  client_id: installed.client_id,
  client_secret: installed.client_secret,
  refresh_token: creds.refresh_token,
  type: 'authorized_user'
};

fs.writeFileSync(process.argv[1], JSON.stringify(result, null, 2));
console.log('gws credentials written to', process.argv[1]);
" "$OUT"
