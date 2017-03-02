#!/bin/env bash

if [ -z "$INI_FILE" ]; then
	echo "Have not ini file"
	exit 1;
fi

idx=0
IFS=$'\n'
declare -A section_set
for line in $(cat $INI_FILE)
do
        #echo $line
        if [[ ${line:0:1} == ';' ]]; then
            continue
        fi

		case $line in
		[a-zA-Z]*=*)
            #key="$(echo $line | sed 's/\(.*\)\(=.*\)/\1/')"
            #val="$(echo $line | sed 's/\(.*=\)\(.*\)/\2/')"
            pos=$(expr index $line '=')
            key=${line:0:$pos-1}
            val=${line:$pos}
			eval ${section}[$key]="'$val'"
			;;
		\[*\])
            title="$(echo $line | sed 's/\[\(.*\)\]/\1/')"
            section="letter$(echo -n $title | md5sum | awk '{print $1}')"
            #echo ${section_set[@]}
            case "${section_set[@]}" 
                in  *"$section"*) 
                    echo "$line found" 
                    ;;
            esac
            eval unset $section
			eval declare -A $section
            idx=$(expr $idx + 1)
			section_set[$idx]="$section"
			eval ${section}['title']="'$title'"
			;;
		\#*)
			;;
		*)
			;;
		esac
done 

get_sections() {
	for i in "${section_set[@]}"; do
		echo -n  "$i "
	done
}

get_keys()
{
	section=$1
	eval keys=\${!${section}[@]};
	for i in $keys;
	do 
		echo -n "$i ";  
	done
}

get_value() {
	section=$1
	key=$2
	eval v=\${$section[$key]}
	echo -n $v 
}

#
# Here is a simple example
#
#for s in `get_sections`;
#do
#	echo "section: $s"
#	for k in `get_keys $s`;
#	do
#		v=`get_value $s $k`
#		echo "$k => [$v] "
#	done
#done
