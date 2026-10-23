#!/usr/bin/env bash
# Instala lo que falte en GitHub Codespaces: Terraform, AWS CLI y python-docx.
set -euo pipefail
mkdir -p "$HOME/.local/bin"; export PATH="$HOME/.local/bin:$PATH"

if ! command -v terraform >/dev/null; then
  echo "Instalando Terraform..."
  V=1.9.8
  curl -fsSL -o /tmp/tf.zip "https://releases.hashicorp.com/terraform/$V/terraform_${V}_linux_amd64.zip"
  unzip -oq /tmp/tf.zip -d "$HOME/.local/bin"
fi
if ! command -v aws >/dev/null; then
  echo "Instalando AWS CLI..."
  curl -fsSL -o /tmp/awscli.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  unzip -oq /tmp/awscli.zip -d /tmp && /tmp/aws/install -i "$HOME/.local/aws-cli" -b "$HOME/.local/bin" --update
fi
pip install -q python-docx || pip install -q --break-system-packages python-docx

grep -q '.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
echo "--- Versiones ---"
docker --version; terraform --version | head -1; aws --version; python3 --version
