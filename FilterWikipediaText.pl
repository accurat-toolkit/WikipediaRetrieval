# Written by M. Paramita (m.paramita@sheffield.ac.uk)
# Last update 4 April 2012

#!/usr/bin/perl
use strict;
use warnings;
my $sourceLang = shift;
my $sourceFile = shift;
my $inputFolder = shift;
my $infobox = 0;
my $gallery = 0;
my $div = 0;
my $table = 0;
my $unmatchedBrackets = 0;
my $bracketsDiff = 0;
my $ignore = 0;
my $other = 0;
my $code = 0;
my $pre = 0;
my $ref = 0;
my $references = 0;
my $timeline = 0;
my $reference = 0;
my $citation = 0;
my $math = 0;
my $overwrite = "true";
my $docId = $sourceFile;

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
#$inputFolder =~ s/[\/\\]*$/\//;
my $input = $inputFolder . "$docId\_$sourceLang.txt";
my $outputFolder = $inputFolder;
$outputFolder =~ s/[\/\\]*$/-filtered\//;
$outputFolder = normalisePath($outputFolder);
my $output = $outputFolder . "$docId\_filtered\_$sourceLang.txt";
mkdir $outputFolder unless (-d $outputFolder);

if ((-e $output) && ($overwrite eq "false")) {
	print "File $input has been processed before.\n";
}
elsif (-e $input) {
	open INPUT, "<:encoding(utf-8)", $input or die "Cannot open file $input: $!\n";
	open OUTPUT, ">:utf8", $output or die "Cannot open file $output: $!\n";

	while (<INPUT>) {
		my $line = $_;
		my $originalLine = $_;
		chomp($line);
		$line =~ s/&nbsp;/ /g;
		$line =~ s/&mdash;/-/g;
		$line =~ s/&ndash;/-/g;
		$line =~ s/<br \/>/ /g;
		$line =~ s/<div>[ ]*<\/div>//g;
		$line =~ s/__NOTOC__//g;
		
		if ($line =~ m/{{refbegin.*}}/) {
			$reference = 1;
		}
		#contents below reflist is normally further reading, etc., which are useless, so ignore those
		if ($line =~ m/\{\{reflist.*\}\}/i) {
			$reference = 1;
		}	
		#normally is the closing of ref
		#if ref is not followed by any other thing, add line break in the end
		if ($ref == 1) {
			if ($line =~ m/^([^<]*<\/ref>[ ]*)$/) {
				my $text = normaliseText($1);
				$ref = 0;
				$line =~ s/$text//;
				$line .= "\n";
			}
			elsif ($line =~ m/^([^<]*<\/ref>)/) {
				my $text = normaliseText($1);
				$ref = 0;
				$line =~ s/$text//;
			}
			elsif ($line =~ m/(^.*<\/ref>)/) {
				my $text = normaliseText($1);
				$ref = 0;
				$line =~ s/$text//;
			}
			else {
				#print "97: $line\n";
				#next;
			}
		}	
		if ($reference == 1) {
			if ($line =~ m/{{refend.*}}/) {
				$reference = 0;
				$line = "";
			}
			else {
				#next;
			}
		}
		#normally is the closing of gallery
		if ($gallery == 1) {
			if ($line =~ m/<\/gallery>/) {
				$gallery = 0;
				$line = "";
				}
			else {
				#next;
			}
		}
		#normally is the closing of pre
		if ($citation == 1) {
			if ($line =~ m/\}\}/) {
				$citation = 0;
				$line = "";
			}
			else {
				#next;
			}
		}		
		#normally is the closing of infobox
		#using 'if' because it may fulfils any condition above and still be the end of an infobox
		if ($infobox == 1) {
			if ($line =~ m/^\}\}/) {
				$infobox = 0;
				$line =~ s/\}\}//; 
			}
			else {
				#next;
			}
		}	
		#normally is the closing of code
		if ($code ==1) {
			if ($line =~ m/<\/code>/) {
				$code = 0;
				$line = "";
			}
			else {
				#next;
			}
		}
		#normally is the closing of pre
		if ($pre == 1) {
			if ($line =~ m/<\/pre>/) {
				$pre = 0;
				$line = "";
			}
			else {
				#next;
			}
		}
		
		#normally is the closing of gallery
		if ($timeline == 1) {
			if ($line =~ m/<\/timeline>/) {
				$timeline = 0;
				$line = "";
			}
			else {
				#next;
			}
		}
		
		#normally is the closing of <!--
		if ($ignore == 1) {
			if ($line =~ m/(^[ ]*\-[\-]+>[ ]*)/) {
				my $text = normaliseText($1);
				$ignore = 0;
				$line =~ s/$text//;
			}
			else {
				#next;
			}
		}
		#normally is the closing of {|
		if ($other ==1) {
			if ($line =~ m/^\|\}$/) {
				$other = 0;
				$line = "";
			}
			else {
				#next;
			}
		}
		#normally is the closing of math
		if ($math ==1) {
			if ($line =~ m/<\/math>/) {
				$math = 0;
				$line = "";
			}
			else {
				#next;
			}
		}	
		if ($line =~ m/<code>.*<\/code>/) {
			$line = "";
		}
		elsif ($line =~ m/<code>.*/) {
			$line = "";
			$code = 1;
		}
		if ($line =~ m/<timeline>.*<\/timeline>/) {
			$line = "";
		}
		elsif ($line =~ m/<timeline>.*/) {
			$line = "";
			$timeline = 1;
		}
		if ($line =~ m/<pre>.*<\/pre>/) {
			$line = "";
		}
		elsif ($line =~ m/<pre>.*/) {
			$line = "";
			$pre = 1;
		}
		while ($line =~ m/(<\!\-[\-]+[^>]*[\-]+>)/) {
			my $text = normaliseText($1);
			$line =~ s/$text//;
		}
		#if ($line =~ m/^[ ]*<\!\-[\-]+[ ]*$/) {
		if ($line =~ m/([ ]*<\!\-[\-]+.*$)/) {
			my $text = normaliseText($1);
			$line =~ s/$text//;
			$ignore = 1;
		}

		#citations
		#The '''economy of India''' is the [[List of countries by GDP (nominal)|twelfth largest]] economy in the world by market exchange rates<ref name="India's GDP in 2008">{{cite web |url = http://economictimes.indiatimes.com/Mr_Rupee_pulls_India_into_1_trillion_GDP_gang/articleshow/1957520.cms|title = "'''India twelfth wealthiest boss
		#in 2005''': World Bank"|publisher = [[The Economic Times]]|accessdate = 2006-07-08}}</ref> and the [[List of countries by GDP (PPP)|fourth largest]] by [[List of countries by GDP (PPP)|purchasing power parity]] (PPP) basis.<ref>{{cite web|url=https://www.cia.gov/library/publications/the-world-factbook/rankorder/2001rank.html |title=CIA&nbsp;— The World Factbook&nbsp;— Rank Order&nbsp;— GDP (purchasing power parity) |publisher=Cia.gov |date=2009-03-05 |accessdate=2009-03-13}}</ref>

		if ($line =~ m/^\{\{.*\}\}$/) {
			$line = "";
		}
		elsif ($line =~ m/\{\{.*\}\}/) {
			$line = removeCitations($line);
		}
		elsif ($line =~ m/\{\{(citation|cite).*\}\}$/) {
			$line = "";
		}
		elsif ($line =~ m/\{\{(citation|cite book)[^\}]*$/) {
			$citation = 1;
			$line = "";
		}
		
		#print "123: $line\n";
		#<ref>[http://www.spotnet.lv/profile/?id=9448 www.spotnet.lv | | SPOTNET<!-- Bota izveidots nosaukums -->]</ref>
		while ($line =~ m/(<ref[^<]*>[^>]*<\/ref>)/) {
			my $text = normaliseText($1);
			$line =~ s/$text//g;
		}
		#print "130: $line\n";
		#this is using if because sentences may use <ref></ref> then unclosed <ref>
		#####################################################
		while ($line =~ m/(<ref[^<]*\/>)/) {
			my $text = normaliseText($1);
			$line =~ s/$text//g;
		}
		if ($line =~ m/(<ref[^<]*>.*$)/) {
			$ref = 1;
			#print "--------- Setting ref to $ref on sentence: $line\n";
			my $text = normaliseText($1);
			$line =~ s/$text//;
			#print "=======\t$line\n";
		}
		my $string = $line;
		my $countA = $string =~ s/\[//g;
		my $countB = $string =~ s/\]//g;
		
		#for images which contains texts with anchors
		if (($unmatchedBrackets == 0) && ($countA != $countB)) {
			$unmatchedBrackets = 1;
			$bracketsDiff = $countA - $countB;
		}
		elsif ($countA != $countB) {
			$bracketsDiff += $countA - $countB;
			if ($bracketsDiff == 0) {
				$unmatchedBrackets = 0;
				$line = "";
			}
		}
		if ($line =~ m/\{\|([ ]*(class|border|cellpadding|cellspacing|align|width|style)+.*)+/) {
			$line = "";
			$table += 1;
		}
		elsif ($line =~ m/<table.*/) {
			$line = "";
			$table += 1;
		}
		if ($line =~ m/^\|\}/) {
			if ($table >= 1) { 
				$table -= 1;
				$line =~ s/\|\}//; 
			}
		}
		elsif ($line =~ m/(.*<\/table>)/) {
			if ($table >= 1) { 
				$table -= 1;	
				my $text = normaliseText($1);
				$line =~ s/$text//g;		
			}
		}
		#normally is start of an unfinished infobox
		elsif ($line =~ m/^\{\{/) {
			$line = "";
			$infobox = 1;
		}
		#normally is start of an unfinished div (tables, etc.)
		elsif ($line =~ m/^<div.*>/) {
			$line = "";
			$div = 1;
		}
		#normally is the closing of infobox
		elsif ($line =~ m/<\/div>/) {
			if ($div == 1) {
				$div = 0;
				$line =~ s/<\div>//;
			}
		}
		#normally is start of an unfinished gallery (tables, etc.)
		elsif ($line =~ m/<gallery.*>/) {
			$line = "";
			$gallery = 1;
		}
		elsif ($line =~ m/^[:]*\{\|/) {
			$line = "";
			$other = 1;
		}
		if ($line =~ m/^[ ]*\|/) {
			$line = "";
		}
		#if line contains mathematical operators, delete it
		if ($line =~ m/<math>.*<\/math>/) {
			$line = "";
		}
		elsif ($line =~ m/<math>.*/) {
			$line = "";
			$math = 1;
		}
		#sentences are normaly preceded with symbols, delete these.
		if ($line =~ m/(^[\*:]+[ ]*)/) {
			$line =~ s/^[\*:]+[ ]*//g;
		}
		if ($line =~ m/(http[s]*:\/\/)/) {
			$line = "";
		}
		#if ($line =~ m/( \[[^\[^\]]+\] )/) {
			#my $text = normaliseText($1);
			#print "--346: $text\n";
			#my $plainText = $text;
			#$plainText=~ s/[\[\]]*//g;
			#$line =~ s/$text/$plainText/g;
		#}
		while ($line =~ m/(\[\[[^\[^\]^:]+:[^ ]{1}([^\[^\]]*)(((\[\[)+[^\[^\]]*(\]\])+)*[^\[^\]]*)*\]\])/) {
		#while ($line =~ m/(\[\[[^\[^\]^:]+:[^ ]+[^\[^\]]*(((\[\[)[^\[^\]]*(\]\]))*[^\[^\]]*)*\]\])/) {
			my $text = $1;
			$text = normaliseText($1);
			$line =~ s/$text//;
		}

		while ($line =~ m/(\[\[([^\[^\]^:]+:[^ ]+[^\[^\]]*)+\]\])/) {
			my $text = $1;
			$text = normaliseText($1);
			$line =~ s/$text//;
		}
		#while ($line =~ m/(\[\[([^\[^\]]*)\]\])/) {
		#	my $text = $1;
		#	#print "83: $text\n";
		#	my $plainText = process($text);
		#	$text = normaliseText($text);
		#	$line =~ s/$text/$plainText/;
		#}
		
		if ($line =~ m/(<[^>]*>)/) {
			$line =~ s/<[^>]*>//g;
		}

		#delete ' if it is preceeded or followed by space
		if ($line =~ m/^[\']+/) {
			$line =~ s/^[\']+//;
		}
		if ($line =~ m/[\']+$/) {
			$line =~ s/[\']+$//;
		}
		while ($line =~ m/(([ \(\-]+)([\']+))/) {
			my $text = normaliseText($1);
			my $replace = $2;
			$line =~ s/$text/$replace/g;
		}
		while ($line =~ m/(([\']+)([,\.\) \-]+))/) {
			my $text = normaliseText($1);
			my $replace = $3;
			$line =~ s/$text/$replace/g;
		}
		if ($line =~ m/\'[\']+/) {
			$line =~ s/\'[\']+/ /g;
		}
		if ($line =~ m/;[\']+/) {
			$line =~ s/;[\']+/ /g;
		}	
		if ($line =~ m/\(;[ ]+/) {
			$line =~ s/\(;[ ]+/\(/g;
		}
		if ($line =~ m/\(\)/) {
			$line =~ s/[ ]*\(\)//g;
		}
		if ($line =~ m/colspan/) {
			$line = "";
		}	
		#delete empty brackets
		if ($line =~ m/([ ]*\([ ,]+\))/) {
			my $text= normaliseText($1);
			$line =~ s/$text//g;
		}
		$line = trim($line);
		if (($infobox == 0) && ($div == 0) && ($gallery == 0) && ($table == 0) && ($unmatchedBrackets == 0) && ($other == 0) && ($code == 0) && ($pre == 0) && ($reference == 0) && ($citation == 0) && ($timeline == 0) && ($math == 0)) {
			#if (($ref == 1) && ($line =~ m/^[^\|]+/)) {
			if (($ignore == 1) && ($originalLine =~ /<!-/)) {
				print OUTPUT $line;
			}
			elsif (($ref == 1) && ($originalLine =~ m/<ref>/)) {
				print OUTPUT $line;
				#print "239: $line\n";
			}
			elsif ($ref == 0) {
				if ($line eq "\n") {
					print OUTPUT $line;
				}
				elsif ($line =~ m/[\w]+/) {
					#print OUTPUT $line . "\n";
					if ($line =~ m/[;=\!\#]+/) {
						####################################
						$line =~ s/^[;=\!\#]+[ ]*//;
						$line =~ s/[=]+[ ]*$//;
						print OUTPUT "$line\n";
					}
					else {
						print OUTPUT "$line\n";
					}
				}
				############################################
				elsif ($line =~ m/^[\!\-\s\{\}\.,=<>\#\)\(~\\;:\|]*$/) {
				} 
				else {
					#print $input . "\t" . $line . "\n";
					print OUTPUT $line . "\n";
				} 
			}
			else {
			}
		}
		else {
		}
	}
	close INPUT;
	close OUTPUT;
}
else {
}

sub removeRefs {
	my $line = shift;
 
	while ($line =~ m/(<ref[^<]*>[^<]+<\/ref>)/) {
		my $text = normaliseText($1);

		$line =~ s/$text//;

	}
	#print "======277: $line\n";
	return $line;
}
sub removeCitations {
	my $line = shift;
	#print $line . "\n";

	while ($line =~ m/([ ]*\{\{[^\{]*(\{\{[^\{]*\}\})*[^\{]*\}\}[, ]*)/) {

	#while ($line =~ m/(\{\{([^\{^\{]*)\}\})/) {
		my $text = normaliseText($1);
		#print "301: $text\n";
		$line =~ s/$text//;
		#print "$text\n";
	
	}
	return $line;
}
sub process {
	my $text = shift;
	$text =~ s/[\[\]]*//g;

	my $plainText = " ";
	############################################
	#if ($text =~ m/valign[ ]*=/) {
	#	$plainText = ""; 
	#}

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
sub trim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}