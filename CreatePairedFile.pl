my $sourceLang = shift;
my $targetLang = shift;
my $outputFolder = shift;

my $output = $outputFolder . "$sourceLang\_$targetLang.txt";
my $sourceInput = $outputFolder . "alignment_$sourceLang\_$targetLang.txt";
my $targetInput = $outputFolder . "alignment_$targetLang\_$sourceLang.txt";

open SOURCE, "<:encoding(utf-8)", $sourceInput or die "Cannot open file $sourceInput: $!\n";
open TARGET, "<:encoding(utf-8)", $targetInput or die "Cannot open file $targetInput: $!\n";
open OUTPUT, ">:utf8", $output or die "Cannot open file $output: $!\n";

my %sourceHT = ();
my %targetHT = ();
my %titlePairs = ();

while (<SOURCE>) {
	chomp($_);
	my @temp = split(/\t/, $_);
	my $id = $temp[0];
	my $sourceTitle = $temp[1];
	my $targetTitle = $temp[2];
	$sourceHT{$sourceTitle} = $id;
	$titlePairs{$sourceTitle} = $targetTitle;
}
close SOURCE;

while (<TARGET>) {
	chomp($_);
	my @temp = split(/\t/, $_);
	my $id = $temp[0];
	my $targetTitle = $temp[1];
	my $sourceTitle = $temp[2];
	$targetHT{$targetTitle} = $id;
	$titlePairs{$sourceTitle} = $targetTitle;
}
close TARGET;

foreach my $sourceTitle (keys %titlePairs) {
	my $targetTitle = $titlePairs{$sourceTitle};
	if ((exists $sourceHT{$sourceTitle}) && (exists $targetHT{$targetTitle})) {
		print OUTPUT $sourceHT{$sourceTitle} . "\t";
		print OUTPUT $sourceTitle . "\t";
		print OUTPUT $targetHT{$targetTitle} . "\t";
		print OUTPUT $targetTitle . "\n";
	}
}
close OUTPUT;