### Cache

When you add samples to catwalk, a JSON string of the reference compressed sequence is saved to the `instance-name` directory. When you restart catwalk with that instance name, it will load these sequences automatically. This is much faster than re-adding them every time, and the files are smaller than the original fasta files.
