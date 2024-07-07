#!/usr/bin/env zsh
# Author: Alejandro M. BERNARDIS
# Email: alejandro.bernardis at gmail.com

# -----------------------------------------------------------------------------

typeset -r VERSION='@VERSION@'

# -----------------------------------------------------------------------------

emulate -L zsh
setopt local_options no_monitor
zmodload zsh/zutil || return 1

# -----------------------------------------------------------------------------

function io::out() {
  (( "$#" )) || return 1
  LC_ALL=POSIX builtin print -P "$@"
}

function io::err() {
  (( "$#" )) || return 1
  LC_ALL=POSIX builtin print -P "$@" >&2
}

function io::cache() {

  emulate -L zsh
  setopt local_options extended_glob

  (( "$#" )) || return 1

  local tkn
  local -a cch

  tkn="${1}"
  cch=($tkn(Nms-${2:-${GSTAT_CACHE_TTL:-5}}))

  if [[ -s "${tkn}" ]]; then
    if (( ! "${#cch}" )); then
      rm -f ${tkn} | true
    else
      command -p cat "${tkn}"
      return
    fi
  fi

  return 1

}

# -----------------------------------------------------------------------------

local -r  CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
local -r  CONFIG_FILE="/etc/gstat/gstat.conf"

local     CACHE_PATH
local     CACHE_PREFIX
local     _args_hash
local     _args_cache
local -aU _argvs

function {

  local x

  for x (
    "${HOME}/.gstat.conf"
    "${CONFIG_HOME}/gstat/gstat.conf"
    "${HOME}/.local/${CONFIG_FILE}"
    "${CONFIG_FILE}"
  ); do
    if [[ -s "${x}" ]]; then
      builtin source "${x}"
      break
    fi
  done

  _argvs=(${${(qo)@}#*:})

  if (( ! "${#_argvs}" )); then
    _argvs=("${PWD}")
  fi

  CACHE_PATH="${GSTAT_CACHE_PATH:-/tmp}"
  CACHE_PREFIX="${GSTAT_CACHE_PREFIX:-gstat_cache_}"

  _args_hash="$(md5sum <<<"${(j::)_argvs}" | cut -d' ' -f1)"
  _args_cache="${CACHE_PATH}/${CACHE_PREFIX}${_args_hash}"

} "$@"

readonly CACHE_PATH
readonly CACHE_PREFIX
readonly _args_hash
readonly _args_cache
readonly _argvs

# -----------------------------------------------------------------------------

local     _help
local     _version
local     _debug
local     _verbose
local     _check
local     _warnings
local     _fetch
local     _depth
local     _no_depth
local     _no_cache
local     _no_environ
local     _no_pull
local     _no_push
local     _no_upstream
local     _no_uncommitted
local     _no_staged
local     _no_stashes
local     _no_conflicts
local     _no_untracked
local     _config
local     _remove_cache
local -aU _path

# -----------------------------------------------------------------------------

zparseopts -D -E -F -- \
  \
    {h,-help}=_help \
    {V,-version}=_version \
    {x,-debug}=_debug \
    {c,-check}+=_check \
    {v,-verbose}=_verbose \
    {w,-warnings}+=_warnings \
  \
    {f,-fetch}=_fetch \
    {d,-depth}:=_depth \
    {D,-no-depth}=_no_depth \
    {X,-no-cache}=_no_cache \
    {E,-no-environ}=_no_environ \
  \
    {P,-no-pull}+=_no_pull \
    {H,-no-push}+=_no_push \
    {U,-no-upstream}+=_no_upstream \
    {M,-no-uncommitted}+=_no_uncommitted \
    {G,-no-staged}+=_no_staged \
    {S,-no-stashes}+=_no_stashes \
    {C,-no-conflicts}+=_no_conflicts \
    {T,-no-untracked}+=_no_untracked \
  \
    -config=_config \
    -remove-cache=_remove_cache \
  \
  || return 1

if (( "${#_help}" )); then
io::err "$(<<EOF

  %B%K{208}%F{16} ${${(U)0:t}%%.*} %f%k%b

  Show summary changes for multiple git repositories.

  %B%F{214}USAGE:%f%b

    %F{222}%B${${0:t}%%.*}%b%f (options) [path...]

  %B%F{214}OPTIONS:%f%b

    %B%F{222}Common Options:%f%b

      %F{223}-h, --help            %f-- Print a help message and exit
      %F{223}-V, --version         %f-- Display version information and exit
      %F{223}-x, --debug           %f-- Run in debug mode
      %F{223}-c, --check           %f-- Run in check mode
      %F{223}-d, --depth <value>   %f-- Descend to N directory levels below the starting points
      %F{223}-D, --no-depth        %f-- Do not drill down into directory levels
      %F{223}-X, --no-cache        %f-- Do not use existing cached
      %F{223}-E, --no-environ      %f-- Do not use existing environment variables

    %B%F{222}Git Options:%f%b

      %F{223}-f, --fetch           %f-- Updates the repository before displaying the status

    %B%F{222}Verbose Options:%f%b

      %F{223}-v, --verbose         %f-- Show all repositories
      %F{223}-w, --warnings        %f-- Show the repositories with alerts
      %F{223}-P, --no-pull         %f-- Ignore pulls
      %F{223}-H, --no-push         %f-- Ignore pushes
      %F{223}-U, --no-upstream     %f-- Ignore upstreams
      %F{223}-M, --no-uncommitted  %f-- Ignore uncommitted changes
      %F{223}-G, --no-staged       %f-- Ignore staged changes
      %F{223}-S, --no-stashes      %f-- Ignore stashes changes
      %F{223}-C, --no-conflicts    %f-- Ignore conflicts
      %F{223}-T, --no-untracked    %f-- Ignore untracked files

  %F{247}%BKeep in touch%b

  - %BIssues:%b https://github.com/alejandrobernardis/gstat/issues
  %F{240}+\n%f

EOF
)" && return 0
fi

if (( "${#_version}" )); then
io::err "$(<<EOF

  %B%F{214}Version:%f%b ${VERSION}
  %F{240}+\n%f

EOF
)" && return 0
fi

