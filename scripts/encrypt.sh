#!/bin/bash

echo && echo "==> loading age key..."
export SOPS_AGE_KEY_FILE="${HOME}/.dotfiles/key.txt"

echo && echo "==> encrypting *.tfbackend..."
sops encrypt --input-type binary "./envs/default.tfbackend" --output "./envs/default.tfbackend.enc"

echo && echo "==> encrypting *.tfvars..."
sops encrypt --input-type binary "./envs/default.tfvars" --output "./envs/default.tfvars.enc"
