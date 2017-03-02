#!/bin/bash

source iniParser.bash

echo "== Parsed Config =="

for s in `get_sections`;
do
    echo "[$s]"
    for k in `get_keys $s`;
    do
        v=`get_value $s $k`
		echo "$k => $v "
    done
done
