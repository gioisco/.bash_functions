#!/bin/bash

set -e

dir=$1
cmd="ls -tr $dir | grep -v $(basename "$0")"

function get_zeros_to_prepend() {
  local current_counter="$1"
  local max_counter_length="${#n_files}"
  local zeros=""

  if (( current_counter < 1 || current_counter > n_files )); then
      echo "Error: Invalid counter value"
      return 1
  fi

  local digit_counter="${#current_counter}"

  if (( digit_counter < max_counter_length )); then
      local num_zeros=$(( max_counter_length - digit_counter ))
      zeros=$(printf "%0${num_zeros}d" 0)
  fi

	echo "$zeros"
}

echo "Working on:"
realpath "$dir"
dir=$(realpath "$dir")
n_files=$(eval "$cmd" | wc -l)

echo
echo "Rename $n_files files:"
counter=1

# Read the output of eval "$cmd" line by line (safest method)
eval "$cmd" | while IFS= read -r filename; do
  if [[ $filename == "0"* ]]; then
      echo "Already renamed"
      exit
  fi

  new_name="$(get_zeros_to_prepend $counter)$counter. $filename"
  printf "Rename: '%s' \tto: '%s'\n" "$filename" "$new_name"

  counter=$((counter+1))
done | column -ts $'\t'


