#!/usr/bin/env perl

use strict;
use warnings;

while (<>) {
    chomp;
    my @line = split(/\s+/, $_);
    my $name = $line[0];
    my $chrom = $line[1];
    my $start = $line[2];
    my $end = $line[3];
    my $contig = $line[4];

    `blastn -query \$WORKDIR/queries/$name.fa -subject \$WORKDIR/contigs/$contig.fa -outfmt 6 -out \$WORKDIR/blastn_outfmt6.out -max_target_seqs 1`;
    `cat \$WORKDIR/blastn_outfmt6.out >> \$WORKDIR/blastn.results`;
    `blastn -query \$WORKDIR/queries/$name.fa -subject \$WORKDIR/contigs/$contig.fa -outfmt 1 -out \$WORKDIR/blastn_outfmt1.out`;
    `cat \$WORKDIR/blastn_outfmt1.out >> \$WORKDIR/blastn.outfmt1.results`;
}
