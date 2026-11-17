#!/bin/sh
# commit-msg: credit the personal account on every Madauto commit.
# Called from .husky/commit-msg (untracked, listed in .git/info/exclude).
git interpret-trailers --in-place --if-exists addIfDifferent \
  --trailer 'Co-authored-by: eliemada <72560989+eliemada@users.noreply.github.com>' "$1"
