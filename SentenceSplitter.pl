# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 4 April 2012

#!/usr/bin/perl 
my $lang = shift;
my $file = shift;
my $inputFolder = shift;
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

my $docId = $file;
$inputFolder =~ s/[\/\\]*$/-filtered\//;
$inputFolder = normalisePath($inputFolder);

my $input = $inputFolder . "$docId\_filtered\_$lang.txt";
my $outputFolder = $inputFolder;
$outputFolder =~ s/[\/\\]*$/-lineSeparated\//;
$outputFolder = normalisePath($outputFolder);
my $output = $outputFolder . "$docId\_filtered\_lineSeparated\_$lang.txt";
mkdir $outputFolder unless (-d $outputFolder);

if ((-e $output) && ($overwrite eq "false")) {
}
elsif (-e $input) {
	open INPUT, "<encoding(utf-8)", $input or die "Cannot open file $input: $!\n";
	open OUTPUT, ">:utf8", $output or die "Cannot open file $output: $!\n";

	while (<INPUT>) {
		chomp($_);
		my $sentence = $_;

		my @sentences = split(/\.[ ]+/, $sentence);
		my $tempSentence = "";

		foreach (@sentences) {
			my $initSentence = $_;
			if ($initSentence =~ m/\.$/) {
			}
			else {
				$initSentence .= ".";
			}
			my $plainSentence = $initSentence;
			$plainSentence =~ s/[\[\]]*//g;

			#if this sentence starts with a lower case, combine it with the previous sentence.
			if ($plainSentence =~ m/^[a-z\(\)\'\"]+.*/) {
				if ($tempSentence eq "") {
					$tempSentence = $initSentence;
				}
				else {
					$tempSentence = $tempSentence . " " .  $initSentence;
				}
			}
			#if this sentence starts with a capital case, write the previous sentence into the array.
			#unless the number of brackets doesn't match!
			else {
				if ($tempSentence ne "") {
					#if number of brackets are equal, add sentence to the array
					if ($tempSentence =~ m/^([^\[^\]]*(\[\[[^\[^\]]*\]\])*[^\[^\]]*)*$/) {
						push(@mergedSentences, $tempSentence);
						$tempSentence = $initSentence;
					}
					#if number of brackets are not the same, save the sentence to be merged with the next one.
					else {
						$tempSentence = $tempSentence . " " . $initSentence;
					}
				}
				else {
					$tempSentence = $initSentence;
				}
			}
		}
		push(@mergedSentences, $tempSentence);
		@sentences = ();
	}
	close INPUT;

	foreach my $sentence (@mergedSentences) {
		print OUTPUT $sentence . "\n";
	}
	close OUTPUT;
}
else {
	print "File doesn't exist: $input\n";
}