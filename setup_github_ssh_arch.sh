#!/usr/bin/env bash
#
# setup_github_ssh_arch.sh
#
# Installs git on Arch/Manjaro (pacman), sets up an SSH agent, generates a
# new SSH key, adds it to the agent, configures git (--global) with your
# name/email, and prints the public key in the format GitHub expects you
# to paste in Settings -> SSH and GPG keys -> New SSH key.
#
set -euo pipefail

echo "=== 1. Installing git and openssh ==="
sudo pacman -Sy --needed --noconfirm git openssh

echo
echo "=== 2. Git global configuration ==="
read -rp "Enter your git/GitHub username: " GIT_USERNAME
read -rp "Enter your git/GitHub email: " GIT_EMAIL

git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"

echo "Configured git user.name=$GIT_USERNAME user.email=$GIT_EMAIL"

echo
echo "=== 3. Generating a new SSH key ==="
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

DEFAULT_KEY_NAME="github_ed25519"
read -rp "Filename for the new key [$DEFAULT_KEY_NAME]: " KEY_NAME
KEY_NAME="${KEY_NAME:-$DEFAULT_KEY_NAME}"
KEY_PATH="$SSH_DIR/$KEY_NAME"

if [[ -f "$KEY_PATH" ]]; then
    echo "Key $KEY_PATH already exists, skipping generation."
else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH"
fi

echo
echo "=== 4. Starting the ssh-agent ==="
eval "$(ssh-agent -s)"

echo
echo "=== 5. Adding the key to the ssh-agent ==="
ssh-add "$KEY_PATH"

# Persist agent startup + key add for future shells (bash/zsh)
SSH_CONFIG="$SSH_DIR/config"
if [[ ! -f "$SSH_CONFIG" ]] || ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    {
        echo "Host github.com"
        echo "  AddKeysToAgent yes"
        echo "  IdentityFile $KEY_PATH"
    } >> "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    echo "Added github.com entry to $SSH_CONFIG"
fi

echo
echo "=== 6. Your public key (copy everything below into GitHub) ==="
echo
echo "----- BEGIN: paste into https://github.com/settings/keys -> New SSH key -----"
cat "${KEY_PATH}.pub"
echo "----- END -----"
echo
echo "Done. Add the key above at: https://github.com/settings/ssh/new"
echo "Then test with: ssh -T git@github.com"
