#!/usr/bin/perl

# This script adds landmark IDs to the set of 14 or 26 point .raw 3D face landmark files
# in the directory specified on the command line (or current dir).
# The results are saved in corresponding .lnd files

$dir = $ARGV[0];
if (length($dir) == 0) {
  $dir = ".";
}
-d $dir or die "\"\" is not a directory";
opendir DIR, $dir;
@files = readdir DIR;
foreach (<@files>){
  $infile = "$dir/$_";
  next if ($infile !~ /\.raw/);
  $size = `wc -l <$infile`;
  if ($size == 26) {@label = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26);}
  elsif ($size == 14) {@label = (1, 2, 3, 4, 5, 8, 11, 13, 12, 14, 17, 21, 25, 26);}
  else {die ("Can only deal with 14 or 26 pt files");}
  open INFILE, "<$infile";
  $outfile = $infile;
  $outfile =~ s/\.raw/.lnd/;
  open OUTFILE, ">$outfile";
  $i = 0;
  while (<INFILE>) {
    $_ = "$label[$i] $_";
    print OUTFILE $_;
    $i++;
  }
  close INFILE;
  close OUTFILE;
}
