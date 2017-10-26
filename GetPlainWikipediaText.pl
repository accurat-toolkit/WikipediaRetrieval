# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 4 April 2012

#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;

my $sourceLang = shift;
my $targetLang = shift;
my $sourceFolder = shift;
my $targetFolder = shift;
my $listFolder = shift;
my $corporaFolder = shift;
my $threshold = 0.1;

###############
my $rawSourceFolder = $sourceFolder;
my $rawTargetFolder = $targetFolder;
$corporaFolder = normalisePath($corporaFolder);
mkdir $corporaFolder unless (-d $corporaFolder);
my $alignmentFile = $corporaFolder . "alignment-$sourceLang-$targetLang.txt";
$corporaFolder =~ s/[\/\\]*$/\/$sourceLang-$targetLang\//;
$corporaFolder = normalisePath($corporaFolder);
mkdir $corporaFolder unless (-d $corporaFolder);

$sourceFolder =~ s/[\/\\]*$/-filtered\//;
$sourceFolder = normalisePath($sourceFolder);
$targetFolder =~ s/[\/\\]*$/-filtered\//;
$targetFolder = normalisePath($targetFolder);

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
sub process {
	my $text = shift;
	$text =~ s/[\[\]]*//g;

	my $plainText = " ";

	if ($text =~ m/:/) {
		$plainText = ""; 
	}
	elsif ($text =~ m/\|/) {
		$plainText = $text;

		while ($plainText =~ m/\|/) {
			$plainText =~ s/.*\|//g;
		}
	}
	else {
		$plainText = $text;
		$plainText =~ s/[\[\]]+//g;
	}
	return $plainText;
}
sub normaliseText {
	my $text = shift;
	$text =~ s/\\/\\\\/g;
	$text =~ s/\//\\\//g;
	$text =~ s/\[/\\[/g;
	$text =~ s/\]/\\]/g;
	$text =~ s/\|/\\|/g;
	$text =~ s/\(/\\(/g;
	$text =~ s/\)/\\)/g;
	$text =~ s/\*/\\*/g;
	$text =~ s/\./\\./g;
	$text =~ s/\-/\\-/g;
	$text =~ s/\?/\\?/g;
	$text =~ s/\$/\\\$/g;
	$text =~ s/\&/\\\&/g;
	$text =~ s/\+/\\+/g;
	$text =~ s/\^/\\^/g;
	$text =~ s/\{/\\{/g;
	$text =~ s/\}/\\}/g;

	return $text;
}

open INPUTLIST, "<:encoding(utf-8)", $listFolder or die "Cannot open file $listFolder: $!\n";
open ALIGNMENT, ">:utf8", $alignmentFile or die "Cannot open $alignmentFile.\n";

while (<INPUTLIST>) {
	chomp($_);
	if ($_ =~ /Source_ID/) {
		next;
	}
	my @temp = split(/\t/, $_);
	my $sourceId = $temp[0];
	my $targetId = $temp[1];
	my $comparabilityScore = $temp[9];

	if ($comparabilityScore >= $threshold) {
		
		my $sourceFilename = $sourceFolder . $sourceId . "_filtered_$sourceLang.txt";
		mkdir $corporaFolder . $sourceLang unless (-d $corporaFolder.$sourceLang);
		my $sourceOutputFolder = $corporaFolder . $sourceLang;
		$sourceOutputFolder = normalisePath($sourceOutputFolder);
		my $sourceOutput = $sourceOutputFolder . "$sourceId\_$sourceLang.txt";

		open INPUT, "<:encoding(utf-8)", $sourceFilename or die "Cannot open file $sourceFilename: $!\n";
		open OUTPUT, ">:utf8", $sourceOutput or die "Cannot open file $sourceOutput: $!\n";

		while (<INPUT>) {
			my $line = $_;
			chomp($line);
			while ($line =~ m/(\[\[([^\[^\]]*)\]\])/) {
				my $text = $1;
				my $plainText = process($text);
				$text = normaliseText($text);
				$line =~ s/$text/$plainText/;
			}
			if ($line =~ m/[\w]+/) {
				print OUTPUT $line . "\n";
			}
		}
		close INPUT;
		close OUTPUT;

		my $targetFilename = $targetFolder . $targetId . "_filtered_$targetLang.txt";
		mkdir $corporaFolder . $targetLang unless (-d $corporaFolder.$targetLang);
		my $targetOutputFolder = $corporaFolder . $targetLang;
		$targetOutputFolder = normalisePath($targetOutputFolder);
		my $targetOutput = $targetOutputFolder . "$targetId\_$targetLang.txt";
		open INPUT, "<:encoding(utf-8)", $targetFilename or die "Cannot open file $targetFilename: $!\n";
		open OUTPUT, ">:utf8", $targetOutput or die "Cannot open file $targetOutput: $!\n";

		while (<INPUT>) {
			my $line = $_;
			chomp($line);
			while ($line =~ m/(\[\[([^\[^\]]*)\]\])/) {
				my $text = $1;
				my $plainText = process($text);
				$text = normaliseText($text);
				$line =~ s/$text/$plainText/;
			}
			if ($line =~ m/[\w]+/) {
				print OUTPUT $line . "\n";
			}
		}
		if ((-e $sourceOutput) && (-e $targetOutput)) {
			print ALIGNMENT "$sourceOutput\t$targetOutput\n";
		}

		close INPUT;
		close OUTPUT;
	}
}
close INPUTLIST;
close ALIGNMENT;