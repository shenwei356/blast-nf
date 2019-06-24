# blast-nf

A nextflow-based BLAST command-line helper tool

## Requirements 

* Unix-like operating system (Linux, macOS, etc)
* Java 6+ 
* [NCBI BLAST+](ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/)


## Quickstart

1. [Install `nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation)

        curl -s https://get.nextflow.io | bash

1. Download this repository

        git clone https://github.com/shenwei356/blast-nf
        cd blast-nf

1. Copy `blast.nf` to anywhere in your `$PATH`

        mkdir -p ~/bin;
        cp blast-nf/blast.nf ~/bin

1. Making BLAST db

        makeblastdb -dbtype nucl -in test/db.fa -out test/db

1. Run `blastn`

        blast.nf --db test/db test/query1.fa

1. Filter tabular result

        cat query1.fa.blastn@db.asn.tsv \
            | csvtk filter2 -t -f '($length/$qlen > 0.8) && ($pident > 80)' \
            | csvtk cut -t -f qseqid,sseqid,qlen,length,slen,pident,evalue,salltitles \
            | csvtk pretty -t
        qseqid         sseqid         qlen   length   slen   pident   evalue     salltitles
        mmu-mir-216b   gga-mir-216c   86     81       86     86.420   1.76e-21   gga-mir-216c MI0007066 Gallus gallus miR-216c stem-loop

## Usage

```
blast-nf - A nextflow-based BLAST command-line helper tool

Version: 0.1.0
Author: Wei Shen <shenwei356@gmail.com>
Source code: https://github.com/shenwei356/blast

Functions:
    1. Running NCBI BLAST, saving result in ASN.1 format.
    2. Converting ASN.1 format to tabular (outfmt 6) and default (outfmt 0) format.

Usage:
    blast --db db_path [option...] <query_fasta> [<query fasta>...]

Options:
    --db            BLAST database path.
    --app           BLAST program. (default: blastn).
                    Available: blastn, blastp, blastx, tblastx.
    --flags         Additional BLAST options.
                    e.g., -max_target_seqs 5 -max_hsps 5
    --num_threads   Threads number, 0 for all. (default: 0)
    --outdir        Output directory. (default: ".")
    --help          Print this help message.

Examples:
    1. simple one
        blast.nf --db ~/db/nt seq.fa
    2. mulitple query files:
        blast.nf --db ~/db/nt seq*.fa
    3. more BLAST options:
        blast.nf --db ~/db/nt seq.fa --args "-max_target_seqs 5 -max_hsps 5"
    4. saving result to directory of query file
        blast.nf --db $db  $query --outdir $(dirname $query)

Output files:
    seq.fa.blastn@nt.asn      # asn
    seq.fa.blastn@nt.asn.tsv  # outfmt 6 with column names
    seq.fa.blastn@nt.asn.txt  # outfmt 0

Columns in tabular format:
    1       qseqid
    2       sseqid
    3       pident
    4       length
    5       qlen
    6       slen
    7       qstart
    8       qend
    9       sstart
    10      send
    11      evalue
    12      bitscore
    13      mismatch
    14      gapopen
    15      staxids
    16      salltitles

```

## License

[MIT License](https://github.com/shenwei356/blast-nf/blob/master/LICENSE)