if (( "${#_remove_cache}" )); then
  local -aU cf=("${CACHE_PATH}/${CACHE_PREFIX}"*(N))
  if (( "${#cf}" )); then
    rm -f "${cf[@]}" | true
    io::err " The cache was %B%F{214}deleted%f%b."
    return
  fi
  return 1
fi

if (( "${#_config}" )); then
  mkdir -p "${CONFIG_HOME}/gstat" | true
  if cp "${CONFIG_FILE}" "${CONFIG_HOME}/gstat/" &>/dev/null; then
    io::err " The configuration file was created in: %B%F{214}${CONFIG_HOME}/gstat/%f%b"
    return
  fi
  return 1
fi

while (( "$#" )); do
  if [[ -d "${1}" ]]; then
    _path+=("${1}")
  fi
  shift
done

# =============================================================================

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

# -----------------------------------------------------------------------------

local     p r
local     _rps
local     _git_rps
local     _git_lcl
local     _git_rmt
local     _git_brc
local     _ic_ok
local     _ic_dirty
local     _ic_warn
local     _ic_error
local     _ic_ignore
local -i  _git_stg
local -i  _git_sts
local -i  _git_chg
local -i  _git_cnf
local -i  _git_unt
local -i  _git_ahd
local -i  _git_bhd
local -i  _interruption
local -a  _find_opt
local -a  _git_opt
local -aU _git_need_push
local -aU _git_need_pull
local -aU _git_need_upst
local -aU _status

# -----------------------------------------------------------------------------

