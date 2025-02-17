#!/usr/bin/env bash

# Copyright 2020 The cert-manager Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# shellcheck disable=SC2059

set -o nounset
set -o errexit
set -o pipefail

red=
green=
yel=
cyan=
bold=
gray=
end=
warn=
wait=
greencheck=
redcross=
if ! printenv NO_COLOR >/dev/null; then
  red="\033[0;31m"
  green="\033[0;32m"
  yel="\033[0;33m"
  cyan="\033[0;36m" # C = cyan
  bold="\033[0;37m" # B = white bold
  gray="\033[0;90m"
  end="\033[0m" # E is the "end" marker.
  warn="⚠️  "
  wait="⏳️  "
  greencheck="✅  "
  redcross="❌  "
fi

# Color stuff. Usage:
#    echo "Test in yellow!" | color "$yel"
# or if you just want some ANSI codes to be interpreted:
#    echo "${yel}Test in yellow!${end}" | color
color() {
  if printenv 1 >/dev/null; then
    # Let's prevent accidental interference from programs that also print
    # colors. Caveat: does only work on lines that end with \n. Lines that
    # do not end with \n are discarded.
    cmd='sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"'
    col=${1}
  else
    cmd='cat'
    col=
  fi
  $cmd | while IFS= read -r line; do
    # We should be using "%s" "$line", but that would disable the
    # interpretation of color characters in $line.
    #
    # shellcheck disable=SC2059
    printf "${col}${line}${end}\n"
  done
}

# https://superuser.com/questions/184307/bash-create-anonymous-fifo
PIPE=$(mktemp -u)
mkfifo "$PIPE"
exec 3<>"$PIPE"
rm "$PIPE"
exec 3>/dev/stderr

# Shows the command before running it. Usage:
#
#     trace CMD ARGUMENTS...
#
# If you wish to trace a command that contains pipes, you can run:
#
#     trace bash -c "command | command | command"
trace() {
  # This mysterious perl expression makes sure to double-quote the arguments
  # that have special characters in them, such as spaces, curly braces (since
  # zsh interprets curly braces), interogation marks, simple braces, and "*".
  # Note that no ending newline is printed in this line so that we can append
  # "<<EOF" (see below.)
  LANG=C perl -e "print \"${yel}$1${bold} \""', join(" ", map { $_ =~ / |}|{|\(|\)|\\|\*|\?/ ? "\"".$_."\"" : $_} @ARGV)',"\"\n${end}\"" -- "${@:2}" >&3

  command "$@"
}
