#!/usr/bin/env perl

use strict;
use warnings;

while (<>) {
    chomp;
    my @line = split(/\s+/, $_);
    my $chrom = $line[0];
    my $start = $line[1];
    my $end = $line[2];
    my $name = $line[3];

    #check if each end of the feature falls within an alignment
    my @front_results = split(/\n/, `awk '{if ((\$1 == "$chrom" && \$2<$start && \$3>$start) || (\$1 == "$chrom" && \$3<$start && \$2>$start)) print \$4}' results/out.coords.reformat`);
    my @end_results = split(/\n/, `awk '{if ((\$1 == "$chrom" && \$2<$end && \$3>$end) || (\$1 == $chrom && \$3<$end && \$2>$end)) print \$4}' results/out.coords.reformat`);

    #find those features that have both ends falling in an alignment to the same contig
    if (@front_results && @end_results) {
	foreach (@front_results) {
	    my $front_element = $_;
	    foreach (@end_results) {
		my $end_element = $_;
		if ($front_element eq $end_element) {
		    print $name, "\t", $chrom, "\t",  $start, "\t", $end, "\t", $front_element, "\n";
		}
	    }	
	}
    }

#    print $name, "\t", @front_results, "\n", $name, "\t", @end_results, "\n\n\n";

}
