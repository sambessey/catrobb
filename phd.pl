#!/usr/bin/perl
use Data::Dumper qw(Dumper);
####THIS IS THE STRATAFIED AY APoE FILE#######
########################################
##############CLEANER CODE##############
########################################
my $flag==0;
my $siglvl="";
my $depVar = "";
my $cleanBuffer="";
my $cleanQuery ="";
my $prefix ="";
my @searchTerms = ();
my %consolidated;
my $bothDone=0;
my $expectInputs=0;
my @legacyTerms=();
my@prefixArr=();
my @finalOutputOrderRows=();
my @finalOutputOrder =();
my $conffile="";
my $regParam="";
my $permitWrite = "Y";
print "Please enter a config file: ";
$conffile = <>;
chomp ($conffile);
my %config = do 'config/'.$conffile;
my @listOfFiles = ($config{file1},$config{file2});
my @listOfTables = ($config{thistable1},$config{thistable2});
$modelId = $config{modelName};
#############
#############
######################################## MAKE EDITS HERE #######################
@finalOutputOrder = split (',', $config{finalOutputOrder});
#print "0:".@finalOutputOrder[0]."1:".@finalOutputOrder[1]."2:".@finalOutputOrder[2]."DONE";
#push @finalOutputOrder, $config{finalOutputOrder};
#print  @finalOutputOrder[0];
####my @finalOutputOrder=("Global Cog","Immediate memory","Delayed memory","Visuospatial","Language","Attention","Executive function");
#NEXT IS LLPA MAIN EFFECTS
#my @finalOutputOrderRows=("[PASEtert2=2.00]","[PASEtert2=1.00]","Time","TimeSqr");
####my @finalOutputOrderRows=("[MLPAPos4=.00]","Time","TimeSqr");
@finalOutputOrderRows = split (',', $config{finalOutputOrderRows});
my $finalOut = "final/".$modelId."-model.csv";
#################################### MAKE EDITS ABOVE HERE #####################
#############
#############
#print "How many input files will there be?: ";
$expectInputs = $config{numberOfFiles};
#chomp ($expectInputs);
while ($bothDone < $expectInputs)
{
#  print "Please enter your INPUT file (It should be in the input directory): ";
  my $tempInput = @listOfFiles[$bothDone];
  $file = "input/".$tempInput;
  print "Is this file 'below the separator'? ";
  $gcurve = <>;
  chomp($gcurve);
  if ($gcurve eq "n")
  {
    #NEXT IS LLPA MAIN EFFECTS
  #  @searchTerms = ("[PASEtert2=2.00]","[PASEtert2=1.00]","Time","TimeSqr");
    @searchTerms  = split (',', $config{searchTerms1});
    #print @searchTerms[0].@searchTerms[1].@searchTerms[2].@searchTerms[3]."END";
    @legacyTerms = @searchTerms;
    #print "Enter a prefix (Like APoECarrier): ";
    $prefix =$config{prefix1};
    #chomp($prefix);
    push @prefixArr, $prefix;
    #print @prefixArr[0];
  }
  if ($gcurve eq "y")
  {
    @searchTerms = split (',', $config{searchTerms2});
  #  print "Enter a prefix (Like APoEnonCarrier): ";
    $prefix =$config{prefix2};
  #  chomp($prefix);
    push @prefixArr, $prefix;
    #$prefix = '2-';
    if( @legacyTerms ~~ @searchTerms )
    {
      print "Identical terms for both runs found\n";
    }
  }
  my $output = "staging/".$prefix.$modelId.".tsv";
  print "Set to ".$modelId;
  open(IN, '<'.$file) or die $!;
  while(<IN>)
  {
      if ($_=~m/95\%\ Confidence\ Interval[\t\n]/)
      {
        #print "Found a match\n";
        $flag=1;
      }
      if ($flag == 1 && $_=~m/^\t*\n/)
      {
        $flag--;
        if ($flag==0)
        {
          print "End of table found: ".$depVar."\n";
          $cleanBuffer .= "\n".$depVar;
          $depVar =~ s/ /-/g;
          print "Writing to file ".$depVar."...\n";
          open(OUT, '>temps/'.$depVar.".tsv") or die $!;
          print OUT $cleanBuffer."\n";
          $cleanBuffer ="";
          close (OUT);
        }
      }
      $_ =~ s/95\%\ Confidence\ Interval\n//g;
      $_ =~ s/\t\t\t\t\t\t//g;
      if($flag==1)
      {
      #  print "FLAG IS1-Here:".$_;
        if (@listOfTables[$bothDone] ne "" && $_!~m/95\%\ Confidence\ Interval[\t\n]/)
        {
          #print "\n\n\n\nMATCH FOUND!!!!!".@listOfTables[$bothDone]."?\n\n\n\n\n\n\n";
          my $tableID = @listOfTables[$bothDone];
          if ($_=~m/\Q$tableID/)
          {
            $permitWrite ="Y";
            $_=~ s/$tableID//g;
          }
          else {
          if ($_=~m/^[\w\-]/)
          {
            $permitWrite ="N";
            if ($_=~m/Dependent Variable/)
            {
              $permitWrite ="Y";
            }
          }
        }
#          if ($permitWrite eq "Y")
#          {
#            print "YES".$_;
#          }
#          else
#          {
#            print "NO".$_;
#          }
        }
        #next unless $_ =~m/\-99/;
        #print "HEY\n";
        if ($_ =~m/\w\.* Dependent Variable\:\ (.*)?/)
        {
          $depVar = $1;
          $depVar =~ s/[^a-zA-Z0-9 ]//g;
        }

        $_=~ s/^\t([a-zA-Z0-9\[].*)/$1/g;
        if ($permitWrite eq "Y")
        {
          $cleanBuffer .= $prefix.$_;
        }
      }

    }
    close(IN);
    close(OUT);
    ########################################
    ############END CLEANER CODE############
    ########################################
    @files = <temps/*>;
    foreach $filename (@files) {
      #my $filename = "Global-Cog.tsv";
      open(IN, '<'.$filename) or die $!;
      my %results = ();
      $filename =~ s/-/ /g;
      $filename =~ s/^.*?\///g;
      my $printDepVar = substr($filename, 0, -4);
      print "Writing ".$printDepVar." to staging file...\n";
      while(<IN>)
      {
        chomp;
        foreach my $k (@searchTerms)
        {
          $cleanQuery = "^".$prefix.$k;
          $cleanQuery =~ s/([\[\]\=\*])/\\$1/g;
          $cleanQuery.="\t";
          if($_=~m/$cleanQuery/)
          {
            push @{ $results{$k} }, split /\t/, $_;
          }
        }
      }
      open(OUT, '>>'.$output) or die $!;
      print "Writing from".$output."\n";
      keys %results;
      print OUT ($modelId."\t\t\n".$printDepVar."\t\tSig\n");
      foreach my $k (@searchTerms)
      {
        if ($results{$k}[5] < .08)
        {
          $siglvl = "x";
        }
        if ($results{$k}[5] < .05)
        {
          $siglvl = "*";
        }
        if ($results{$k}[5] < .01)
        {
          $siglvl = "**";
        }
        if ($results{$k}[5] < .001)
        {
          $siglvl = "***";
        }
        my $middleCol = sprintf('%.2f', $results{$k}[1])." [".sprintf('%.2f', $results{$k}[6]).", ".sprintf('%.2f', $results{$k}[7])."]".$siglvl;
        my $sigCol = sprintf('%.2f', $results{$k}[5]);
        print OUT ($k."\t".$middleCol."\t".$sigCol."\n");
        $siglvl = "";
        $consolidated.=$consolidated{$printDepVar}{ $prefix.$k } = $middleCol;
      }
      close (OUT);
    }
    $bothDone++;
    $permitWrite = "Y";
}
print Dumper \%consolidated;
print "\n\nRAW DATA OBJECT OUTPUT ABOVE - DON'T FORGET TO CHECK FOR ERRORS!\n\n";
open(FINAL, '>final/'.$modelId.'.tsv') or die $!;
print "Writing final model file to tsv for Excel...\n";
keys %consolidated;
my $thing="";
for my $pfx (@prefixArr) {
  print FINAL $pfx."\t";
  foreach my $k (@finalOutputOrder)
  {
    print FINAL $k."\t";
  }
  print FINAL "\n";
  for $hashMeasure(@finalOutputOrderRows)
  {
    print FINAL $hashMeasure."\t";
    for $hashDepVar( @finalOutputOrder )
    {
      #print $hashDepVar.$thing.$hashMeasure.":".$consolidated{$hashDepVar}{$pfx.$hashMeasure}."\n";
      print FINAL "$consolidated{$hashDepVar}{$pfx.$hashMeasure}\t";
    }
    print FINAL "\n";
  }
}
print "Completed Successfully.";
