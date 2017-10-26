# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 2 April 2012

#!/usr/bin/perl
use strict;
use warnings;
use utf8;

sub normalisePath {
	my $path = shift;
	if ($^O eq "MSWin32") {
		$path =~ s/[\\\/]+/\\/g;	
		$path =~ s/[\\\/]*$/\\/;
	}
	else {
		$path =~ s/[\\\/]+/\//g;	
		$path =~ s/[\\\/]*$/\//;
	}
	return $path;
}
sub normalizeLang( $ ) {
    my( $lang ) = lc( $_[0] );
    my( %accuratlanguages ) = (
        #1
        "romanian" => "ro",
        "rum" => "ro",
        "ron" => "ro",
        "ro" => "ro",
        #2
        "english" => "en",
        "eng" => "en",
        "en" => "en",
        #3
        "estonian" => "et",
        "est" => "et",
        "et" => "et",
        #4
        "german" => "de",
        "ger" => "de",
        "deu" => "de",
        "de" => "de",
        #5
        "greek" => "el",
        "gre" => "el",
        "ell" => "el",
        "el" => "el",
        #6
        "croatian" => "hr",
        "hrv" => "hr",
        "hr" => "hr",
        #7
        "latvian" => "lv",
        "lav" => "lv",
        "lv" => "lv",
        #8
        "lithuanian" => "lt",
        "lit" => "lt",
        "lt" => "lt",
        #8
        "slovenian" => "sl",
        "slv" => "sl",
        "sl" => "sl"
    );
	if (exists ($accuratlanguages{$lang}) ) {
		return $accuratlanguages{$lang};
	}
	else {
		return $lang;
	}
    #return $accuratlanguages{$lang} if ( exists( $accuratlanguages{$lang} ) ); 
}
my @parameter = ("--source", "--target", "--sourcePage", "--targetPage", "--output");
my $temp = "@ARGV";
my ($sourceLang, $targetLang, $sourcePages, $targetPages, $outputFolder);

if (($temp =~ m/--source/) && ($temp =~ m/--target/) && ($temp =~ m/--sourcePage/) && ($temp =~ m/--targetPage/) &&
	($temp =~ m/--output/)) {
	my $index = 0;

	for (my $i=0; $i < scalar @ARGV; $i = $i+2) {
		if ($ARGV[$i] eq "--source") {
			$sourceLang = &normalizeLang($ARGV[$i+1]);
		}
		elsif ($ARGV[$i] eq "--target") {
			$targetLang = &normalizeLang($ARGV[$i+1]);
		}
		elsif ($ARGV[$i] eq "--sourcePage") {
			$sourcePages = $ARGV[$i+1];
		}
		elsif ($ARGV[$i] eq "--targetPage") {
			$targetPages = $ARGV[$i+1];
		}
		elsif ($ARGV[$i] eq "--output") {
			$outputFolder = $ARGV[$i+1] . "/";
			$outputFolder = normalisePath($outputFolder);
			#$outputFolder =~ s/\\/\//g;
			#$outputFolder =~ s/[\/\\]+$/\//g;
		}
		else {
			print "81: Format $ARGV[$i] is not recognized. Please correct the format and restart the tool.\n";
			exit();
		}
	}
}
else
{ 
	print "Missing parameter:\n";
	foreach my $par (@parameter) {
	  if ($temp !~ /$par/) {
		  print "     $par\n";
	  }
	}
	print "Please run the tool based on the guideline below.\n\n";
	print "-------------------------------------------------------------------------------------------------------\n";
	print "To run this script, please use the following arguments:\n\n";
	print "     \"perl WikipediaExtractor.pl --source [sourceLang] --target [targetLang] --sourcePage\n";
	print "     [pageOfSourceLang] --targetPage [pageOfTargetLang] --output [outputFolder]\n";
	print "-------------------------------------------------------------------------------------------------------\n";
	exit;
}

print "Extracting Wikipedia documents from source language...\n";
system("perl ExtractWikipediaPages.pl $sourcePages $sourceLang $targetLang $outputFolder");
print "Extracting Wikipedia documents from target language...\n";
system("perl ExtractWikipediaPages.pl $targetPages $targetLang $sourceLang $outputFolder");
print "Create paired file...\n";
system("perl CreatePairedFile.pl $sourceLang $targetLang $outputFolder");
my $tempAlignment1 = $outputFolder . "alignment_$sourceLang\_$targetLang.txt";
my $tempAlignment2 = $outputFolder . "alignment_$targetLang\_$sourceLang.txt";
my $outputAlignment = $outputFolder . "$sourceLang\_$targetLang.txt";
print "The extracted documents are written in $outputFolder and alignment file is stored in $outputAlignment.\n";