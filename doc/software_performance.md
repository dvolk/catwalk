
## Performance
Catwalk queries are fast:
* To compare one SARS-CoV-2 sample against another takes about 0.4 microseconds.
* To compare one *M. tuberculosis* sample against another takes about 0.7 microseconds.
* So to find close neighbours of a sequence from a million sequences takes under a second.

The speed of comparison depends on the distance of the test samples from the reference, and the number of unknown bases in the sequence.  

Simulated data illustrating this is [available](../benchmark/sim/simulation_results.md).
