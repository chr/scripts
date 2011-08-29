#!/bin/ksh

# Give an URL as first parameter and will download a copy of the
# page with external files (in <link>s and <img>s)

# This is free and unencumbered software released into the public domain.
# For more information, please refer to <http://unlicense.org/>

usage() {
	echo usage: $(basename $0) WEBPAGE
	exit $1
}

if [[ -n $1 ]] ; then
	page=$1
else
	usage 1
fi

dir=$HTML/tmp

curl -s "$page" > $dir/index.html

if [[ $? -ne 0 ]] ; then
	usage 2
fi

dirname=$(dirname $page)
host=$(echo $page | awk -F '/' '{ print $1"//"$3 }')

fn_remote_files() {
	sed -n '/<'$1'.* '$2'/ {
	s/.*'$2'="\([^"][^"]*\)"\(.*\)/\1/gp
	}' $dir/index.html
}

links=$(fn_remote_files link href)
imgs=$(fn_remote_files img src)

# XXX uniq for $links and imgs ??
i=1
for file in $links $imgs ; do
	# XXX $host/ or $host
	if [[ $file != "$host/" ]] ; then
		if echo $file | grep '://' >/dev/null 2>&1 ; then
			file_name=$(echo $file | sed 's/[^[:alnum:].][^[:alnum:].]*/_/g')
		elif echo $file | grep '^/' >/dev/null 2>&1 ; then
		#XXX host$ = host//
			# XXX Duplicated (see above)
			file_name=$(echo $host/$file | sed 's/[^[:alnum:].][^[:alnum:].]*/_/g')
		else
			# XXX What for?
			file_name=$dirname/$file
		fi

		curl -L -s "$file" > $dir/$file_name
		sed "s|$file|$file_name|;t" $dir/index.html > $dir/index.html.tmp.$i
		cp $dir/index.html.tmp.$i $dir/index.html.tmp
		let i=i+1
		if [[ $? -eq 0 ]] ; then
			mv $dir/index.html.tmp $dir/index.html
		fi
	fi
done

# Useful to have in mind
## -k = --convert-links
#wget -E -H -k -K -p $site

chmod a+r $dir/*
