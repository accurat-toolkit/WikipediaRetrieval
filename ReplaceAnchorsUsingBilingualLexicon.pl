# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 4 April 2012

#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

my %bilingualLexicons = ();
my %pairs = ();

my $sourceLang = shift;
my $targetLang = shift;
my $pairsDoc = shift;
my $sourceFolder = shift;
my $targetFolder = shift;

my $overwrite = "true";

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

my $bilingualLexicon = $pairsDoc;
$bilingualLexicon =~ s/\.txt/_bilingualLexicon.txt/g;

open INPUT, "<:encoding(utf-8)", $pairsDoc or die "Cannot open file $pairsDoc: $!\n";

while (<INPUT>) {
	chomp($_);
	my $sentence = $_;
	my @temp = split(/\t/, $sentence);
	my $id1 = lc $temp[0];
	my $id2 = lc $temp[2];

	if (($id1 != 0) && ($id2 != 0)) {
		$pairs{$id1} = $id2;
	}
}
close INPUT;

open INPUT, "<:encoding(utf-8)", $bilingualLexicon or die "Cannot open file $bilingualLexicon: $!\n";

while (<INPUT>) {
	chomp($_);
	my $sentence = $_;
	my @temp = split(/\t/, $sentence);
	my $term1 = lc $temp[0];
	my $term2 = lc $temp[1];

	if (scalar @temp == 2) {
	#if (($id1 != 0) && ($id2 != 0)) {
		$term1 =~ s/_/ /g;
		
		$term2 =~ s/_/ /g;

		$bilingualLexicons{$term1} = $term2;
	}
}
close INPUT;

$sourceFolder =~ s/[\/\\]*$/-filtered-lineSeparated\//;
$sourceFolder = normalisePath($sourceFolder);

my $outputSourceFolder = $sourceFolder;
$outputSourceFolder =~ s/[\/\\]*$/-anchors-replaced\//;
$outputSourceFolder = normalisePath($outputSourceFolder);

mkdir $outputSourceFolder unless (-d $outputSourceFolder);

$targetFolder =~ s/[\/\\]*$/-filtered-lineSeparated\//;
$targetFolder = normalisePath($targetFolder);

my $outputTargetFolder = $targetFolder;
$outputTargetFolder =~ s/[\/\\]*$/-anchors-replaced\//;
$outputTargetFolder = normalisePath($outputTargetFolder);
mkdir $outputTargetFolder unless (-d $outputTargetFolder);

