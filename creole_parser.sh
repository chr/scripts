#!/bin/sh

# Take the contents of a file which contains creole text
# <http://en.wikipedia.org/wiki/Creole_(markup)> and convert it to HTML.

# This is free and unencumbered software released into the public domain.
# For more information, please refer to <http://unlicense.org/>

# XXX by default the first line is the <h1> title, but I'll change that ASAP.

# TODO
# * Titles with leading blank space isn't parsed.
# * Paragraphs show not remove the white space between paragraphs
#   (for readability of the generated HTML).
# * Underlined text isn't regonised.
# * Break lines (\\) aren't recognised.
# * Second or more levels in lists aren't recognised.
# * <hr>s are inside <p>s.
# * Markup inside <h#>s is parsed, though this is optional.


creole_to_html() {
range=alnum
# XXX awk is nawk
sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g;s@\\\\$@<br />@' $1 |\
awk -v nl='\n' -v inside=0 -v list=0 -v el=p -v pre=0 '
/^{{{$/,/^}}}$/ { print; pre=1; next; }
/^=/ { match($0,"^=*"); hnum=RLENGTH; match($0,"=*$");
    print "<h"hnum">"substr($0,hnum+1,RSTART-hnum-1)"</h"hnum">";
    next;
}
{   pre=0; line=$0; if ($1=="*") { el="ul" } if ($1=="#") { el="ol" }
    while (NF!=0) {
        if (inside==0) { inside=1; print "<"el">"; }
        if ($1=="*" || $1=="#") {
            line = substr($0,3);
            el="li>\n</"el
            if (list==1) {
                print "</li>";
            }
            print "<li>"; list=1;
        }
        print line;
        next;
    }
    if (inside==1) { print "</"el">"; el="p"; inside=0; list=0; }
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


if [ -n "$@" -a -f $1 ] ; then
	echo "$@" | creole_to_html $1
fi
