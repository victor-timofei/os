#!/usr/bin/bash

# Generates a symbol redefenition file for `ojbcopy`

# The symbol redefenition filename
sym_redefinition_filename=$1

# The original filename from which the object was created
origin_filename=$2

# The symbol prefix
prefix=$3

path_prefix=$(readlink -f "${origin_filename}" | sed -E 's#/|\.#_#g')
syms_prefix="_binary_${path_prefix}"

echo "${syms_prefix}_start ${prefix}_binary__start" >> ${sym_redefinition_filename}
echo "${syms_prefix}_end ${prefix}_binary__end"     >> ${sym_redefinition_filename}
echo "${syms_prefix}_size ${prefix}_binary__size"   >> ${sym_redefinition_filename}