foreach my $id1 (keys %pairs) {
	my $id2 = $pairs{$id1};
	my $sourceFile = $sourceFolder . "$id1\_filtered\_lineSeparated\_$sourceLang.txt";
	my $outputSourceFile = $outputSourceFolder . "$id1\_filtered\_lineSeparated\_anchors\_replaced\_$sourceLang.txt";
	
	my $targetFile = $targetFolder . "$id2\_filtered\_lineSeparated\_$targetLang.txt";
	my $outputTargetFile = $outputTargetFolder . "$id2\_filtered\_lineSeparated\_anchors\_replaced\_$targetLang.txt";

	if ((-e $sourceFile) && (-e $targetFile)) {
		open INPUT, "<:encoding(utf-8)", $sourceFile or die "Cannot open file $sourceFile.\n";

		my %count = ();
		while (<INPUT>) {
                my @words = split(/\W+/);
                $count{$sourceFile} += @words;
        }
		close INPUT;

		my $numberOfWords1 = $count{$sourceFile};
		open OUTPUT, "<:encoding(utf-8)", $targetFile or die "Cannot open file $targetFile.\n";
		while (<OUTPUT>) {
                my @words = split(/\W+/);
                $count{$targetFile} += @words;
        }
		close OUTPUT;
		my $numberOfWords2 = $count{$targetFile};

		if ((-e $outputSourceFile) && ($overwrite eq "false")) {
		}
		else {
			open INPUT, "<:encoding(utf-8)", $sourceFile or die "Cannot open file $sourceFile.\n";
			open OUTPUT, ">:utf8", $outputSourceFile or die "Cannot open file $outputSourceFile.\n";
			
			my $numberOfAnchors = 0;
			my $translatedAnchors = 0;

			while (<INPUT>) {
				#print $_;
				chomp($_);
				my $sentence = $_;
				my $originalSentc = $sentence;
				my $translatedSentc = $originalSentc;

				while ($sentence =~ m/\[\[([^\[^\]]+)\]\]/) {
					#print "125: " . $sentence . "\n";
					$numberOfAnchors++;
					#print "126: " . $1 . "\n";
					my $keyword = $1;
					my $initialWord = lc $keyword;
					my $additionalWord = "";
					my $translation = "";

					if ($initialWord =~ m/\|/) {
						my @temp = split(/[ ]*\|[ ]*/, $initialWord);
						$initialWord = $temp[0];

						if (scalar @temp > 1) {
							$additionalWord = $temp[1];
						}
					}
					$keyword =~ s/\\/\\\\/g;
					$keyword =~ s/\[/\\[/g;
					$keyword =~ s/\]/\\]/g;
					$keyword =~ s/\|/\\|/g;
					$keyword =~ s/\*/\\*/g;
					$keyword =~ s/\+/\\+/g;
					$keyword =~ s/\-/\\-/g;
					$keyword =~ s/\?/\\?/g;
					$keyword =~ s/\$/\\\$/g;
					$keyword =~ s/\&/\\\&/g;
					$keyword =~ s/\^/\\^/g;
					$keyword =~ s/\(/\\(/g;
					$keyword =~ s/\)/\\)/g;
					$keyword =~ s/\{/\\{/g;
					$keyword =~ s/\}/\\}/g;
					$keyword =~ s/\./\\./g;
					

					if (exists $bilingualLexicons{$initialWord}) {
						$translation = $bilingualLexicons{$initialWord};
						#$translatedAnchors++;
					}

					if ($translation ne "") {
						$sentence =~ s/\[\[$keyword\]\]/<<$translation>>/;
						$translatedSentc =~ s/\[\[$keyword\]\]/[[$translation]]/;
					}
					else {
						#eventhough no translation can be found, still replace the format so the 'while' loop can move on
						$translatedSentc =~ s/\[\[$keyword\]\]/[[$initialWord]]/;
						$sentence =~ s/\[\[$keyword\]\]/<<$translation>>/;
					}
				}
				print OUTPUT $translatedSentc . "\n";
			}	
			close INPUT;
			close OUTPUT;

			if ((-e $outputTargetFile) && ($overwrite eq "false")) {
				print "Files $outputTargetFile exists.\n";
			}
			else {
				open INPUT, "<:encoding(utf-8)", $targetFile or die "Cannot open file $targetFile.\n";
				open OUTPUT, ">:utf8", $outputTargetFile or die "Cannot open file $outputTargetFile.\n";
				
				$numberOfAnchors = 0;
				$translatedAnchors = 0;

				while (<INPUT>) {
					chomp($_);
					my $sentence = $_;
					my $originalSentc = $sentence;
					my $translatedSentc = $originalSentc;

					while ($sentence =~ m/\[\[([^\[^\]]+)\]\]/) {
						$numberOfAnchors++;
						my $keyword = $1;
						my $initialWord = lc $keyword;
						my $additionalWord = "";
						my $translation = "";

						if ($initialWord =~ m/\|/) {
							my @temp = split(/[ ]*\|[ ]*/, $initialWord);
							$initialWord = $temp[0];
							if (scalar @temp > 1) {
								$additionalWord = $temp[1];
							}
						}
						$keyword =~ s/\\/\\\\/g;
						$keyword =~ s/\[/\\[/g;
						$keyword =~ s/\]/\\]/g;
						$keyword =~ s/\|/\\|/g;
						$keyword =~ s/\*/\\*/g;
						$keyword =~ s/\+/\\+/g;
						$keyword =~ s/\-/\\-/g;
						$keyword =~ s/\?/\\?/g;
						$keyword =~ s/\$/\\\$/g;
						$keyword =~ s/\&/\\\&/g;
						$keyword =~ s/\^/\\^/g;
						$keyword =~ s/\(/\\(/g;
						$keyword =~ s/\)/\\)/g;
						$keyword =~ s/\{/\\{/g;
						$keyword =~ s/\}/\\}/g;
						$keyword =~ s/\./\\./g;
						
						$sentence =~ s/\[\[$keyword\]\]/<<$initialWord>>/;
						$translatedSentc =~ s/\[\[$keyword\]\]/[[$initialWord]]/;
					}
					print OUTPUT $translatedSentc . "\n";
				}	
				close INPUT;
				close OUTPUT;
			}
		}
	}
	else {
		print "229: $sourceFile\n";
	}
}
