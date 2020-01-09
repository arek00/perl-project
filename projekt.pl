#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use DateTime::Format::Strptime;
use Text::CSV_XS qw ( csv );

my $inputFile = $ARGV[0];
my @lines = readLines($inputFile);
my $argsNumber = scalar @ARGV;
my @searchingPatterns = @ARGV[1..$argsNumber-1];

say("Used patterns");                         
foreach my $pattern (@searchingPatterns) {
    print($pattern."\n");
}

my @report1Data = generateReport1Data(@lines, @searchingPatterns);
@report1Data = parseDates(@report1Data);
@report1Data = sort {$a->{data} cmp $b->{data}} @report1Data;
@report1Data = datesToString(@report1Data);

say("Mapped dates:");
say("Data"
    ."\t"
    ."Autor"
    ."\t"
    ."Czasopismo");
foreach my $record (@report1Data) {
    my %recordHash = %$record;
    
    say($recordHash{data}
        ."\t"
        .$recordHash{autor}
        ."\t"
        .$recordHash{gazeta});
}


sub readLines {
    my $filePath = $_[0];
    my $parsedCsv = csv (in => $filePath,
                        headers => "auto",
                        quote_char => "\"");    
    return @$parsedCsv;
}

sub generateReport1Data {
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

sub parseDate {
    my $date = $_[0];
    say("Date to parse: ".$date);
    
    $date =~ s/(\d{1,2})(st|nd|rd|th),/$1/;
    say("Date: ".$date);
    
    my $datePattern = "%B %e %Y";
    my $parser = DateTime::Format::Strptime->new(pattern=>$datePattern, locale=>"en_US");
    my $datetime = $parser->parse_datetime($date) or die;
    
    return $datetime;
}

sub dateToString {
    print($_[0]);
    my $dateStringPattern = "%d.%m.%Y";
    my $date = $_[0];
    my $strDateTime = DateTime::Format::Strptime::strftime($dateStringPattern, $date) or die;
    return $strDateTime;
}

sub parseDates {
    my @array = @_;
    
    my @ret = ();
    foreach my $row_ (@array) {
        my %row = %$row_;    
        
        $row{data} = parseDate($row{data});
        
        push(@ret, \%row);
    }
    
    return @ret;
}

sub datesToString {
    my @array = @_;
    
    my @ret = ();
    foreach my $row_ (@array) {
        my %row = %$row_;    
        
        $row{data} = dateToString($row{data});
        
        push(@ret, \%row);
    }
    
    return @ret;
}

sub report1 {
    my @_searchingPatterns = @_;

    print("Słowa kluczowe: ");
    my $patternsJoined = join(" lub ", @_searchingPatterns);
    print($patternsJoined); 

}



