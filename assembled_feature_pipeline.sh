#!/bin/bash

#note: this script requires the BED file to have unique identifiers in the fourth (i.e. "name") field 
#note: this script requires contigs in the assembly (FASTA) to have unique names

#first set path to MUMmer, BLAST, and bedtools                                                                                                                              
#PATH=$PATH\:/home/rmccoy/tools/MUMmer3.23 ; export PATH                                                                                                                    
#PATH=$PATH\:/home/rmccoy/tools/ncbi-blast-2.2.28+/bin/ ; export PATH                                                                                                       
#PATH=$PATH\:/home/rmccoy/tools/bedtools-2.17.0/bin/ ; export PATH 

if ( ! getopts "a:r:f:" opt); then
    echo "Usage: ./assembled_feature_pipeline.sh -a /full/path/to/assembly.fa -r /full/path/to/reference.fa -f /full/path/to/feature.bed";
exit $E_OPTERROR;
fi

while getopts "a:r:f:" opt; do
     case $opt in
         a) ASSEMBLY=$OPTARG;;
         r) REFERENCE=$OPTARG;;
	 f) FEATURE=$OPTARG;;
     esac
done

wget https://nash-bioinformatics-codelets.googlecode.com/files/split_fasta.pl

PWD=$(pwd)
mkdir $PWD/results
WORKDIR=$PWD/results; export WORKDIR


printf "\nReading assembly: $ASSEMBLY...\n"
printf "Mapping to reference genome: $REFERENCE.  This step can take over an hour...\n"

#perform alignment with NUCmer
nucmer --maxmatch --prefix $WORKDIR/out $REFERENCE $ASSEMBLY 1> $WORKDIR/assembled_feature_pipeline.stdout 2> $WORKDIR/assembled_feature_pipeline.stderr

printf "Filtering alignment...\n"
delta-filter -q $WORKDIR/out.delta > $WORKDIR/out.filter
show-coords -rc $WORKDIR/out.filter > $WORKDIR/out.filter.2
cat $WORKDIR/out.filter.2 | sed '1,5d' > $WORKDIR/out.coords
awk '{print $15"\t"$1"\t"$2"\t"$16"\t"$4"\t"$5"\t"$19}' $WORKDIR/out.coords > $WORKDIR/out.coords.reformat

printf "Checking whether genomic features' boundaries fall within aligned contigs...\n"
#get list of features with both ends falling in single aligned contigs
cat $FEATURE | perl check_boundaries.pl > $WORKDIR/out.boundaries

mkdir $WORKDIR/contigs/
cp split_fasta.pl $WORKDIR/contigs/
cd $WORKDIR/contigs/
perl split_fasta.pl $ASSEMBLY

mkdir $WORKDIR/queries/
#make a fasta file of the features of interest
bedtools getfasta -bed $FEATURE -fi $REFERENCE -name -fo $WORKDIR/queries/feature.fa
printf "Copying and splitting assembly into BLAST reference contigs.  This part takes a few minutes...\n"
cp split_fasta.pl $WORKDIR/queries/
cd $WORKDIR/queries/
printf "Copying and splitting genomic features into BLAST queries.\n"
perl split_fasta.pl feature.fa
rm $WORKDIR/queries/feature.fa
rm split_fasta.pl


cd $WORKDIR
cd ..
pwd
printf "Running BLASTN...\n"
touch $WORKDIR/blastn.results
touch $WORKDIR/blastn.outfmt1.results
cat $WORKDIR/out.boundaries | perl run_blastn.pl


cat $FEATURE | awk '{print $4"\t"$3-$2}' | LANG=C sort > $WORKDIR/feature.lengths
LANG=C sort $WORKDIR/blastn.results > $WORKDIR/blastn.sorted.results
printf "Name\tContig_ID\tPct_length\tPct_ident\n" > $WORKDIR/FINAL.REPORT
LANG=C join -1 1 -2 1 $WORKDIR/feature.lengths $WORKDIR/blastn.sorted.results | awk '{print $1"\t"$3"\t"($5/$2)*100"\t"$4}' | awk '!x[$1]++' >> $WORKDIR/FINAL.REPORT

printf "Done.\n"
