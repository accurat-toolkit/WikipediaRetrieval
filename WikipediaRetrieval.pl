# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 4 April 2012

#!/usr/bin/perl
use strict;
use warnings;
use utf8;

my @parameter = ("--source", "--target", "--alignment", "--sourceFolder", "--targetFolder", "--output");
my $temp = "@ARGV";

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
my ($sourceLang, $targetLang, $alignmentFile, $sourceFolder, $targetFolder, $output);

if (($temp =~ m/--source/) && ($temp =~ m/--target/) && ($temp =~ m/--alignment/) && ($temp =~ m/--sourceFolder/) &&
	($temp =~ m/--targetFolder/) && ($temp =~ m/--output/)) {
	my $index = 0;

	for (my $i=0; $i < scalar @ARGV; $i = $i+2) {
		if ($ARGV[$i] eq "--source") {
			$sourceLang = &normalizeLang($ARGV[$i+1]);
		}
		elsif ($ARGV[$i] eq "--target") {
			$targetLang = &normalizeLang($ARGV[$i+1]);
		}
		elsif ($ARGV[$i] eq "--alignment") {
			$alignmentFile = $ARGV[$i+1];
		}
		elsif ($ARGV[$i] eq "--sourceFolder") {
			$sourceFolder = normalisePath($ARGV[$i+1]);
		}
		elsif ($ARGV[$i] eq "--targetFolder") {
			$targetFolder = normalisePath($ARGV[$i+1]);
		}
		elsif ($ARGV[$i] eq "--output") {
			$output = $ARGV[$i+1];
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
	print "     \"perl WikipediaRetrieval.pl --source [sourceLang] --target [targetLang] --alignment [alignmentFile]\n";
	print "     --sourceFolder [folderPathForSourceDocs] --targetFolder [folderPathForTargetDocs] --output [outputFolder]\n";
	print "-------------------------------------------------------------------------------------------------------\n";
	exit;
}

#load list of source document and target document
open INPUT, $alignmentFile or die "Cannot open file $alignmentFile: $!\n";
my @sourceFiles = ();
my @targetFiles = ();
while (<INPUT>) {
	my @temp = split(/\t/, $_);
	my $fileid1 = $temp[0];
	my $fileid2 = $temp[2];
	if (($fileid1 ne "0") && ($fileid2 ne "0")) {
		push(@sourceFiles, $fileid1);
		push(@targetFiles, $fileid2);
	}
}
close INPUT;

print "Extracting bilingual lexicon ...\n";
system("perl ExtractBilingualLexicon.pl $sourceLang $targetLang $alignmentFile");

print "Processing source documents ...\n";
foreach my $sourceFile (@sourceFiles) {
	system("perl FilterWikipediaText.pl $sourceLang $sourceFile $sourceFolder");
	system("perl SentenceSplitter.pl $sourceLang $sourceFile $sourceFolder");
}
print "Processing target documents ...\n";

foreach my $targetFile (@targetFiles) {
	system("perl FilterWikipediaText.pl $targetLang $targetFile $targetFolder");
	system("perl SentenceSplitter.pl $targetLang $targetFile $targetFolder");
}
print "Replacing anchors for the files ...\n";
system("perl ReplaceAnchorsUsingBilingualLexicon.pl $sourceLang $targetLang $alignmentFile $sourceFolder $targetFolder");
print "Calculating similarity scores ...\n";
system("perl ComparabilityMeasurerOnSentenceLevel.pl $sourceLang $targetLang $alignmentFile $sourceFolder $targetFolder anchor+word $output");
print "Comparable documents of language pair: \'$sourceLang-$targetLang\' have been added to the folder:\n$output\n";