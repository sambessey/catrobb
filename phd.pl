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
my @legacyTerms=();
my@prefixArr=();
print "Please enter a Model name (i.e. Model 1): ";
$modelId = <>;
chomp ($modelId);
#############
#############
######################################## MAKE EDITS HERE #######################
my @finalOutputOrder=("Global Cog","Immediate memory","Delayed memory","Visuospatial","Language","Attention","Executive function");
my @finalOutputOrderCols=("[PASEtert2=2.00]","[PASEtert2=1.00]","Time","TimeSqr");
my $finalOut = "final/".$modelId."-model.csv";
#################################### MAKE EDITS ABOVE HERE #####################
#############
#############
while ($bothDone < 2)
{
  print "Please enter your INPUT file (It should be in the input directory): ";
  my $tempInput = <>;
  chomp ($tempInput);
  $file = "input/".$tempInput;
  print "Is this file 'below the separator'? ";
  $gcurve = <>;
  chomp($gcurve);
  if ($gcurve eq "n")
  {
    @searchTerms = ("[PASEtert2=2.00]","[PASEtert2=1.00]","Time","TimeSqr");
    @legacyTerms = @searchTerms;
    print "Enter a prefix (Like APoECarrier): ";
    $prefix =<>;
    chomp($prefix);
    push @prefixArr, $prefix;
    #$prefix = '1-';
  }
  if ($gcurve eq "y")
  {
    @searchTerms = ("[PASEtert2=2.00]","[PASEtert2=1.00]","Time","TimeSqr");
    print "Enter a prefix (Like APoEnonCarrier): ";
    $prefix =<>;
    chomp($prefix);
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
        print "Found a match\n";
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
        if ($_ =~m/\w\.* Dependent Variable\:\ (.*)?/)
        {
          $depVar = $1;
          $depVar =~ s/[^a-zA-Z0-9 ]//g
        }
      #  print $prefix.$_;
        $cleanBuffer .= $prefix.$_;
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
      #open(MODEL, '>>'.$output) or die $!;
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
}
print Dumper \%consolidated;
print "\n\nRAW DATA OBJECT OUTPUT ABOVE - DON'T FORGET TO CHECK FOR ERRORS!\n\n";
open(FINAL, '>final/'.$modelId.'.tsv') or die $!;
print "Writing final model file to tsv for Excel...\n";
print FINAL "\t";
keys %consolidated;
my $thing="";
for my $pfx (@prefixArr) {
#while ($x<2)
  #$thing = $x."-";
  foreach my $k (@finalOutputOrder)
  {
    print FINAL $k."\t";
  }
  print FINAL "\n";
  for $hashMeasure(@finalOutputOrderCols)
  {
    print FINAL $pfx.$hashMeasure."\t";
    for $hashDepVar( @finalOutputOrder )
    {
      print $hashDepVar.$thing.$hashMeasure.":".$consolidated{$hashDepVar}{$pfx.$hashMeasure}."\n";
      print FINAL "$consolidated{$hashDepVar}{$pfx.$hashMeasure}\t";
    }
    print FINAL "\n";
    #$prefix--;
  }
}
print "Completed Successfully.";
