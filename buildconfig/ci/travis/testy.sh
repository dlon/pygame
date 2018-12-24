#!/usr/bin/env bash

brew update
brew uninstall --force --ignore-dependencies libpng

function retry {
  local n=1
  local max=5
  local delay=2
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

function install_or_upgrade {
  # FIXME: recursion will screw up "set +e"? or is it scoped?
  local deps=""
  if (brew info "$1" | grep "(bottled)" >/dev/null); then
    deps=$(brew deps "$1")
  else
    deps=$(brew deps --include-build "$1")
  fi
  if [[ "$deps" ]]; then
    echo -n "$1 dependencies: "
    echo $deps
    while read -r dependency; do
      echo "$1: Install dependency $dependency."
      install_or_upgrade "$dependency"
    done <<< "$deps"
  fi

  if (brew ls --versions "$1" >/dev/null) && ! (brew outdated | grep "$1" >/dev/null); then
    echo "$1 is already installed and up to date."
  else
    if (brew outdated | grep "$1" >/dev/null); then
      echo "$1 is installed but outdated."
      if (brew info "$1" | grep "(bottled)" >/dev/null); then
        echo "$1: Found bottle."
        retry brew upgrade "$1"
        return 0
      fi
    else
      echo "$1 is not installed."
      if (brew info "$1" | grep "(bottled)" >/dev/null); then
        echo "$1: Found bottle."
        retry brew install "$1"
        return 0
      fi
    fi

    echo "$1: Found no bottle. Let's build one."

    retry brew install --build-bottle "$@"
    brew bottle --json "$@"
    # TODO: ^ first line in stdout is the bottle file
    # use instead of file cmd. json file has a similar name. | head -n 1 should work but fails?
    local jsonfile=$(find . -name $1*.bottle.json)
    echo "json file: $jsonfile"
    brew uninstall --ignore-dependencies "$@"
    # TODO: bottle name, json file (from "brew bottle" smoehow)
    local bottlefile=$(find . -name $1*.tar.gz)
    echo "brew install $bottlefile"
    brew install "$bottlefile"

    # Add the bottle info into the package's formula
    echo "brew bottle --merge --write $jsonfile"
    brew bottle --merge --write "$jsonfile"

    # Path to the cachefile will be updated now
    local cachefile=$(brew --cache $1)
    echo "Copying $bottlefile to $cachefile..."
    cp -f "$bottlefile" "$cachefile"

    # save cache file
    # THIS is probably wrong?
    #echo "Copying $cachefile to $HOME/HomebrewLocal/bottles..."
    #mkdir -p "$HOME/HomebrewLocal/bottles"
    #cp -f "$cachefile" "$HOME/HomebrewLocal/bottles/"

    # save bottle info
    echo "Copying $jsonfile to $HOME/HomebrewLocal/json..."
    mkdir -p "$HOME/HomebrewLocal/json"
    cp -f "$jsonfile" "$HOME/HomebrewLocal/json/"

    echo "Saving bottle path to to $HOME/HomebrewLocal/path/$1..."
    mkdir -p "$HOME/HomebrewLocal/path"
    echo "$cachefile" > "$HOME/HomebrewLocal/path/$1"
    echo "Result: $(cat $HOME/HomebrewLocal/path/$1)."
  fi
}

function check_local_bottles {
  echo "Checking local bottles in $HOME/HomebrewLocal/json/..."
  for jsonfile in $HOME/HomebrewLocal/json/*.json; do
    [ -e "$jsonfile" ] || continue
    local pkg="$(cut -d'-' -f1 <<<"$(basename $jsonfile)")"
    echo "Package: $pkg. JSON: $jsonfile."

    local filefull=$(cat $HOME/HomebrewLocal/path/$pkg)
    local file=$(basename $filefull)
    echo "$pkg: local bottle path: $filefull"

    # TODO: remove test below
    # only works if local bottle is right version? unsure
    # I think this only works after re-adding
    # NO: after adding json info to the formula, this should point to our old cached file
    #echo "brew cache test"
    #brew --cache "$pkg"

    # This might be good enough for now?
    echo "Adding local bottle into $pkg's formula."
    brew bottle --merge --write "$jsonfile"

    #echo "brew cache test"
    #brew --cache "$pkg"
    #TODO: remove. confirmed to be updated & file exists

    # TODO: check if the local bottle is still appropriate (by comparing versions and rebuild numbers)
    # if it does, re-add bottle info to formula like above
    # if it doesn't, delete cached bottle & json
    #    ie rm -f $filefull

    # TODO: compare local bottle version w/ up-to-date version
    #echo "brew info --json=v1 $pkg"
    #brew info --json=v1 "$pkg"
    ##echo "brew info --json=v1 $(brew --cache $pkg)"
    ##brew info --json=v1 $(brew --cache $pkg)
    #echo "brew info --json=v1 $filefull"
    #brew info --json=v1 "$filefull"
    # FIXME: this fails even though the file exists? may work after mergng w/ json,
    #  but that seems wrong.
  done
  echo "Done checking local bottles."
}

check_local_bottles

set +e
install_or_upgrade libpng
#install_or_upgrade fluid-synth
set -e

#cp -f "$HOME/HomebrewLocal/bottles/$file" $filefull
# TODO: brew cleanup (in before_cache):
#   first backup ALL bottles (not just ones just created) to the dir
#     "$HOME/HomebrewLocal/bottles/" (hard links?)
#   then brew cleanup && restore deleted; rm -rf "$HOME/HomebrewLocal/bottles/"
