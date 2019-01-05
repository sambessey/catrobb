#!/usr/bin/perl
########################################
##############CLEANER CODE##############
########################################
my $flag==0;
my $siglvl="";
my $file = "output2global cognition basic.txt";
my $output = "test.tsv";
my %results = ();
rename($file, $file.'.bak');
open(IN, '<'.$file.'.bak') or die $!;
open(OUT, '>'.$file) or die $!;
while(<IN>)
{
    if ($_=~m/95\%\ Confidence\ Interval\n/)
    {
      $flag=1;
    }
    if ($_=~m/^\n/)
    {
      $flag=0;
    }
    $_ =~ s/95\%\ Confidence\ Interval\n//g;
    $_ =~ s/\t\t\t\t\t\t//g;
    if($flag==1)
    {
      print OUT $_;
    }

}
close(IN);
close(OUT);
########################################
############END CLEANER CODE############
########################################

open(IN, '<'.$file) or die $!;
while(<IN>)
{
  chomp;

  if($_=~m/Time\t/)
  {
    push @{ $results{"Time"} }, split /\t/, $_;
#    print $results{"Time"}[1];
  }
  if($_=~m/TimeSqr\t/)
  {
    push @{ $results{"TimeSqr"} }, split /\t/, $_;
#    print $results{"TimeSqr"}[1];
  }
  if($_=~m/\[PASEtert2\=1.00\]\t/)
  {
    push @{ $results{"[PASEtert2=1.00]"} }, split /\t/, $_;
  #  print $results{"[PASEtert2=1.00]"}[1];
  }
  if($_=~m/\[PASEtert2\=2.00\]\t/)
  {
    push @{ $results{"[PASEtert2=2.00]"} }, split /\t/, $_;
    #print $results{"[PASEtert2=2.00]"}[1];
  }
}
open(OUT, '>'.$output) or die $!;
keys %results; # reset the internal iterator so a prior each() doesn't affect the loop
print OUT ("Model 1\t\t\nGlobal cog\t\tSig\n");
foreach my $k ("[PASEtert2=2.00]","[PASEtert2=1.00]","Time",'TimeSqr'){
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
print OUT ($k."\t".sprintf('%.2f', $results{$k}[1])." [".sprintf('%.2f', $results{$k}[6]).", ".sprintf('%.2f', $results{$k}[7])."]".$siglvl."\t".sprintf('%.2f', $results{$k}[5])."\n");
$siglvl = "";
}
close (OUT);
