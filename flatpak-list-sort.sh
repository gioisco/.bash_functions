function find_column_index() {
  local target_column_name="$1"
  for i in "${!column_array[@]}"; do
    if [ "${column_array[$i]}" = "$target_column_name" ]; then
      echo "$((i + 1))"
      return
    fi
  done
}

function flatpak-list() {
  local columns="name,application,version,size,description"
  local sort_column_name_default="name"
  local sort_column_name=""
  local sort_column_number=""

  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --columns=*)
      if [ "${1#*=}" != "all" ]; then
        columns="${1#*=}"
      fi
      ;;
    --sort=*)
      sort_column_name="${1#*=}"
      ;;
    --help)
      echo "Usage: flatpak-list [OPTIONS]"
      echo "Get a list of flatpak packages."
      echo "Options:"
      echo "  --columns=COLS  Specify columns to display (comma-separated list)"
      echo "                  e.g., --columns=name,application,version,size"
      echo "                  If 'help' is specified, show available columns."
      echo "  --sort=COL      Specify the column to sort the list"
      echo "                  e.g., --sort=size"
      echo "                  If 'help' is specified, show available columns."
      echo "  --help          Display this help message"
      return 0
      ;;
    *)
      echo "Invalid option: $1"
      return 1
      ;;
    esac
    shift
  done

  # Check if user need and show available columns
  if [[ "$sort_column_name" == "help" || "$columns" == *"help"* ]]; then
    flatpak list --columns=help | head -n -1
    return 0
  fi

  # Split the columns string using a comma as a delimiter
  IFS=',' read -ra column_array <<<"$columns"

  # Find the index of the sorting column
  if [[ -n "$sort_column_name" ]]; then
    sort_column_number=$(find_column_index "$sort_column_name")
  fi

  # If the sorting column was specified and the index was not found, exit with an error
  if [[ -n "$sort_column_name" && -z $sort_column_number ]]; then
    echo "Error: Invalid sort column name - $sort_column_name"
    echo "The specified column name does not match any values in the columns parameter - $columns"
    return 1
  fi

  # Find the index of the default column only if sort_column_number is still empty
  if [ -z "$sort_column_number" ]; then
    sort_column_name=$sort_column_name_default
    sort_column_number=$(find_column_index "$sort_column_name")
  fi

  # Uncomment the lines below for debugging
  #echo
  #echo "DEBUG - Value of sort_column_number: [$sort_column_number]"

  # Do not sort, if no number is found even for the default column
  if [[ -z "$sort_column_number" ]]; then
    sort_command="cat"
  else
    sort_command="sort -t$'\t' -k$sort_column_number"
    if [ "$sort_column_name" == "size" ]; then
      sort_command+="h"
    fi
  fi

  # Initialize the headers variable
  local headers=""

  # Build headers with uppercase initial letter for each column
  for column in "${column_array[@]}"; do
    headers+="$(echo -e "\e[97m${column^}\e[0m")"'\t'
  done

  # Remove the last two added tab characters
  headers="${headers%??}"

  # Use sed to remove special characters from the size column
  (echo -e "$headers" && flatpak list --app --columns=$columns | tail -n +1 | sed 's/\xc2\xa0//g' | eval $sort_command) | column -t -s $'\t'
}

# _flatpak_list - Bash completion for flatpak-list function
_flatpak_list() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  opts="--columns= --sort= --help"

  # Uncomment the lines below for debugging purposes
  #echo
  #echo "Value of prev: [${prev}]"
  #echo "Value of cur: [${cur}]"
  #echo "Value of COMP_LINE: [${COMP_LINE}]"

  # Check if --sort= already contains a column name
  if [[ "${COMP_LINE}" =~ --sort=.*[a-zA-Z], ]]; then
    # No need to call flatpak complete if --sort= already contains a column name
    return 0
  fi

  # Check if the last word in the command line matches specific patterns for completion
  case "${prev}" in
  --columns* | --sort* | =*)
    # Replace "flatpak-list" with "flatpak list" and "sort" with "columns" in COMP_LINE
    COMP_LINE=$(echo "${COMP_LINE}" | sed 's/flatpak-list/flatpak list/;s/sort/columns/')
    # Use flatpak complete to get completion options and append them to COMPREPLY
    RES=($(flatpak complete "${COMP_LINE}" "${COMP_POINT}" "${cur}"))
    COMPREPLY+=("${RES[@]}")
    return 0
    ;;
  esac

  # If the command is still incomplete, do nothing (no autocompletion)
  if [[ "${cur}" != --* ]]; then
    return 0
  fi

  # Autocompletion for general options
  COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
}

# Enable autocompletion without adding a space after the completed word
complete -o nospace -F _flatpak_list flatpak-list
