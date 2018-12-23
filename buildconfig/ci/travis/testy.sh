function install_or_upgrade {
  set +e
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" >/dev/null); then
      brew upgrade "$1"
    else
      echo "latest version is installed"
    fi
  else
    brew install "$@"
  fi
  set -e
}

install_or_upgrade libpng
brew bottle
brew bottle --json
brew --cache libpng
