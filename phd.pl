#!/usr/bin/perl
use Data::Dumper qw(Dumper);
########################################
##############CLEANER CODE##############
########################################
my $flag==0;
my $siglvl="";
#my $file = "input/output2global cognition basic.txt";
my $finalOut = "final/testmodel.csv";
my $depVar = "";
my $cleanBuffer="";
my $cleanQuery ="";
my $prefix ="";
my @searchTerms = ();
my %consolidated;
my $bothDone=0;
my @finalOutputOrder=("Global Cog","Immediate memory","Delayed memory","Visuospatial","Language","Attention","Executive function");
my @finalOutputOrderCols=("[PASEtert2=2.00]","[PASEtert2=1.00]","Time","TimeSqr","[PASEtert2=2.00] * Time","[PASEtert2=2.00] * TimeSqr","[PASEtert2=1.00] * Time","[PASEtert2=1.00] * TimeSqr");
print "Please enter a Model name (i.e. Model 1): ";
$modelId = <>;
chomp ($modelId);
while ($bothDone < 2)
{
  print "Please enter your INPUT file (It should be in the input directory): ";
  my $tempInput = <>;
  chomp ($tempInput);
  $file = "input/".$tempInput;
  print "Is this file is for the GROWTH CURVE section? ";
  $gcurve = <>;
  chomp($gcurve);
  if ($gcurve eq "n")
  {
    @searchTerms = ("[PASEtert2=2.00]","[PASEtert2=1.00]","Time","TimeSqr");
    $prefix = '1-';
  }
  if ($gcurve eq "y")
  {
    @searchTerms = ("[PASEtert2=2.00] * Time","[PASEtert2=2.00] * TimeSqr","[PASEtert2=1.00] * Time","[PASEtert2=1.00] * TimeSqr");
    $prefix = '2-';
  }
  my $output = "staging/".$prefix.$modelId.".tsv";
  print "Set to ".$modelId;
  open(IN, '<'.$file) or die $!;
  while(<IN>)
  {
      if ($_=~m/95\%\ Confidence\ Interval\n/)
      {
        $flag=1;
      }
      if ($_=~m/^\n/)
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
        if ($_ =~m/a Dependent Variable\:\ (.*)?\./)
        {
          $depVar = $1;
        }
        $cleanBuffer .= $_;
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
          $cleanQuery = "^".$k;
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
        $consolidated.=$consolidated{$printDepVar}{ $k } = $middleCol;
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
foreach my $k (@finalOutputOrder)
{
  print FINAL $k."\t";
}
print FINAL "\n";
for $hashMeasure(@finalOutputOrderCols)
{
  print FINAL $hashMeasure."\t";
  for $hashDepVar( @finalOutputOrder )
  {
    print FINAL "$consolidated{$hashDepVar}{$hashMeasure}\t";
  }
  print FINAL "\n";
}
print "Completed Successfully.";
