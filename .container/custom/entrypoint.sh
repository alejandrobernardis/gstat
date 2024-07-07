#!/usr/bin/env bash
# Author: Alejandro M. BERNARDIS
# Email: alejandro.bernardis at gmail.com

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

# -----------------------------------------------------------------------------

umask 0027

# -----------------------------------------------------------------------------

: "${INSTALL:=0}"

export OCI=1

# -----------------------------------------------------------------------------

function __main() {

  local -a _args

  _args=()

  if [[ "${1:0:2}" = '--' ]]; then
    while (( "$#" )); do
      case "${1-}" in
        -i|--install) INSTALL=1;;
        --) shift; break;;
         *) _args+=("${1}");;
      esac
      shift
    done
    set -- "$@"
  fi

  if (( INSTALL )); then
    : # installation steps here ...
  fi

  exec "$@"

}

# -----------------------------------------------------------------------------

if typeset -f __main &>/dev/null; then
  __main "$@" |& tee /tmp/entrypoint.log
fi
