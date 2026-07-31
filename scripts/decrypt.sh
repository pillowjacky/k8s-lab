#!/bin/bash

echo && echo "==> loading age key..."
export SOPS_AGE_KEY_FILE="${HOME}/.dotfiles/key.txt"

echo && echo "==> decrypting *.tfbackend..."
sops decrypt --output-type binary "./envs/default.tfbackend.enc" --output "./envs/default.tfbackend"

echo && echo "==> decrypting *.tfvars..."
sops decrypt --output-type binary "./envs/default.tfvars.enc" --output "./envs/default.tfvars"
