# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 4 April 2012

#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw[min max];

my $sourceLang = shift;
my $targetLang = shift;
my $pairFile = shift;
my $initSourceFolder = shift;
my $sourceFolder = $initSourceFolder;
my $initTargetFolder = shift;
my $targetFolder = $initTargetFolder;
my $method = shift;
my $outputFolder = shift;

my $output = "$sourceLang-$targetLang-scores.txt";

my $overwrite = "true";

my $minThreshold = 0.1;
my $maxThreshold = 0.9;
my $minOverlappingWords = 1;
my $minDifferentWords = 2;

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
sub filterSentence {
	my $sentence = shift;
	$sentence =~ s/[\[\]\<\>]+/ /g;
	$sentence =~ s/\|/ /g;
	$sentence =~ s/http:[A-Za-z\/\.\-0-9\?=:;&_]* //g;
	$sentence =~ s/&nbsp;/ /g;
	$sentence =~ s/&ndash;/ /g;
	$sentence =~ s/[=\'\"\?! ,\#\(\):;\-\/\*\&]+/ /g;
	$sentence =~ s/\.[ ]+/ /g;
	$sentence =~ s/\.$//g;
	$sentence = trim($sentence);
	return $sentence;
}

sub isSentence {
	my $isSentence = 0;
	my $sentence = shift;
	my @words = split(/[ ]+/, $sentence);
	
	if (scalar @words > 3) {
		my $countUppercaseWords = 0;
		my $countNumbers = 0;
		my $i=0;
		foreach my $word (@words) {
			if ($word =~ m/[0-9]+/) {
				$countNumbers++;
			}
			if ($word =~ m/^[A-Z]+[a-z]*/) {
				if ($i != 0) {
					$countUppercaseWords++;
				}
				else {
				}
			}
			$i++;
		}
		my $totalWords = scalar @words;
		my $propOfUppercaseWords = $countUppercaseWords/$totalWords;
		my $propOfCountNumbers = $countNumbers/$totalWords;

		#if proportion of named entities are small 
		if (($propOfUppercaseWords < 0.6) && ($propOfCountNumbers < 0.4)) {
			$isSentence = 1;
		}
		else {
			#too many numbers and uppercase words --> possibly not a sentence
		}
	}
	else 	{
		#the number of words are too small --> possibly not a sentence
	}
	return $isSentence;
}
sub measure {
	my $from = shift;
	my $to = shift;
	my $score = 0;

	$from = lc $from;
	$to = lc $to;
	my @fromWords = split(/[\^\', \?\!\(\)\[\]:]+/, $from);
	my @toWords = split(/[\^\', \?\!\(\)\[\]:]+/, $to);

	my %allWords = ();
	my %fromWords = ();
	my %toWords = ();
	my %overlappingWords = ();
	my $overlapWords = 0;
	foreach my $fromWord (@fromWords) {
		if (exists $fromWords{$fromWord}) {
			#don't check for another overlap
		}
		else {
			$allWords{$fromWord} = 1;
			$fromWords{$fromWord} = 1;
			%toWords = ();

			foreach my $toWord (@toWords) {
				if (exists $toWords{$toWord}) {
					#don't check for another overlap
				}
				else {
					$allWords{$toWord} = 1;
					$toWords{$toWord} = 1;
					if ($toWord eq $fromWord) {
						$overlapWords++;
						$overlappingWords{$fromWord} = 1;
					}
				}
			}
		}
	}
	my $allWordsSize = scalar keys %allWords;
	my $fromWordsSize = scalar keys %fromWords;
	my $toWordsSize = scalar keys %toWords;
	if ($overlapWords <= $minOverlappingWords) {
		$score = 0;
	}
	#if all the words in one sentennce overlap fully with the other, then ignore the sentence <-- can't extract anything useful
	elsif ($overlapWords == $fromWordsSize) {
		$score = 0;
	}
	elsif ($overlapWords == $toWordsSize) {
		$score = 0;
	}
	#if sentences don't fully overlap but the difference is fewer than a threshold, ignore sentences
	#---> to ignore same language sentences
	elsif ((($allWordsSize - $overlapWords) <= $minDifferentWords) && (($overlapWords/$allWordsSize) > $maxThreshold)) {
		$score = 0;
	}
	else {
		$score = $overlapWords/$allWordsSize;
	}
	#print $score . "\n";
	return $score;
}
#read both files

my %stopwordsHT = ();

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
sub loadStopwords {
	my $stopwordsFile = "stopwordsList.txt";
	open INPUT, "<:encoding(utf-8)", $stopwordsFile or die "Cannot open input file $stopwordsFile: $!\n";
	while (<INPUT>) {
		my $stopword = $_;
		chomp($stopword);
		$stopwordsHT{$stopword} = 1;
	}
	close INPUT;
}
sub deleteStopwords{
	my $prevSentence = shift;
	$prevSentence = trim($prevSentence);
	$prevSentence =~ s/\[[0-9]+\]//g;
	$prevSentence =~ s/\[[a-z]+\]//g;
	my $afterSentence = "";

	my @temp = split(/\s/, $prevSentence);
	foreach my $word (@temp) {
		if (exists $stopwordsHT{$word}) {
		}
		else {
			$afterSentence .= $word . " ";
		}
	}
	return $afterSentence;
}

loadStopwords();

open PAIRINPUT, "<:encoding(utf8)", $pairFile or die "Cannot open input file $pairFile: $!\n";
open OUTPUT, ">:utf8", $output or die "Cannot open output file $output:$!\n";
print OUTPUT "Source_ID\tTarget_ID\tSource_NoOfSentence\tTarget_NoOfSentence\tValidSourceSentence\tValidTargetSentence\t" .
	"NoOfPairedSentence\tMaxScoreOfParSentences\tAvgScoreForAllPairedSentences\tAvgScoreForDocs\n";
close OUTPUT;

$sourceFolder =~ s/[\/\\]*$/-filtered-lineSeparated-anchors-replaced\//;
$sourceFolder = normalisePath($sourceFolder);
$targetFolder =~ s/[\/\\]*$/-filtered-lineSeparated-anchors-replaced\//;
$targetFolder = normalisePath($targetFolder);

while (<PAIRINPUT>) {
	chomp($_);
	my @temp = split(/\t/, $_);

	my $sourceId = $temp[0];
	my $targetId = $temp[2];

	my ($sourceFilename, $targetFilename);
	$targetFilename = $targetFolder . $targetId . "_filtered_lineSeparated_anchors_replaced_$targetLang.txt";
	$sourceFilename = $sourceFolder . $sourceId . "_filtered_lineSeparated_anchors_replaced_$sourceLang.txt";

	if ((-e $sourceFilename) && (-e $targetFilename)) {
		open OUTPUT, ">>:utf8", $output or die "Cannot open output file $output:$!\n";
		my %initialSources = ();
		my %initialTargets = ();
		my %sourceSentence = ();
		my %targetSentence = ();

		open INPUT, "<:encoding(utf-8)", $sourceFilename or die "Cannot open input file $sourceFilename: $!\n";
		my $i = 0;
		while (<INPUT>) {
			chomp($_);

			my $sentence = $_;		
			$sentence = filterSentence($sentence);
			
			if (isSentence($sentence) == 1) {
				$initialSources{$i} = $sentence;
				$sourceSentence{$i} = deleteStopwords($sentence);
			}
			else {
			}
			$i++;
		}
		close INPUT;

		open INPUT, "<:encoding(utf-8)", $targetFilename or die "Cannot open input file $targetFilename: $!\n";
		my $j = 0;
		while (<INPUT>) {
			chomp($_);
			my $sentence = $_;
			$sentence = filterSentence($sentence);
			if (isSentence($sentence) == 1) {
				$initialTargets{$j} = $sentence;
				$targetSentence{$j} = deleteStopwords($sentence);
			}
			else {
			}
			$j++;
		}
		close INPUT;

		my $sourceSentenceSize = $i;
		my $targetSentenceSize = $j;
		my $validSourceSentenceSize = 0 + keys %sourceSentence;
		my $validTargetSentenceSize = 0 + keys %targetSentence;
		
		print OUTPUT "$sourceId\t$targetId\t$sourceSentenceSize\t$targetSentenceSize\t";

		my (%fromHT, %toHT);
		my ($fromSize, $toSize);
		if ($sourceSentenceSize < $targetSentenceSize) {
			%fromHT = %sourceSentence;
			%toHT = %targetSentence;

			$fromSize = $sourceSentenceSize;
			$toSize = $targetSentenceSize;
		}
		else {
			%toHT = %sourceSentence;
			%fromHT = %targetSentence;

			$fromSize = $targetSentenceSize;
			$toSize = $sourceSentenceSize;
		}

		my $maxScore = -1;
		my $combination = "";
		my %combinationHT = ();

		#for each sentence from a smaller file, pick the best matching sentence from the bigger file
		for (my $i = 0; $i < $fromSize; $i++) {
			if (exists $fromHT{$i}) {
				for (my $j = 0; $j < $toSize; $j++) {
					if (exists $toHT{$j}) {
						my $fromPar = $fromHT{$i};
						my $toPar = $toHT{$j};
						my $score = measure($fromPar,$toPar);
						if ($score > $maxScore) {
							$maxScore = $score;
							$combination = "$i-$j";
						}
					}
				}
				#only store combination if the score != 1 (otherwise the sentence would have matched perfectly and is no use
				if (($maxScore > $minThreshold) && ($maxScore <= 1)) {
					$combinationHT{$combination} = $maxScore;
					#print $combination . "\t" . $maxScore;
				}
				$maxScore = -1;
				$combination = "";
			}
		}
		my $maxScoreOfParPairs = 0;
		my $avgScoreForAllPars = 0;

		my $initialSource = "";
		my $initialTarget = "";

		my $noOfPairedPairs = scalar keys %combinationHT;
		if ($noOfPairedPairs > 0) {
	
			foreach my $key (keys %combinationHT) {
				my @temp = split(/-/, $key);
				my $i = $temp[0];
				my $j = $temp[1];

				my ($fromPar, $toPar);
				if ($sourceSentenceSize < $targetSentenceSize) {
					$fromPar = $fromHT{$i};
					$toPar = $toHT{$j};

					$initialSource = $initialSources{$i};
					$initialTarget = $initialTargets{$j};
				}
				else {
					#if the target file was bigger, switch the value
					$fromPar = $toHT{$j};
					$toPar = $fromHT{$i};

					$initialSource = $initialSources{$j};
					$initialTarget = $initialTargets{$i};

					my $temp = $i;
					$i = $j;
					$j = $temp;
				}
				my $score = $combinationHT{$key};
				
				$avgScoreForAllPars += $score;
				if ($score > $maxScoreOfParPairs) {
					$maxScoreOfParPairs = $score;
				}
			}
			$avgScoreForAllPars = $avgScoreForAllPars/$noOfPairedPairs;
		}
		print OUTPUT "$validSourceSentenceSize\t$validTargetSentenceSize\t$noOfPairedPairs\t$maxScoreOfParPairs\t$avgScoreForAllPars\t";

		my $normalisedScore = 0;
		if (min($validSourceSentenceSize, $validTargetSentenceSize) > 0) {
			$normalisedScore = ($avgScoreForAllPars*$noOfPairedPairs)/(min($validSourceSentenceSize, $validTargetSentenceSize));
		}
		print OUTPUT "$normalisedScore\n";
		close OUTPUT;
	}
	else {
		if (-e $sourceFilename) {
		}
		else {
			#print "File $sourceFilename does not exist.\n";
		}
		if (-e $targetFilename) {
		}
		else {
			#print "File $targetFilename does not exist.\n";
		}
	}
}
close PAIRINPUT;

system("perl GetPlainWikipediaText.pl $sourceLang $targetLang $initSourceFolder $initTargetFolder $output $outputFolder");
