#!/usr/bin/env perl

# USAGE:
#   text2c < hankaku.text > hankaku.c

$/ = "\r\n";	# chompされる文字を定義

sub pattern2num {
    @pattern = split(//, $_[0]);
    
    $num = 0;
    foreach (@pattern) {
	$num <<= 1;
	if (/\*/) {
	    $num++;
	}
    }

    return $num;
}

print "char hankaku[4096] = {";

while (<>) {
    chomp;
    
    if (/char 0x/) {
	print "\n  /* ", $_, " */\n  "; 
    } elsif (/^[.*]+$/) {
	printf "0x%02x, ", pattern2num($_);
    }
}

print "\n};\n";

