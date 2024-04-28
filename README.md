# .bash-functions
Useful function for bash

# Installation

Clone this repository in your home directory.

Copy/paste the code below in your `~/.bashrc`, for scanning the `~./bash_functions` directory

```bash
# Import ~/.bash_functions
functions_directory=~/.bash_functions
_import_recursively() {
    local path=$1
    local ignore_files=(
        "README.md"
        "LICENSE"
    )

    if [ -d "$path" ]; then
        # Check if the directory name is in the ignore list
        local dirname=$(basename "$path")
        #echo "DEBUG - Dirname: $dirname"
        if [[ " ${ignore_files[@]} " =~ " $dirname " ]]; then
            return # Ignore the directory
        fi
        # Recursively explore the contents of the directory
        for i in "$path/"*; do
            _import_recursively "$i"
        done
    elif [ -f "$path" ]; then
        local filename=$(basename "$i")
        # Check if the file is not in the ignore list
        if [[ ! " ${ignore_files[@]} " =~ " $filename " ]]; then
            #echo "DEBUG - File to include: $path"
            source $path
        fi
    fi
}

if [ -d ~/.bash_functions ]; then
    _import_recursively "$functions_directory"
fi
```

# Functions

## flatpak-list

Wrapper of official command `flatpak list`, show the flatpak applications and allow to perform sorting for sigle column.

Example:
`
flatpak-list --sort=size
`

### Contributions

- (good first issue) Improve this README file
- (good first issue) Add --app as optional parameter
- multi-columns sorting
- issues with review of code, are welcome
