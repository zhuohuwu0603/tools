#!/usr/bin/perl -T
#
#   Author: Hari Sekhon
#   Date: 2013-06-05 14:08:20 +0100 (Wed, 05 Jun 2013)
#  $LastChangedBy$
#  $LastChangedDate$
#  $Revision$
#  $URL$
#  $Id$
#
#  vim:ts=4:sts=4:et

$DESCRIPTION = "Util to uppercase SQL / HiveQL keywords in a file or stdin";

$VERSION = "0.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/lib";
}
use HariSekhonUtils;

my $file;
my $comments;

%options = (
    "f|files=s"      => [ \$file, "File(s) to uppercase SQL from" ],
    "c|comments"     => [ \$comments, "Apply transformations even to lines with --/# comments" ],
);

get_options();

my @files = parse_file_option($file, "args are files");
my %sql_keywords;

my $fh = open_file dirname(__FILE__) . "/sql_keywords.txt";
foreach(<$fh>){
    chomp;
    s/(?:#|--).*//;
    /^\s*$/ and next;
    $_ = trim($_);
    my $sql = $_;
    $sql =~ s/\s+/\\s+/g;
    # wraps regex in (?:XISM: )
    #$sql = validate_regex($sql);
    $sql_keywords{$sql} = uc $_;
}

sub uppercase_sql ($) {
    my $string = shift;
    #$string =~ /(?:SELECT|SHOW|ALTER|DROP|TRUNCATE|GRANT|FLUSH)/ or return $string;
    unless($comments){
        $string =~ /#|--/ and return $string;
    }
    my $sep = '\s|\(|\)|\[|\]|,|;|\n|\r\n|\"|' . "'";
    foreach my $sql (sort keys %sql_keywords){
        if($string =~ /(^|$sep)($sql)($sep|$)/gi){
            my $uc_sql = uc $2;
            $string =~ s/(^|$sep)$sql($sep)/$1$uc_sql$2/gi;
        }
    }
    return $string;
}

if(@files){
    foreach my $file (@files){
        open(my $fh, $file) or die "Failed to open file '$file': $!\n";
        while(<$fh>){ print uppercase_sql($_) }
    }
} else {
    while(<STDIN>){ print uppercase_sql($_) }
}