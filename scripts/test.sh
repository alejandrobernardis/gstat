#!/usr/bin/env

_output=/tmp/gstat-test.log
>"${_output}"

function gcmd() {
  local p; p=${1}; shift
  echo >&2 "${p} -> $@"
  command -p git --git-dir "${p}/.git" --work-tree "${p}" "$@" \
    |& tee -a "${_output}" &>/dev/null
}

function remote() {
  $1 remote add gh https://github.com/fboender/multi-git-status.git
  $1 fetch --all
  $1 switch master
}

_hr="$(printf -- "-%.0s" {1..80} 2>/dev/null)"

function hr() {
  echo "${_hr}"
}

dst=$(mktemp -d)
sudo rm -fr /tmp/tmp* /tmp/gstat_* | true
git config --global user.name "Frank ZAPPA"
git config --global user.email "frank.zappa@gmail.com"
git config --global init.defaultBranch 'develop'
sleep 3

echo -e '\033[38;5;247m'

for x in {1..15}; do

  r="${dst}/rep-$(printf "%02d" "${x}")"
  c="gcmd ${r}"

  mkdir -p "${r}"
  hr
  $c init

  if (( x < 10 )); then
    echo "repo ${r}" >"${r}/README.md"
    $c add --all
    $c commit --message 'Add README'
  fi

  case "${x}" in
     1) echo "changed" >>"${r}/README.md";;
     2) $c config --local --bool gstat.ignore false;;
     3) echo "" >"${r}/.git/index.lock";;
     4) echo "$(date '+%s')" >"${r}/NEW_FILE_$(date +'%F-%s').txt";;
     5) $c config --local --bool gstat.ignore true;;
     6) echo "$(date '+%s')" >"${r}/OTHER_FILE_$(date +'%F-%s').txt";;
     7) sudo chown 0:0 "${r}/.git";;
     8) touch "${r}"/{NEW,TEST,OTHER}.md
        $c add "${r}/NEW.md"
        $c commit --message "Add NEW file"
        echo "changed" >>"${r}/NEW.md"
        $c stash
    ;;
     9) remote "$c"
    ;;
    10) remote "$c"
        touch "${r}"/{NEW,TEST,OTHER}.md
        $c add "${r}/TEST.md"
    ;;
    11) remote "$c"
    ;;
    13) $c config --local --bool gstat.ignore true;;
     *);;
  esac

  $c status

done

hr && echo -e '\033[0m'
hr && gstat /tmp
hr && gstat /tmp -v
hr && gstat /tmp -c
hr && echo -e '\n\n'
