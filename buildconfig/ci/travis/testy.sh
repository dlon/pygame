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
    # TODO: verify
    ls -l

    local cachefile=$(brew --cache $1)
    echo "Copying $bottlefile to $cachefile..."
    cp -f "$bottlefile" "$cachefile"

    echo "Copying $bottlefile to $HOME/HomebrewLocal/bottles..."
    mkdir -p "$HOME/HomebrewLocal/bottles"
    cp -f "$bottlefile" "$$HOME/HomebrewLocal/bottles"
    # ^probably wrong. the former will be found?

    # save bottle info file
    echo "Copying $jsonfile to $HOME/HomebrewLocal/json..."
    mkdir -p "$HOME/HomebrewLocal/json"
    cp -f "$jsonfile" "$HOME/HomebrewLocal/json"
  fi
  set -e
}

function check_local_bottles {
  for jsonfile in $HOME/HomebrewLocal/json/*.json; do
    [ -e "$jsonfile" ] || continue
    echo "Time to parse $jsonfile."
    # TODO: at startup, use brew info --json=v1 <bottle> and brew info --json=v1 <pkg>
    # TODO: check json and bottles here
    local pkg="$(cut -d'-' -f1 <<<"$jsonfile")"
    echo "package: $pkg"
    echo "brew info --json=v1 $pkg"
    brew info --json=v1 "$pkg"
    # TODO: check local bottle the same way. but how to find it?
    echo "brew info --json=v1 $(brew --cache $pkg)"
    brew info --json=v1 $(brew --cache $pkg)
    # does this work if we don't uninstall it?
  done
}

#libpng--1.6.36.el_capitan.bottle.1.tar.gz
#libpng--1.6.36.el_capitan.bottle.json
# match file with json?

check_local_bottles

install_or_upgrade libpng
echo "running brew bottle"
brew bottle