if (( ! "${#_no_environ}" )); then

  local    v vv
  local -a _support_env

  _support_env=(
    GSTAT_DEPTH
    GSTAT_NO_DEPTH
    GSTAT_NO_CACHE
    GSTAT_FETCH
    GSTAT_VERBOSE
    GSTAT_WARNINGS
    GSTAT_NO_PULL
    GSTAT_NO_PUSH
    GSTAT_NO_UPSTREAM
    GSTAT_NO_UNCOMMITTED
    GSTAT_NO_STAGED
    GSTAT_NO_STASHES
    GSTAT_NO_CONFLICTS
    GSTAT_NO_UNTRACKED
  )

  while read -r v; do
    if (( ! ${_support_env[(Ie)${v}]} )); then
      io::log --tab 1 "Option %F{${_c_red}}%B${v}%b%f not supported"
      continue
    fi
    vv="${${(L)v}##*gstat}"
    case "${#${(P)vv}}" in
      0) eval "${vv}=${${(P)v}##0}";;
      2) unset "${vv}";;
      *) ;;
    esac
  done < <(command -p grep -ioP '^gstat_[a-z0-9\_]+' 2>/dev/null <(env))

  unset v vv _not_support_env

fi

# -----------------------------------------------------------------------------

if (( ! "${#_no_cache}" )) && io::cache "${_args_cache}"; then
  return
fi

# -----------------------------------------------------------------------------

typeset -ri __IO_OFF=0
typeset -ri __IO_H_D_CLR=190 # DARK
typeset -ri __IO_H_L_CLR=194 # LIGHT
typeset -ri __IO_H_S_CLR=240 # SOFT
typeset -ri __IO_L_C_CLR=206 # CRITICAL
typeset -ri __IO_L_F_CLR=204 # FATAL
typeset -ri __IO_L_E_CLR=202 # ERROR
typeset -ri __IO_L_W_CLR=226 # WARNING
typeset -ri __IO_L_N_CLR=47  # NOTICE
typeset -ri __IO_L_I_CLR=81  # INFORMATION
typeset -ri __IO_L_D_CLR=250 # DEBUG
typeset -ri __IO_L_C_LVL=1
typeset -ri __IO_L_F_LVL=2
typeset -ri __IO_L_E_LVL=3
typeset -ri __IO_L_W_LVL=4
typeset -ri __IO_L_N_LVL=5
typeset -ri __IO_L_I_LVL=6
typeset -ri __IO_L_D_LVL=7
typeset -r  __IO_L_C_CHR=C
typeset -r  __IO_L_F_CHR=F
typeset -r  __IO_L_E_CHR=E
typeset -r  __IO_L_W_CHR=W
typeset -r  __IO_L_N_CHR=N
typeset -r  __IO_L_I_CHR=I
typeset -r  __IO_L_D_CHR=D

: "${__IO_L_LVL:=${__IO_OFF}}"
: "${__IO_L_TSP:=${__IO_OFF}}"

: "${TIMEZONE:=America/Argentina/Buenos_Aires}"
: "${OWNER:=$(id -u)}"
: "${MAX_DEPTH:=5}"
: "${LIMIT_DEPTH:=15}"

function io::iso8601() {
  TZ="${1:-${TIMEZONE}}" date '+%Y-%m-%dT%H:%M:%S%z';
}

function io::level::get() {

  (( "$#" )) || (( __IO_L_LVL )) || return 1

  local ret clc

  while (( "$#" > 0 )); do
    case "${1}" in
      -c|--calculate) clc=1;;
      *) ret="${1}";;
    esac
    shift
  done

  if ! [[ "${ret}" =~ ^[0-9]+$ ]]; then
    ret="LOG_${ret:u}_LVL"
    ret="${(P)ret}"
  fi

  if (( clc )); then
    if [[ "${ret}" -lt "${__IO_L_C_LVL}" ]]; then
      ret="${__IO_L_C_LVL}"
    elif [[ "${ret}" -gt "${__IO_L_D_LVL}" ]]; then
      ret="${__IO_L_D_LVL}"
    fi
  elif [[ \
    -z "${ret}" \
    || "${ret}" -lt "${__IO_L_C_LVL}" \
    || "${ret}" -gt "${__IO_L_D_LVL}" \
  ]]; then
    ret=0
  fi

  io::out "${ret}"

}

