# How Catwalk works

## Is this a command line program?
It is a server application.  The server, once started, will remain running until terminated.  The server can be started with a command line operation.

## How the server accessible?
HTTP REST-API
Command line client

## What does it calculate?
It calculates pairwise single nucleotide variation between sequences mapped to a fixed length reference genome.  Uncertain or missing bases are ignored.  

For example, suppose we have two genomes
```
>S1
ACGTAT
>S2
ACGTAG
```
dist(S1,S2) = 1

However, 
```
>S1
ACGTAT
>S3
ACGTAN
```
dist(S1,S2) = 0

## What data is it designed to work on?
It is designed to work on consensus nucleotide sequences obtained by mapping sequencer output to single fixed-length consensus genome, and then calling a single consensus base at each position.

This can be supplied in three ways:
* fasta files, including multi-fasta files.  Please see the [/add_samples_from_mfsl](api.md) endpoint.
* a sequence name, and a string sequence.  Please see the [/add_sample](api.md) endpoint .
* differences from the reference genome.  A more detailed description of how these can be computed is [here](refcomp.md).  Please see also the [/add_sample_from_refcomp](api.md).

## How does it work internally?
It computes and stores variation of each sequence against the reference.  It uses the reference compressed differences directly in fast distance computation.  These sequences are stored in RAM.

This approach has the following implications:
* it works best when the reference is close to the sequence data, because there are fewer differences to store
* if there are regions of the genome which are known to never be adequately called, they should be masked (see below).  This will result in smaller memory representations and fast computation.

## What do the server parameters mean?
An example startup command is as below:
```
./cw_server --instance-name=test \
                --reference-filepath=reference/nc_045512.fasta \
                --mask-filepath=reference/covid-exclude.txt \
                --bind_port 5000 \
                --max_n_positions 3000
```

The parameters are as follows:  
**instance_name**: an alphanumeric identifier for the server.  Is included in the outputs of commands like ```ps x`` and so can be used to work out process identifiers (pids) of running servers.  
**reference-filepath**: the path to a fasta file containing the reference genome, see also 'reference file' below.  
**mask-filepath**: the path to a text file containing zero-indexed positions in the reference genome to be ignored by the server.  See also 'mask file' below.

## What is a 'reference file'
This the genome to which the consensus sequences are mapped.  Typically, it is closed genome from Genbank.  It must contain only A,C,G,T characters in unmasked positions; case is ignored.

You may wish to work with a 'pseudogenome' in which contigs are concatenated.  Often, synthetic gaps of N characters are added where the contigs are concatenated.  Such pseudogenomes can be used as reference, but the N characters must be masked. 

[Example 1 : SARS-CoV-2](https://www.ncbi.nlm.nih.gov/nuccore/NC_045512.2?report=fasta)  
[Example 2: H37Rv (TB) v3 genome](reference/TB-ref.fasta)  

## What is a 'mask file'
Commonly, there are regions of the genome where mapping is known to be problematic.  Such regions are typically ignored during single nucleotide variation calculation.  A mask file can be supplied to the server and specifies which regions should be ignored, if any.  A mask file is always required, but if no masking is desired, the file can be empty..  Differences in regions which are specified in the mask are ignored in single nucleotide computations.

The mask file itself is very simple in format.  It is always required, but can be
* [an empty file](../reference/nil.txt).  Such files can be created very easily using ```touch``` which creates and empty file.  Example: ```touch my_new_exclusion_file.txt```
* a text file containing zero indexed positions of the reference file to be excluded, one on each line.  
[Example for SARS-CoV-2](../reference/covid-exclude.txt)    
[Example for *M. tuberculosis*](../reference/TB-exclude-adaptive.txt)  


## What does reference to 'max_n_positions's refer to?
If a sequence has more than max_n_positions, the server 
* ignores this in computations
* stores this internally as 'invalid'
* does not store a reference compressed representation

The reason for this is that single nucleotide differences cannot be meaningful computed without an adequate quality consensus sequence.

For example, if not sequence has been computed for sequence S4, 
```
>S1
ACGTAT
>S4
NNNNNN
```
dist(S1, S4) = 0 but actually we cannot say that S4 is similar to S1 : we lack information to do so.

Catwalk's approach to this is to ignore samples which have more than some cutoff number of Ns: what this value should be depends on the sequence set study and is a subject for optimisation.

## Does it store distance data between sequences?
No.  This is because benchmarking indicates that it is often faster to recompute distances than to store the results. If you need to do store distances, please see [findNeighbour4](https://github.com/davidhwyllie/findNeighbour4).

## Does it handle IUPAC (ambiguity) codes?
No.  Only A,C,G,T,N and - characters are accepted.  If you need to handle ambiguity, please see  [findNeighbour4](https://github.com/davidhwyllie/findNeighbour4).  This service ignores IUPAC codes in nucleotide distance computations, but it does store them and uses them in various quality/mixture calculations.

W