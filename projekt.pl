#!/usr/bin/perl

### Import libraries
use 5.010;
use strict;
use warnings;
use DateTime::Format::Strptime;
use Text::CSV_XS qw ( csv );
use Text::Table;

### initialize parameters
my $inputFile = $ARGV[0];
my @lines = readLines($inputFile);
my $argsNumber = scalar @ARGV;
my @searchingPatterns = @ARGV[1..$argsNumber-1];


### Generate report 1
say("Start generating report 1");
my @report1Data = generateReport1Data(@lines, @searchingPatterns);
@report1Data = parseDates(@report1Data);

say("Sorting data in report 1");
@report1Data = sort {$a->{data} cmp $b->{data}} @report1Data;

say("Convert dates to string in report 1");
@report1Data = datesToString(@report1Data);

### Printing report 1
say("Create table 1");
my $table = Text::Table->
    new(columnTitle("Data"), columnTitle("Autor"), columnTitle("Czasopismo"));
foreach my $reportRow(@report1Data) {
    my %row = %$reportRow;
    $table->load([$row{data}, $row{autor}, $row{gazeta}]);
}

my $report1File = "raport1.txt";
print($table);
open(my $fileHandler, '>', $report1File) or die;
print $fileHandler "Słowa kluczowe: ".arrayToStr(@searchingPatterns)."\n";
print $fileHandler $table;


### Generate report 2
say("Start generating report 2");
my @report2Data = generateReport2Data();

say("Parsing dates in report 2");
@report2Data = parseDates(@report2Data);


say("Sorting data in report 2");
@report2Data = sort {scalar(@{$b->{matched}}) cmp scalar(@{$a->{matched}})} @report2Data;

say("Mapping arrays to strings in report 2");
@report2Data = mapMatchedWordsToString(@report2Data);

say("Creting report 2 table");
my $reportTable2 = Text::Table->
    new(columnTitle("Data"), columnTitle("Autor"), columnTitle("Czasopismo"), columnTitle("Wyszukane słowa"));

say("Filling report 2 table with data");
foreach my $reportRow (@report2Data) {
    my %row = %$reportRow;
    $reportTable2->load([$row{data}, $row{autor}, $row{gazeta}, arrayToStr(@{$row{matched}})]);
}


say("Writing report 2 to file");
my $report2File = "raport2.txt";
print($reportTable2);
open(my $fileHandler2, '>', $report2File) or die;
print $fileHandler2 "Słowa kluczowe: ".arrayToStr(@searchingPatterns)."\n";
print $fileHandler2 $reportTable2;

#################################################

### Functions definitions

sub columnTitle {
    say("Start column title");

    my $string = $_[0];  
    my $strLen = length($string);    
    my $line = "-" x $strLen;
    
    return "$line\n$string\n$line";
}

sub readLines {
    say("Start read lines");
    my $filePath = $_[0];
    my $parsedCsv = csv (in => $filePath,
                        headers => "auto",
                        quote_char => "\"");    
    return @$parsedCsv;
}

sub generateReport1Data {
    say("Start generating report 1");
    my @results = ();
    foreach my $line (@lines) {
        my %_line = %$line;
    
        foreach(@searchingPatterns) {
            my $pattern = $_;
            if($_line{tekst} =~ m/$pattern/i) {
                push(@results, \%_line);
                last;
            }
        }       
    }
    
    return @results;
}

sub generateReport2Data {
    say("Start generating report 2");

    my @results = ();
    
    ## Iterate over each CSV' file line.
    foreach my $line (@lines) {
        my %_line = %$line;
        
        my @words = split(/\s+/, $_line{tekst});
        @words = map {s/[\"\,\.]//; $_} @words;
        my @matchedWords = ();
        
        my $wordsInLine = arrayToStr(@words);
        say("Processing text: $wordsInLine");       
        
        ## Iterate over each word from tekst column.
        foreach my $word (@words) {
            ## Iterate over each defined word/pattern to match to find if any pattern matches word.
            
            #say("Matching word $word");
            
            foreach my $searchingPattern (@searchingPatterns) {
                my $pattern = qr/$searchingPattern/i;
                #say("Attempting to match $word with pattern $searchingPattern");
                if($word =~ m/\w*$pattern\w*/i) {
                    push(@matchedWords, $word);
                    #say("Matched $searchingPattern to $word");
                    last;
                }
            }                       
        }
        
        if(scalar(@matchedWords) > 0) {
            my $matchedStr = arrayToStr(@matchedWords);
            say("Matched words: $matchedStr");
            $_line{matched} = \@matchedWords;        
            push(@results, \%_line);
        }
    }
    
    return @results;
}

sub parseDate {
    say("Start parse date");

    my $date = $_[0];
    #say("Date to parse: ".$date);
    
    $date =~ s/(\d{1,2})(st|nd|rd|th),/$1/;
    #say("Date: ".$date);
    
    my $datePattern = "%B %e %Y";
    my $parser = DateTime::Format::Strptime->new(pattern=>$datePattern, locale=>"en_US");
    my $datetime = $parser->parse_datetime($date) or die;
    
    return $datetime;
}

sub dateToString {
    say("Start date to string");
    my $dateStringPattern = "%d.%m.%Y";
    my $date = $_[0];
    my $strDateTime = DateTime::Format::Strptime::strftime($dateStringPattern, $date) or die;
    return $strDateTime;
}

sub parseDates {
    say("Start parse dates");
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

sub compareArraysLengths {
    say("Start compare array lengths");
    my %hash1 = %$a;
    my %hash2 = %$b;

    say("Compare lengths of $hash1{matched} - $hash2{matched}");    
    
    my @array1 = $hash1{matched};
    my @array2 = $hash2{matched};
    
    return @array1.length() - @array2.length();
}

sub mapMatchedWordsToString {
    my @array = @_;
    
    foreach my $line (@array) {
        my %lineHash = %$line;
        $lineHash{matchedStr} = arrayToStr(%lineHash{matched});
    }
    
    return @array;
}

sub arrayToStr {
    say("Start array to string");
    my @array = @_; 
    return join(",", @array);     
}
