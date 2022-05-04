## Utilities

Various utilities used during development of the software are included.

### utils/make_mfsl.py
Example script converting all fasta files in a single directory  into a single 'two-line' multifasta format.  [Example usage](use.md)

### utils/verify.py
Compares output from Catwalk with that from a python algorithm implementing of snp distance computation, used to test Catwalk outputs.  Given a reference, a mask file and two samples, determines the snp distance between the samples.

### utils/compare_neighbours.py
Compares output from Catwalk with that from findNeighbour3 https://github.com/davidhwyllie/findNeighbour3, a python server implementing reference based compression and SNV computation.  Used for quality control of catwalk software.

### utils/clusters.py
Experimental software which draws a network illustrating links between samples.
Use networkx to create a cluster graph

#### Example: making a cluster graph png

You will need a running catwalk server and graphviz installed

Add your samples to catwalk and run:

```
python3 compare_neighbours.py cwn 12 > example.txt
python3 clusters.py example.txt 12
sfdp example.dot -Tpng -o example.png
```

This creates a cluster graph for SNP distance 12, see [an output example](https://gitea.mmmoxford.uk/dvolk/catwalk/raw/branch/master/doc/cluster-example.png).
