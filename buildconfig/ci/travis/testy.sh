#!/usr/bin/env bash

brew update
brew uninstall --force --ignore-dependencies libpng

function install_or_upgrade {
  set +e
  # TODO: recursively for dependencies. also check if bottled. if not, --include-build for brew deps
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" >/dev/null); then
      brew upgrade "$1"
    else
      echo "latest version is installed"
    fi
  else
    brew install --build-bottle "$@"
    echo "json thingy here"
    brew bottle --json "$@"
    #brew uninstall "$@"
    # TODO: bottle name, json file (from "brew bottle" smoehow)
    #brew install <bottle>
    #brew bottle --merge --write <json file>
    # TODO: save bottle info file (brew --cache libpng)
  fi
  set -e
}

install_or_upgrade libpng
brew bottle
echo "Cache `brew --cache libpng`"
# output: Cache /Users/travis/Library/Caches/Homebrew/downloads/0acae2cec2dc03a719ffe9df2774778541b7bf920acceca88d457e0cf0f50578--libpng-1.6.36.tar.xz
# TODO: save bottle info file (brew --cache libpng)
