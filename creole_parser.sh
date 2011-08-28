#!/bin/ksh

# Take the contents of a file which contains creole text
# <http://en.wikipedia.org/wiki/Creole_(markup)> and convert it to HTML.

# This is free and unencumbered software released into the public domain.
# For more information, please refer to <http://unlicense.org/>

# TODO
# * Titles with leading blank space aren't parsed.
# * Paragraphs show not remove the white space between paragraphs
#   (for readability of the generated HTML).
# * Break lines (\\) are, though no (actual) blank line is added.
# * Second or more levels in lists are recognised but generates non XHTML.
# * <hr>s are inside <p>s.
# * Markup inside <h#>s is parsed, though this is optional.


usage() {
	echo usage: $(basename $0) FILE
	exit 1
}

creole_to_html() {
range=alnum
# XXX awk is nawk
sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g;s@\\\\@<br />@' $1 |\
awk -v nl='\n' -v inside=0 -v list=0 -v el=p -v pre=0 '
/^{{{$/,/^}}}$/ { print; pre=1; next; }

################################ Titles ########################################
/^=/ { match($0,"^=*"); hnum=RLENGTH; match($0,"=*$");
    print "<h"hnum">"substr($0,hnum+1,RSTART-hnum-1)"</h"hnum">";
    next;
}

# XXX Not XTHML
/^[#*] /,/^$/ {
while ( $0 !~ /^$/ ) {
	if ( inside_li == 0 ) {
		if ( $1 ~ /#/ ) {
			list = "ol"
		} else {
			list = "ul"
		}
		print "<"list">"
		level = 1
	}
	inside_li = 1
	match($0,"^[#*]*")
	lnum=RLENGTH
	line = substr($0,lnum+1);
	if (lnum>level) { start_li="<"list">\n" ; level++ }
	else { start_li = "" }
	if (lnum<level) { start_li="</"list">\n" ; level-- }
	print start_li "<li>" line end_li
	next
}
print "</"list">"
inside_li = 0
}

{   pre=0; line=$0;
    while (NF!=0) {
        if (inside==0) { inside=1; print "\n<"el">"; }
        print line;
        next;
    }
    if (inside==1) { print "</"el">"; el="p"; inside=0 }
}
END { if (pre==0) { print "</"el">"nl } }' |\
sed "/^{{{$/,/^}}}$/ ! {s@^//@ //@;
  s@\*\*\([[:$range:]]\)@<strong>\1@g;s@\([[:$range:]]\)\*\*@\1</strong>@g;
  s@ //\([[:$range:]]\)@ <em>\1@g;s@\([[:$range:]]\)//@\1</em>@g;
  s@##\([[:$range:]]\)@<tt>\1@g;s@\([[:$range:]]\)##@\1</tt>@g
  }" | sed 's@^{{{$@<pre>@;s@^}}}$@</pre>@;s@^[[:space:]]*----[- ]*$@<hr />@' |\
sed 's@\([hfg][[:alpha:]]*://[^ |<>]*[a-zA-Z0-9/]\)@<a href="\1">\1</a>@g' |\
sed 's@\[\[\(<a href="[^ ]*">\)[^ ]*\(</a>\)|\([^[]*\)\]\]@\1\3\2@g'
}


if [[ -n "$@" && -f "$1" ]] ; then
	echo "$@" | creole_to_html $1
else
	usage
fi
