use HTML::Entities;

my $input = shift;
my $sourceLang = shift;
my $targetLang = shift;
my $outputFolder = shift;
my $initOutputFolder = $outputFolder;
mkdir $outputFolder unless (-d $outputFolder);

sub writeContent {
	my $content = shift;
	#$content = decode_entities($content);

	my $output = shift;
	print $output . "\n";
	open OUTPUT, ">:utf8", $output or die "Cannot open file $output: $!\n";
	print OUTPUT $content;
	close OUTPUT;
}
sub findLangLinks {
	my $id = shift;
	my $title = shift;
	my $content = shift;
	my $targetlang = shift;
	my $link = "";
	
	if ($content =~ m/\[\[$targetLang:(.*)\]\]/) {
		$link = $1;
	}
	if ($link ne "") {
		my $alignmentFile = $initOutputFolder . "alignment_$sourceLang\_$targetLang.txt";
		open OUTPUT, ">>:utf8", $alignmentFile or die "Cannot open file $alignmentFile: $!\n";
		print OUTPUT "$id\t$title\t$link\n";
		close OUTPUT;
	}
}
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

my $alignmentFile = $initOutputFolder . "alignment_$sourceLang\_$targetLang.txt";
open OUTPUT, ">:utf8", $alignmentFile or die "Cannot open file $alignmentFile: $!\n";
print OUTPUT "";
close OUTPUT;

$outputFolder .= "$sourceLang/";
#$outputFolder =~ s/[\/\\]+$/\/$sourceLang\//g;
$outputFolder = normalisePath($outputFolder);
mkdir $outputFolder unless (-d $outputFolder);

my $outputFile = "";
open INPUT, "<:encoding(utf-8)", $input or die "Cannot open file $input: $!\n";
my $i = 0;
my $pageFlag = 0;
my $title = "";
my $id = 0;
my $content = "";
while (<INPUT>) {
	my $sentence = decode_entities($_);
	chomp($sentence);

	if ($sentence =~ m/<page>/) {
		$pageFlag = 1;
	}
	elsif ($sentence =~ m/<text xml:space=\"preserve\">(.*)<\/text>$/) {
		$content .= $1 . "\n";

		if ($content =~ m/\#REDIRECT/i) {
		}
		else {
			#print "Content:\n$content\n";
			#print "----------------------------------------------------------\n";
			if (-e $output) {
				#print "File $output exists.\n";
			}
			else {
				&writeContent($content, $outputFile);
			}
			&findLangLinks($id, $title, $content, $targetLang);
		}
		$content = "";
		$contentFlag = 0;
		$title = "";
		$id = "";
	}
	elsif ($sentence =~ m/<text xml:space=\"preserve\">(.*)$/) {
		$contentFlag = 1;
		$content .= $1 . "\n";
		next;
	}
	
	if ($pageFlag == 1) {
		if ($sentence =~ m/<title>(.*)<\/title>/) {
			$title = $1;
		}
		elsif ($sentence =~ m/<id>(.*)<\/id>/) {
			$id = $1;
			$outputFile = $outputFolder . "$id\_$sourceLang.txt";
			$pageFlag = 0;
		}
	}
	if ($contentFlag == 1) {
		if ($sentence =~ /^(.*)<\/text>$/) {
			$content .= $1 . "\n";

			if ($content =~ m/\#REDIRECT/) {
			}
			elsif ($title =~ m/:[^ ]/) {
			}
			else {
				if (-e $output) {
					#print "File $output exists.\n";
				}	
				else {
					&writeContent($content, $outputFile);
				}
				&findLangLinks($id, $title, $content, $targetLang);
			}
			$content = "";
			$contentFlag = 0;
			$title = "";
			$id = "";
		}
		else {
			$content .= $sentence . "\n";
		}
	}
}
close INPUT;