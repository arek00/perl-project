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


my @report2Data = generateReport2Data();
#@report2Data = parseDates(@report2Data);
#@report2Data = sort compareArraysLengths @report2Data;
#@report2Data = datesToString(@report2Data); 
#@report2Data = map {$_{matched} = arrayToStr($_{matched})} @report2Data;


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




say("Report 2 output");
foreach my $record (@report2Data) {
    my %recordHash = %$record;
    
    say($recordHash{data}
        ."\t"
        .$recordHash{autor}
        ."\t"
       .join(", ", @recordHash{matched}));
}


say(@report2Data[0]->{matched});

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

sub generateReport2Data {
    my @results = ();
    
    ## Iterate over each CSV' file line.
    foreach my $line (@lines) {
        my %_line = %$line;
        
        my @words = split(/\s+/, $_line{tekst});
        @words = map {s/[\"\,\.]//; $_} @words;
        
        my @matchedWords = ();       
        
        ## Iterate over each word from tekst column.
        foreach my $word (@words) {
            ##say ("Matching word ".$word);
            ## Iterate over each defined word/pattern to match to find if any pattern matches word.
            foreach(@searchingPatterns) {
                my $pattern = qr/$_/;
                if($word =~ m/[^\s\,\.]*$pattern[^\s\,\.]*/i) {
                    push(@matchedWords, $word);
                    
                    say("Matched $pattern to $word");
                    last;
                }
            }
            
            #say("Matched words");
            #say(@matchedWords);
            $_line{matched} = @matchedWords;
            push(@results, \%_line);
        }   
    }
    
    return @results;
}

sub parseDate {
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
    #print($_[0]);
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

sub compareArraysLengths {
    my %hash1 = %$a;
    my %hash2 = %$b;

    say("Compare lengths of $hash1{matched} - $hash2{matched}");    
    
    my @array1 = $hash1{matched};
    my @array2 = $hash2{matched};
    
    return @array1.length() - @array2.length();
}

sub arrayToStr {
    my @array = $_[0]; 
    return join(", ", @array);     
}
