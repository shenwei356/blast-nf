#!/usr/bin/env nextflow

// Copyright © 2019 Wei Shen <shenwei356@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/*
blast-nf - A nextflow-based BLAST command-line helper tool
Author: Wei Shen <shenwei356@gmail.com>
Source code: https://github.com/shenwei356/blast
*/

version = "0.2.0"

params.db = ""          // db name
params.app = "blastn"   // blast program
params.outdir = "."     // output directory
params.flags = ""       // more options: like -max_target_seqs -max_hsps
params.num_threads = 0  // threads, 0 for all

params.help = null

def help = """
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
            blast.nf --db \$db  \$query --outdir \$(dirname \$query)

    
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

    """.stripIndent()

if (params.help) {
    println help
    exit 0
}

// this is the best way I can figure out to check whether an argument is given
def argMissing = { str -> str=~ /^$/ || str =~ /true/ }

if (args.size() == 0) {
    println help
    exit 1, 'query file need'
}
if (argMissing(params.db)) {
    println help
    exit 1, 'db path need, please set option: --db nt'
}
if (argMissing(params.app)) {
    println $help
    exit 1, 'blast program, please set option: --app blastn'
}

cpus = params.num_threads <= 0 ?  Runtime.getRuntime().availableProcessors(): params.num_threads

// checking blast grogram
// idxSuffix = ["blastn": "nal", "blastp": "pal", "blastx": "pal", "tblastx": "nal"]
app = params.app
if (!idxSuffix.containsKey(app)) {
    exit 1, "illegal blast program: $app. Available: " + idxSuffix.keySet().join(", ") + '. Type "blast.nf --help" for help.'
}

// checking blast database 
// if (!file("${params.db}."+idxSuffix[app]).exists()) {
//  exit 1, "index file not found for db: $params.db . Please make blastdb."
// }
db = file(params.db)

// checking query files
Channel
    .from(args)
    .filter {file(it).exists()}
    .ifEmpty {exit 1, "query file not exist: " + args.join(", ")}
    .map {file(it)}
    .set {queryFiles}

// columns to output
columns = "qseqid sseqid pident length qlen slen qstart qend sstart send evalue bitscore mismatch gapopen staxids salltitles"

outdir = params.outdir

// running blast and saving result into ASN format
process blast {
    publishDir "$outdir", mode: 'copy'

    input:
    file query from queryFiles

    output:
    file "$outfile" into chFmt6, chFmt0

    script:
    outfile = "${query}.${params.app}@${db.baseName}.asn"
    """    
    ${params.app} -db ${db} -query $query -outfmt 11 -out $outfile -num_threads $cpus ${params.flags}
    """
}

// converting ASN.1 to tabular format
process asn2fmt6 {
    publishDir "$outdir", mode: 'move'

    input:
    file asn from chFmt6

    output:
    file "$outfile"

    script:
    outfile = "${asn}.tsv"
    """
    echo "$columns" | sed "s/ /\t/g" > $outfile
    blast_formatter -archive $asn -outfmt "6 $columns" >> $outfile
    """
}

// converting ASN.1 to outfmt 0
process asn2fmt0 {
    publishDir "$outdir", mode: 'move'

    input:
    file asn from chFmt0

    output:
    file "$outfile"

    script:
    outfile = "${asn}.txt"
    """
    blast_formatter -archive $asn -outfmt 0 > $outfile
    """
}
