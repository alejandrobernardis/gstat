#!/usr/bin/env zsh
# Author: Alejandro M. BERNARDIS
# Email: alejandro.bernardis at gmail.com

local -i _c_black=0
local -i _c_maroon=1
local -i _c_green=2
local -i _c_olive=3
local -i _c_navy=4
local -i _c_purple=5
local -i _c_teal=6
local -i _c_silver=7

local -i _c_grey=8
local -i _c_red=9
local -i _c_lime=10
local -i _c_yellow=11
local -i _c_blue=12
local -i _c_fuchsia=13
local -i _c_aqua=14
local -i _c_white=15

local     _ic_ok
local     _ic_warn
local     _rps_out
local     _git_brc

: "${TIMEZONE:=America/Argentina/Buenos_Aires}"

function io::err() {
  (( "$#" )) || return 1
  LC_ALL=POSIX builtin print -P "$@" >&2
}

function io::iso8601() {
  TZ="${1:-${TIMEZONE}}" date '+%Y-%m-%dT%H:%M:%S%z';
}

function io::log() {

  (( "$#" )) || return 1

  local tst shf tab
  local -a msg pst

  while (( "$#" > 0 )); do
    shf=1
    case "${1}" in
      -t|--timestamp) tst=1;;
      -T|--no-timestamp) tst=0;;
      --tab) tab="$(printf -- "\ %.0s" {1..${2}})"; shf=2;;
      -*) ;;
       *) msg+=("${1}");;
    esac
    shift "${shf}"
  done

  if (( tst || __IO_L_TSP )); then
    pst+=("%F{240}≋ $(io::iso8601)%f")
  fi

  msg=("${msg[@]}" "${pst[@]}")
  io::err "${tab}${(j: :)msg}"

}

_rps_out="github.com/alejandrobernardis/gstat"
_git_brc=develop

print -P "\n  %K{208}%B%F{16} Icons %f%b%k\n"

_ic_ok="%F{${_c_grey}}$(echo -e '\uf00c') %F{${_c_black}}|%f"
_ic_dirty="%F{${_c_green}}$(echo -e '\uf069') %F{${_c_lime}}|%f"
_ic_warn="%F{${_c_yellow}}$(echo -e '\uf071') %F{${_c_olive}}+%f"
_ic_err="%F{${_c_red}}$(echo -e '\uf05e') %F{${_c_maroon}}|%f"
_ic_ign="%F{${_c_grey}}$(echo -e '\uf00d') %F{${_c_black}}|%f"

io::log --tab 1 "${_ic_ok} ok"
io::log --tab 1 "${_ic_dirty} dirty"
io::log --tab 1 "${_ic_warn} warning"
io::log --tab 1 "${_ic_err} error"
io::log --tab 1 "${_ic_ign} ignore"

print -P "\n  %K{208}%B%F{16} Check Mode (-c, -cc) %f%b%k\n"

io::log --tab 1 "${_ic_ok} %F{${_c_grey}}${_rps_out}: %B-%b%f"
io::log --tab 1 "${_ic_err} %F{${_c_red}}${_rps_out}: %BUnsafe%b%f"
io::log --tab 1 "${_ic_warn} %F{${_c_fuchsia}}${_rps_out}: %BLoked%b%f"
io::log --tab 1 "${_ic_ign} %F{${_c_blue}}${_rps_out}: %BIgnored%b%f"

print -P "\n  %K{208}%B%F{16} Normal Mode (-v, -w, ...) %f%b%k\n"

io::log --tab 1 "${_ic_err} %F{${_c_red}}${_rps_out}: %BUnsafe%b%f"
io::log --tab 1 "${_ic_warn} %F{${_c_fuchsia}}${_rps_out}: %BLoked%b%f"
io::log --tab 1 "${_ic_ign} %F{${_c_blue}}${_rps_out}: %BIgnored%b%f"
io::log --tab 1 "${_ic_ok} %F{${_c_grey}}${_rps_out} %B${_git_brc}%b: %B-%b%f"

_status=("%B%F{${_c_blue}}Upstream%f%b %F{${_c_silver}}(develop)%f")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

_status=("%F{${_c_blue}}Push%f %F{${_c_silver}}(develop)%f")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

_status=("%B%F{${_c_yellow}}Pull%f%b %F{${_c_silver}}(develop)%f")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

_status=("%B%F{${_c_red}}Uncommitted%f%b")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

_status=("%F{${_c_maroon}}Staged%f")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

_status=("%F{${_c_maroon}}Stashes%f")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

_status=("%B%F{${_c_fuchsia}}Conflicts%f%b")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

_status=("%F{${_c_purple}}Untracked%f")
io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"

sleep 30
