#!/bin/sh
set -eu

dump_path=':(icase,glob)**/erl_crash.dump'

case "$#" in
  0)
    matches=$(git ls-files -- "$dump_path")
    ;;
  3)
    test "$1" = --range
    head=$(git rev-parse --verify --end-of-options "$3^{commit}")
    range=$head
    case "$2" in
      *[!0]*)
        base=$(git rev-parse --verify --end-of-options "$2^{commit}")
        range="$base..$head"
        ;;
      '')
        printf '%s\n' 'Missing base for crash dump history check.' >&2
        exit 2
        ;;
    esac
    matches=$(git log --full-history -m --no-renames --diff-filter=AMT \
      --format= --name-only "$range" -- "$dump_path")
    ;;
  *)
    printf '%s\n' 'Usage: check-crash-dumps.sh [--range BASE HEAD]' >&2
    exit 2
    ;;
esac

if [ -n "$matches" ]; then
  printf '%s\n' 'Crash dump blocked. Remove erl_crash.dump from the index or affected commits.' >&2
  exit 1
fi
