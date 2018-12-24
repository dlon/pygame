#!/usr/bin/env bash

source "buildconfig/ci/travis/.travis_osx_before_install.sh" --no-installs

# cache bottles with long build times

set +e
install_or_upgrade boost & prevent_stall
set -e