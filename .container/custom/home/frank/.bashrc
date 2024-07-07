# .bashrc

[[ $- != *i* ]] && return

if [ -f /etc/bashrc ]; then
  . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
  . /etc/bash.bashrc
fi

if ! [[ "$PATH" =~ "$HOME/.local/bin:" ]]; then
  PATH="$HOME/.local/bin:$HOME/.local/usr/bin:$PATH"
fi

export PATH

if [ -d ~/.bashrc.d ]; then
  for rc in ~/.bashrc.d/*; do
    if [ -f "$rc" ]; then
      . "$rc"
    fi
  done
fi

unset rc