function io::level::prefix() {

  (( "$#" )) || return 1

  local ret

  ret+="%F{${__IO_H_S_CLR}}[%f"

  case "$(io::level::get "${1}")" in
    ${__IO_L_C_LVL}) ret+=("%F{${__IO_L_C_CLR}}${__IO_L_C_CHR}%f");;
    ${__IO_L_F_LVL}) ret+=("%F{${__IO_L_F_CLR}}${__IO_L_F_CHR}%f");;
    ${__IO_L_E_LVL}) ret+=("%F{${__IO_L_E_CLR}}${__IO_L_E_CHR}%f");;
    ${__IO_L_W_LVL}) ret+=("%F{${__IO_L_W_CLR}}${__IO_L_W_CHR}%f");;
    ${__IO_L_N_LVL}) ret+=("%F{${__IO_L_N_CLR}}${__IO_L_N_CHR}%f");;
    ${__IO_L_I_LVL}) ret+=("%F{${__IO_L_I_CLR}}${__IO_L_I_CHR}%f");;
    ${__IO_L_D_LVL}) ret+=("%F{${__IO_L_D_CLR}}${__IO_L_D_CHR}%f");;
    *) ret=;;
  esac

  if (( "${#ret}" )); then
    ret+="%F{${__IO_H_S_CLR}}]%f"
    io::out "${(j::)ret}"
  fi

}

function io::log() {

  (( "$#" )) || return 1

  local lvl tst shf tab
  local -a pre msg pst

  while (( "$#" > 0 )); do
    shf=1
    case "${1}" in
      -c|--critical) lvl="${__IO_L_C_LVL}";;
      -f|--fatal) lvl="${__IO_L_F_LVL}";;
      -e|--error) lvl="${__IO_L_E_LVL}";;
      -w|--warning) lvl="${__IO_L_W_LVL}";;
      -n|--notice) lvl="${__IO_L_N_LVL}";;
      -i|--information) lvl="${__IO_L_I_LVL}";;
      -d|--debug) lvl="${__IO_L_D_LVL}";;
      -t|--timestamp) tst=1;;
      -T|--no-timestamp) tst=0;;
      --tab) tab="$(printf -- "\ %.0s" {1..${2}})"; shf=2;;
      --pre) pre+=("${2}"); shf=2;;
      --post) pst+=("${2}"); shf=2;;
      -*) ;;
       *) msg+=("${1}");;
    esac
    shift "${shf}"
  done

  if [[ "${lvl}" -le "${__IO_L_LVL}" ]]; then

    lvl="$(io::level::prefix "${lvl}")"

    if [[ -n "${lvl}" ]]; then
      pre+=("${lvl}")
    fi

    if (( tst || __IO_L_TSP )); then
      pst+=("%F{${__IO_H_S_CLR}}≋ $(io::iso8601)%f")
    fi

    msg=("${pre[@]}" "${msg[@]}" "${pst[@]}")
    io::err "${tab}${(j: :)msg}" |&tee -a "${_args_cache}"

  fi

}

function io::critical()    { io::log -c "$@"; }
function io::fatal()       { io::log -f "$@"; }
function io::error()       { io::log -e "$@"; }
function io::warning()     { io::log -w "$@"; }
function io::notice()      { io::log -n "$@"; }
function io::information() { io::log -i "$@"; }
function io::debug()       { io::log -d "$@"; }

# -----------------------------------------------------------------------------

if command -v stty &>/dev/null; then
  stty -echoctl
fi

_interruption=0
trap "_interruption=1; io::err '%F{${_c_red}} >> INTERRUPTION << %f'; exit 1;" SIGINT

# -----------------------------------------------------------------------------

if (( "${#_debug}" )); then
  trap "set +o xtrace;" 0
  set -o xtrace
fi

case "${#_check}" in
  0) if (( "${#_verbose}" )); then
       _warnings=1
     fi
  ;;
  1) unset _verbose;;
  2) _verbose=1;;
  *) ;;
