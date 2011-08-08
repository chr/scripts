#!/usr/bin/awk -f

# Similar to GNU cat -s

BEGIN { white=0 }

{if ( NF == 0 ) { if ( white != 1 ) { print; white=1 }
} else { print $0; white=0 }}
