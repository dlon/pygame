#!/usr/bin/env bash

brew update
brew uninstall --force --ignore-dependencies libpng

function install_or_upgrade {
  set +e
  # TODO: recursively for dependencies (brew deps)
  # FIXME: recursion will fuck up "set +e"? or is it scoped?
  # if no (bottled) in brew info <pkg>, run brew deps --include-build (includes build dependencies)
  # NOTE: deps is recursive by default
  echo "brew info $1"
  brew info "$1"
  if (brew info "$1" | grep "(bottled)" >/dev/null); then
    echo "BREW DEPS $1"
    brew deps "$1"
  else
    echo "BREW DEPS $1 -- include-build"
    brew deps --include-build "$1"
  fi

  # if a bottle is available, brew install or brew upgrade

  if (brew ls --versions "$1" >/dev/null) && (brew outdated | grep "$1" >/dev/null); then
    echo "$1 is already installed and up to date."
  else
    if (brew outdated | grep "$1" >/dev/null); then
      echo "$1 is installed but outdated."
      if (brew info "$1" | grep "(bottled)" >/dev/null); then
        echo "$1: Found bottle."
        brew upgrade "$1"
        set -e
        return 0
      fi
    else
      echo "$1 is not installed."
      if (brew info "$1" | grep "(bottled)" >/dev/null); then
        echo "$1: Found bottle."
        brew install "$1"
        set -e
        return 0
      fi
    fi

    echo "$1: Found no bottle. Let's build one."

    # TODO: need to use the retry function
    brew install --build-bottle "$@"
    echo "json thingy here"
    brew bottle --json "$@"
    # TODO: ^ first line in stdout is the bottle file
    # use instead of file cmd. json file has a similar name. | head -n 1 should work but fails?
    ls -l
    local jsonfile=$(find . -name $1*.bottle.json)
    echo "json file: $jsonfile"
    brew uninstall --ignore-dependencies "$@"
    # TODO: bottle name, json file (from "brew bottle" smoehow)
    local bottlefile=$(find . -name $1*.tar.gz)
    echo "brew install this bottlefile: $bottlefile"
    brew install "$bottlefile"
    # TODO: find json file properly

    # Add the bottle info into the package's formula
    echo "brew bottle --merge --write $jsonfile"
    brew bottle --merge --write "$jsonfile"
    # Path to the cachefile will be updated now?
    local cachefile=$(brew --cache $1)
    echo "Copying $bottlefile to $cachefile..."
    cp -f "$bottlefile" "$cachefile"

    # save cache file
    # THIS is probably wrong?
    #echo "Copying $cachefile to $HOME/HomebrewLocal/bottles..."
    #mkdir -p "$HOME/HomebrewLocal/bottles"
    #cp -f "$cachefile" "$HOME/HomebrewLocal/bottles/"
    # should use cache path to save it in my own location?

    # save bottle info
    echo "Copying $jsonfile to $HOME/HomebrewLocal/json..."
    mkdir -p "$HOME/HomebrewLocal/json"
    cp -f "$jsonfile" "$HOME/HomebrewLocal/json/"

    echo "Saving bottle path to to $HOME/HomebrewLocal/path/$1"
    mkdir -p "$HOME/HomebrewLocal/path"
    echo "$cachefile" > "$HOME/HomebrewLocal/path/$1"
    echo "RESULT (cat):"
    cat $HOME/HomebrewLocal/path/$1
  fi
  set -e
}

function check_local_bottles {
  echo "checking local bottles in $HOME/HomebrewLocal/json/"
  for jsonfile in $HOME/HomebrewLocal/json/*.json; do
    [ -e "$jsonfile" ] || continue
    echo "Time to parse $jsonfile."
    # TODO: at startup, use brew info --json=v1 <bottle> and brew info --json=v1 <pkg>
    # TODO: check json and bottles here
    local pkg="$(cut -d'-' -f1 <<<"$(basename $jsonfile)")"
    echo "package: $pkg"
    echo "brew info --json=v1 $pkg"
    brew info --json=v1 "$pkg"

    echo "Reading bottle path from $HOME/HomebrewLocal/path/$pkg"
    local file=$(cat $HOME/HomebrewLocal/path/$pkg)
    echo "result: $file"

    # TODO: check local bottle the same way. but how to find it?
    #echo "brew info --json=v1 $(brew --cache $pkg)"
    #brew info --json=v1 $(brew --cache $pkg)
    echo "brew info --json=v1 $file"
    brew info --json=v1 $file
    # does this work if we don't uninstall it?

    #TODO: check brew --cache
    # only works if local bottle is right version? unsure
    # I think this only works after re-adding
    # NO: after adding json info to the formula, this should point to our old cached file
    echo "brew cache test"
    brew --cache "$pkg"

    # TODO: check if the local bottle is still appropriate (by comparing versions and rebuild numbers)
    # if it does, re-add bottle info to formula like above
    # if it doesn't, delete cached bottle & json
    #    we should have the path stored to the cache. brew --cache won't work here
    #    TODO: read from path/pkg
    #echo "Reading bottle path from $HOME/HomebrewLocal/path/$pkg"
    #local file=$(cat $HOME/HomebrewLocal/path/$pkg)
    #echo "result: $file"
  done
  echo "done checking local bottles"
}

#libpng--1.6.36.el_capitan.bottle.1.tar.gz
#libpng--1.6.36.el_capitan.bottle.json
# match file with json?

check_local_bottles

# TODO: if using brew cleanup, restore cache files

install_or_upgrade libpng
echo "running brew bottle"
brew bottle