esac

# -----------------------------------------------------------------------------

if (( "${#_no_depth}" || "${_depth[2]:-0}" < 0 )); then
  MAX_DEPTH=1
elif (( "${#_depth}" )); then
  MAX_DEPTH="${_depth[2]}"
fi

if (( MAX_DEPTH > LIMIT_DEPTH )); then
  MAX_DEPTH="${LIMIT_DEPTH}"
fi

# -----------------------------------------------------------------------------

_find_opt=(
  '-maxdepth' "${MAX_DEPTH}"
  '-type' 'd'
  '-not' '-path' '*/.archive/*'
  '-name' '.git'
  '-prune'
)

_ic_ok="%F{${_c_grey}}$(echo -e '\uf00c') %F{${_c_black}}|%f"
_ic_dirty="%F{${_c_green}}$(echo -e '\uf069') %F{${_c_lime}}|%f"
_ic_warn="%F{${_c_yellow}}$(echo -e '\uf071') %F{${_c_olive}}+%f"
_ic_error="%F{${_c_red}}$(echo -e '\uf05e') %F{${_c_maroon}}|%f"
_ic_ignore="%F{${_c_grey}}$(echo -e '\uf00d') %F{${_c_black}}|%f"

# -----------------------------------------------------------------------------

function gcmd() {
  command -p git "${_git_opt[@]}" "$@" 2>/dev/null
}

# -----------------------------------------------------------------------------
# Argument paths [path...]

