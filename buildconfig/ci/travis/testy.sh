#!/usr/bin/env bash

brew update
brew uninstall --force --ignore-dependencies libpng

function install_or_upgrade {
  set +e
  # TODO: recursively for dependencies (brew deps)
  # if no (bottled) in brew info <pkg>, run brew deps --include-build (includes build dependencies)
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" >/dev/null); then
      brew upgrade "$1"
    else
      echo "latest version is installed"
    fi
  else
    brew deps "$1"
    echo "BREW DEPS $1"
    # call self recursively here?
    # NOTE: dep is recursive by default

    brew install --build-bottle "$@"
    echo "json thingy here"
    brew bottle --json "$@"
    # TODO: ^ first line in stdout is the bottle file
    # use instead of file cmd. json file has a similar name
    ls
    echo "json file: `find . -name $1*.json`"
    brew uninstall "$@"
    # TODO: bottle name, json file (from "brew bottle" smoehow)
    local bottlefile=$(find . -name $1*.bottle.*.gz)
    echo "brew install this bottlefile: $(bottlefile)"
    echo "brew install this bottlefile: $bottlefile"
    brew install "$bottlefile"
    # TODO: find json file properly
    echo "brew bottle --merge --write $(find . -name $1*.json)"
    # Add the bottle info into the package's formula
    brew bottle --merge --write $(find . -name $1*.bottle.json)
    # TODO: save bottle info file (brew --cache libpng)
    local cachefile=$(brew --cache $1)
    echo "Copying $(bottlefile) to $(cachefile)..."
    cp -f "$bottlefile" "$cachefile"
  fi
  set -e
}

#libpng--1.6.36.el_capitan.bottle.1.tar.gz
#libpng--1.6.36.el_capitan.bottle.json
# match file with json?

install_or_upgrade libpng
brew bottle
echo "Cache `brew --cache libpng`"
# output: Cache /Users/travis/Library/Caches/Homebrew/downloads/0acae2cec2dc03a719ffe9df2774778541b7bf920acceca88d457e0cf0f50578--libpng-1.6.36.tar.xz
# TODO: save bottle info file (brew --cache libpng)
