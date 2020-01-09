#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV_XS qw ( csv );

my $inputFile = $ARGV[0];
my @lines = readLines($inputFile);
my $argsNumber = scalar @ARGV;
my @searchingPatterns = @ARGV[1..$argsNumber-1];
                         
##my @anyMatch
##my @allMatches
                             
##open (my $fileHandler, '<', $_) or die "Could not open file";


#foreach my $hash (@lines) {
#    my %_hash = %$hash;
#    print($_hash{autor}."\n");
#}

foreach my $pattern (@searchingPatterns) {
    print($pattern."\n");
}


my @report1Data = generateReportData(@lines, @searchingPatterns);

#foreach my $hash (@report1Data) {
 #   print($hash);
    
    #my %_hash = %$hash;
    #print($_hash{tekst});
#}

foreach my $record (@report1Data) {
    my %recordHash = %$record;
    
    print($recordHash{autor});
}


sub readLines {
    my $filePath = $_[0];
    my $parsedCsv = csv (in => $filePath,
                        headers => "auto",
                        quote_char => "\"");    
    return @$parsedCsv;
}

sub generateReportData {
    my @results = ();
    foreach my $line (@lines) {
        my %_line = %$line;
       # print(%line);        
    
        foreach(@searchingPatterns) {
            my $pattern = $_;
            if($_line{tekst} =~ m/$pattern/i) {
                print($_line{autor}."\n");
                push(@results, \%_line);
                last;
            }
        }       
    }
    
    return @results;
}



sub report1 {
    my @_searchingPatterns = @_;

    print("Słowa kluczowe: ");
    my $patternsJoined = join(" lub ", @_searchingPatterns);
    print($patternsJoined); 

}