while read -r p; do

  # ---------------------------------------------------------------------------
  # Repositories [repo... repo]

  while IFS= read -r -u7 r; do

    # clean

    _git_stg=0
    _git_sts=0
    _git_chg=0
    _git_cnf=0
    _git_unt=0
    _git_ahd=0
    _git_bhd=0
    _git_brc=''

    _git_need_push=()
    _git_need_pull=()
    _git_need_upst=()
    _status=()

    # name

    _rps="${${r##${PWD}}:h}"
    _rps_out="${_rps##*repos/}"

    # -------------------------------------------------------------------------

    # check owner

    if (( "$(stat -c %u "${r}")" != "${OWNER}" )); then
      if (( "${#_check}" || "${#_warnings}" )); then
        io::log --tab 1 "${_ic_error} %F{${_c_red}}${_rps_out}: %BUnsafe%b%f"
      fi
      continue
    fi

    # check if locked

    if [[ -e "${r}/index.lock" ]]; then
      if (( "${#_check}" || "${#_warnings}" )); then
        io::log --tab 1 "${_ic_warn} %F{${_c_fuchsia}}${_rps_out}: %BLoked%b%f"
      fi
      continue
    fi

    # path

    _git_rps="${r:h}"

    # set git gommand

    _git_opt=('--git-dir' "${r}" '--work-tree' "${_git_rps}")

    # check if ignored

    if [[ "$(gcmd config --bool gstat.ignore 2>/dev/null)" == "true" ]]; then
      if (( "${#_check}" || "${#_warnings}" )); then
        io::log --tab 1 "${_ic_ignore} %F{${_c_blue}}${_rps_out}: %BIgnored%b%f"
      fi
      continue
    fi

    # only warnings

    if (( "${#_check}" )); then
      if (( "${#_verbose}" )); then
        io::log --tab 1 "${_ic_ok} %F{${_c_grey}}${_rps_out}: %B-%b%f"
      fi
      continue
    fi

    # -------------------------------------------------------------------------

    # fecth update if required

    if (( "${#_fetch}" )); then
      gcmd fetch -q --all &>/dev/null
    fi

    # update the working tree

    gcmd update-index -q --refresh &>/dev/null

    # get current branch

    _git_brc=$(gcmd rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [[ "${_git_brc}" == 'HEAD' ]]; then
      _git_brc=TBD
    fi

    # -------------------------------------------------------------------------

    while IFS=' ' read _git_lcl _git_rmt; do

      if (( ! "${#_git_rmt}" )); then
        _git_need_upst+=("${_git_lcl}")
      fi

      IFS=$'\t' read _git_ahd _git_bhd < <(\
        gcmd \
          rev-list \
          --left-right \
          --count \
          "${_git_lcl}...${_git_rmt}" \
        2>/dev/null \
      )

      if (( _git_bhd )); then
        _git_need_pull+=("${_git_lcl}")
      fi

      if (( _git_ahd )); then
        _git_need_push+=("${_git_lcl}")
      fi

      _git_rlc="$(gcmd rev-parse --verify "${_git_lcl}" 2>/dev/null)"
      _git_rrm="$(gcmd rev-parse --verify "${_git_rmt}" 2>/dev/null)"
      _git_rbs="$(gcmd merge-base "${_git_lcl}" "${_git_rmt}" 2>/dev/null)"

      if [[ "${_git_rlc}" != "${_git_rrm}" ]]; then
        if [[ "${_git_rlc}" == "${_git_rbs}" ]]; then
          _git_need_pull+=("${_git_lcl}")
        fi
        if [[ "${_git_rrm}" == "${_git_rbs}" ]]; then
          _git_need_push+=("${_git_lcl}")
        fi
      fi

    done < <(\
      gcmd \
        for-each-ref \
        --format="%(refname:short) %(upstream:short)" \
        refs/heads \
      2>/dev/null \
    )

    while read -A _git_lcl; do
      case "${_git_lcl}" in
        (1|2)*)
          if [[ "${${_git_lcl[2]}[1]}" != "." ]]; then
            ((_git_stg++))
          fi
          if [[ "${${_git_lcl[2]}[2]}" != "." ]]; then
            ((_git_chg++))
          fi
        ;;
        'u'*) ((_git_cnf++));;
        '?'*) ((_git_unt++));;
      esac
    done < <(gcmd status --porcelain=v2 --ignore-submodules 2>/dev/null)

    _git_sts="$(gcmd stash list 2>/dev/null| wc -l)"

    if (( ! "${#_no_upstream}" && "${#_git_need_upst[@]}" )); then
      _status+=("%B%F{${_c_blue}}Upstream%f%b %F{${_c_silver}}(${_git_need_upst[@]})%f");
    fi

    if (( ! "${#_no_push}" && "${#_git_need_push[@]}" )); then
      _status+=("%F{${_c_blue}}Push%f %F{${_c_silver}}(${_git_need_push[@]})%f");
    fi

    if (( ! "${#_no_pull}" && "${#_git_need_pull[@]}" )); then
      _status+=("%B%F{${_c_yellow}}Pull%f%b %F{${_c_silver}}(${_git_need_pull[@]})%f");
    fi

    if (( ! "${#_no_uncommitted}" && _git_chg )); then
      _status+=("%B%F{${_c_red}}Uncommitted%f%b");
    fi

    if (( ! "${#_no_staged}" && _git_stg )); then
      _status+=("%F{${_c_maroon}}Staged%f");
    fi

    if (( ! "${#_no_stashes}" && _git_sts )); then
      _status+=("%F{${_c_maroon}}Stashes%f");
    fi

    if (( ! "${#_no_conflicts}" && _git_cnf )); then
      _status+=("%B%F{${_c_fuchsia}}Conflicts%f%b");
    fi

    if (( ! "${#_no_untracked}" && _git_unt )); then
      _status+=("%F{${_c_purple}}Untracked%f");
    fi

    if (( "${#_status}" )); then
      io::log --tab 1 "${_ic_dirty} %F{${_c_white}}${_rps_out}%f (%F{$_c_yellow}${_git_brc}%f): ${(j:, :)_status}"
    elif (( "${#_verbose}" )); then
      io::log --tab 1 "${_ic_ok} %F{${_c_grey}}${_rps_out} %B${_git_brc}%b: %B-%b%f"
    fi

  done 7< <(find -L "${p}" "${_find_opt[@]}" 2>/dev/null | sort -dfu)

done < <(printf '%s\n' "${_path[@]:-.}")
