#!/usr/bin/perl -T
#
#  Author: Hari Sekhon
#  Date: 2013-12-19 18:21:24 +0000 (Thu, 19 Dec 2013)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

$DESCRIPTION = "Prints a cool Matrix effect in your terminal

Thanks to my colleagues Chris Greatbanks and Sameer Charania at BSkyB for sharing this cool web tip with me on which I decided to base this code:

http://www.climagic.org/coolstuff/matrix-effect.html";

$VERSION = "0.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/lib";
}
use HariSekhonUtils;
use Time::HiRes 'sleep';
use Term::ReadKey 'GetTerminalSize';

# Original Shell Trick:
#
# echo -e "\e[1;40m" ; clear ; while :; do echo $LINES $COLUMNS $(( $RANDOM % $COLUMNS)) $(( $RANDOM % 72 )) ;sleep 0.05; done|gawk '{ letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"; c=$4; letter=substr(letters,c,1);a[$3]=0;for (x in a) {o=a[x];a[x]=a[x]+1; printf "\033[%s;%sH\033[2;32m%s",o,x,letter; printf "\033[%s;%sH\033[1;37m%s\033[0;0H",a[x],x,letter;if (a[x] >= $1) { a[x]=0; } }}'
#
# More clearly:
#
# echo -e "\e[1;40m";
# clear; 
# while :; do
#     echo $LINES $COLUMNS $(( $RANDOM % $COLUMNS)) $(( $RANDOM % 72 )) ;sleep 0.05; done |
#     gawk '{
#         letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()";
#         c=$4;
#         letter=substr(letters,c,1);
#         a[$3]=0;
#         for (x in a) {
#             o=a[x];
#             a[x]=a[x]+1; 
#             printf "\033[%s;%sH\033[2;32m%s",o,x,letter; 
#             printf "\033[%s;%sH\033[1;37m%s\033[0;0H",a[x],x,letter;
#             if(a[x] >= $1){
#                 a[x]=0;
#             }
#         }
#     }'

# Perl Reimplementation, much more readable with explanation comments:

get_options();
my ($columns, $lines, $wpixels, $hpixels) = GetTerminalSize();

$lines   = validate_int($lines,   'Terminal Lines',   0, 1000);
$columns = validate_int($columns, 'Terminal Columns', 0, 5000);
vlog_options "Terminal Pixels", "${wpixels}x${hpixels}";

my @chars = ("A".."Z", "a".."z", 0..9, split('', '@#$%^&*()'));
# Actually looks better without all the ascii symbols
#@chars = ();
#for(my $ascii=33; $ascii < 127; $ascii++){
#    push(@chars, chr($ascii));
#}

my $ESC = "\033";

my $system_failure = "  ==> SYSTEM FAILURE <==  ";

autoflush();

set_timeout($timeout, sub { printf "${ESC}[%s;%sH${ESC}[0;40m${ESC}[1;37m%s${ESC}[$lines;${columns}H", int($lines / 2.0) , int($columns / 2.0 - (length($system_failure) / 2.0)), $system_failure; exit 0; } );

# sets terminal to bold black - done per printf
#print "${ESC}[1;40m";
# clear screen     # cursor position to 0,0
print "${ESC}[2J"; # ${ESC}[0;0H";
my (%cursor, $char, $line, $column);
while(1){
    $cursor{int(rand $columns)} = 0;
    foreach $column (keys %cursor){
        $char = $chars[rand @chars];
        $line = $cursor{$column};
        $cursor{$column} += 1;
                # ESC cursor position to $line, $column
                # ESC bold;black   bg (1;40)
                # ESC faint;green  fg (2;32)  print $char
                # ESC cursor position to line $a{$column}, $column
                # ESC normal;black bg (0;40) - to not dim white fg chars, allow them to stand out more
                # ESC bold;white   fg (1;37)  print $char
        printf "${ESC}[%s;%sH"  .
               "${ESC}[1;40m"   .
                # XXX: in Putty faint "2;" comes out with an underline ruining the effect, set to "0;" for now
               "${ESC}[0;32m%s" .
               "${ESC}[%s;%sH"  .
               "${ESC}[0;40m"   .
               "${ESC}[1;37m%s" ,
                $line, $column,
                $char,
                $cursor{$column}, $column,
                $char;
        # reset to 0,0 coordinates
        #printf "${ESC}[0;0H";
        if($cursor{$column} >= $lines){
            # XXX: changed faint "2;" to "0;" here as well, add detection to solve this based on terminal later
            printf "${ESC}[%s;%sH${ESC}[1;40m${ESC}[0;32m%s", $cursor{$column}, $column, $chars[rand @chars];
            $cursor{$column} = 0;
        }
    }
    sleep 0.0565;
}
