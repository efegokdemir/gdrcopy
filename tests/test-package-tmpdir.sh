#!/bin/bash
# Exercise the temporary-directory assignment used by both package builders.
set -eu
repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
custom_tmp="$scratch/tmp dir"
mkdir "$custom_tmp"

for script in packages/build-rpm-packages.sh packages/build-deb-packages.sh; do
    assignment=$(grep '^tmpdir=`mktemp -d ' "$repo/$script")
    [ -n "$assignment" ] || { echo "$script has no tmpdir assignment" >&2; exit 1; }

    TMPDIR="$custom_tmp"
    export TMPDIR
    tmpdir=
    eval "$assignment"
    case "$tmpdir" in "$custom_tmp"/gdr.*) ;; *) echo "$script ignored TMPDIR with spaces: $tmpdir" >&2; exit 1 ;; esac
    [ -d "$tmpdir" ]
    rm -rf "$tmpdir"

    unset TMPDIR
    tmpdir=
    eval "$assignment"
    case "$tmpdir" in /tmp/gdr.*) ;; *) echo "$script fallback changed: $tmpdir" >&2; exit 1 ;; esac
    [ -d "$tmpdir" ]
    rm -rf "$tmpdir"
done

echo "package TMPDIR regressions passed"
