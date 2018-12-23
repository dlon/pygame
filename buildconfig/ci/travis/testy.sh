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
    echo "brew info $1"
    brew info "$1"
    if (brew info "$1" | grep "(bottled)" >/dev/null); then
      echo "BREW DEPS $1"
      brew deps "$1"
    else
      echo "BREW DEPS $1 -- include-build"
      brew deps --include-build "$1"
    fi
    # why does it return nothing!?
    # call self recursively here?
    # NOTE: dep is recursive by default

    # TODO: need to use the retry function
    brew install --build-bottle "$@"
    echo "json thingy here"
    brew bottle --json "$@"
    # TODO: ^ first line in stdout is the bottle file
    # use instead of file cmd. json file has a similar name
    ls -l
    local jsonfile=$(find . -name $1*.bottle.json)
    echo "json file: $jsonfile"
    brew uninstall --ignore-dependencies "$@"
    # TODO: bottle name, json file (from "brew bottle" smoehow)
    local bottlefile=$(find . -name $1*.tar.gz)
    echo "brew install this bottlefile: $bottlefile"
    brew install "$bottlefile"
    # TODO: find json file properly
    echo "brew bottle --merge --write $jsonfile"
    # Add the bottle info into the package's formula
    brew bottle --merge --write "$jsonfile"
    echo "there should be a new bottle here now? same name?"
    ls -l

    local cachefile=$(brew --cache $1)
    echo "Copying $bottlefile to $cachefile..."
    cp -f "$bottlefile" "$cachefile"

    echo "Copying $bottlefile to $HOME/HomebrewLocal/bottles..."
    mkdir -p "$HOME/HomebrewLocal/bottles"
    cp -f "$bottlefile" "$$HOME/HomebrewLocal/bottles"

    # save bottle info file
    echo "Copying $jsonfile to $HOME/HomebrewLocal/json..."
    mkdir -p "$HOME/HomebrewLocal/json"
    cp -f "$jsonfile" "$HOME/HomebrewLocal/json"
  fi
  set -e
}

#libpng--1.6.36.el_capitan.bottle.1.tar.gz
#libpng--1.6.36.el_capitan.bottle.json
# match file with json?

# TODO: at startup, use brew info --json=v1 <bottle> and brew info --json=v1 <pkg>

install_or_upgrade libpng
brew bottle
echo "Cache `brew --cache libpng`"
