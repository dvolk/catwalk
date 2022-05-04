## Utilities

Various utilities are provided which use the Catwalk server.

### utils/make_mfsl.py
Convert a directory of fasta files into a single 'two-line' multifasta format.  [Example usage](use.md)

### utils/verify.py

Given a reference, a mask file and two samples, check the difference between the samples in different ways.

### utils/compare_neighbours.py

Get all neighbours from different relateness services and compare them. Useful for comparing identical datasets processed in different ways for QC purposes.

### utils/clusters.py

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
