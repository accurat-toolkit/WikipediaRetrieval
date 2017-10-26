# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 14 October 2011

#!/usr/bin/perl
use strict;
use warnings;
use utf8;

my $sourceLang = shift;
my $targetLang = shift;
my $alignment = shift;
my $output = $alignment;
$output =~ s/\.txt/_bilingualLexicon.txt/g;

open INPUT, "<:encoding(utf8)", $alignment or die "Cannot open file $alignment: $!\n";
open OUTPUT, ">:utf8", $output or die "Cannot open file $output: $!\n";

my %bilingualLexicons = ();
while (<INPUT>) {
	chomp($_);
	my $sentence = $_;
	my @temp = split(/\t/, $sentence);
	my $term1 = $temp[1];
	my $term2 = $temp[3];

	my $id1 = $temp[0];
	my $id2 = $temp[2];

	$term1 =~ s/\([0-9A-Za-z ]+\)//g;
	$term1 =~ s/_$//g;
	$term1 =~ s/_/ /g;
	
	$term2 =~ s/\([0-9A-Za-z ]+\)//g;
	$term2 =~ s/_$//g;
	$term2 =~ s/_/ /g;

	if (($term1 ne $term2) && ($id1 != 0) && ($id2 != 0)) {
		$bilingualLexicons{$term1} = $term2;
		print OUTPUT "$term1\t$term2\n";
	}
}
close INPUT;
close OUTPUT;