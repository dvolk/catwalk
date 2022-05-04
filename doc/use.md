## Using Catwalk

### Starting the server (cw_server)

Example, using port 5000:
```
    ./cw_server --instance-name=test \
                --reference-filepath=reference/nc_045512.fasta \
                --mask-filepath=reference/covid-exclude.txt \
                --bind_port 5000
```

Note: This starts a server, and leaves it running in the terminal you opened it in.   
You can stop it with ^C.

In practice, you would normally use ```nohup``` to run it as a background process:

```
    nohup ./cw_server --instance-name=test \
                --reference-filepath=reference/nc_045512.fasta \
                --mask-filepath=reference/covid-exclude.txt \
                --bind_port 5000 &
```
This will start the server in the background, write output to a file called ```nohup.out```, and report a process id (pid), such as 1234567. This pid can be used to terminate the process (see below).   
However, first we will check the server is running.
We will use the Linux *curl* utility, but you can also use a web browser:
```
curl localhost:5000/info
```
This returns a json string containing status information on the server, e.g.
```
{"name":"test","reference_name":"reference/nc_045512.fasta","reference_sequence_length":29903,"mask_name":"reference/covid-exclude.txt","mask_positions":385,"max_n_positions":130000,"total_mem":5640192,"occupied_mem":713136,"n_samples":0,"compile_version":"0.9.4-dirty","compile_time":"2022-05-03 20:59:29+00:00"}
```

### How does the server work, what are the inputs and parameters?
It stores compressed sequence data in RAM, and uses a fast algorithm to compare sequences with each other.  Parameters impact performance and memory usage, so must be chosen carefully.  Please read our description of [how it works](howitworks.md) before using the server on your own data.

### Loading samples from a multifasta file: bulk load 

The fastest method of loading data is from a multi-fasta file.
Hundreds of thousands of samples can be loaded in a few minutes, but there are two main restrictions: 
* The file must be in ['fasta-2line'](https://biopython.org/wiki/SeqIO) format.  In this format, the defline and sequence occupy exactly two lines of the multifasta file, one for the defline and one for the sequence.  An example would be a fasta file like this:
```
>seq1
ACTCGATGAA
>seq2
ACTCGATGAT
```

* the fasta file has to be accessible from the server.   

To illustrate this loading method, we will generate a fasta-2line file from a test file representing a simulated SARS-CoV-2 phylogeny provided in the repository.  This phylogeny is derived from [Genbank:NC_045512](https://www.ncbi.nlm.nih.gov/nuccore/1798174254) *in silico*.  We use it as test set representing the results of mapping SARS-CoV-2 sequencing output to NC_045512. 

First, we decompress it, because we supply it compressed to keep file sizes down.
```
    gunzip --keep benchmark/sim/sim0.fasta.gz 
```
This file is just a normal fasta file, with genome positions indicated by 
A,C,G,T or N for unknown.  '-' characters, denoting gaps are also acceptable.  In this particular test file, there are no N or - characters, but this is not important for this demonstration.
```
    head benchmark/sim/sim0.fasta
```
We can convert it to [fasta-2line](https://biopython.org/wiki/SeqIO) format with a small utility included in the package.
```
    pipenv run python3 utils/make_mfsl.py benchmark/sim/
```

This makes a file ```benchmark/sim/mfsl.fa``` which we can now load the output file into Catwalk.  To do so, we use the cw_client utility, which expects the server to be running on port 5000.

```
    ./cw_client add_samples_from_mfsl -f benchmark/sim/mfsl.fa
```

We can confirm that this has added the files.
```
curl localhost:5000/info
```
This returns
````
{"name":"test","reference_name":"reference/nc_045512.fasta","reference_sequence_length":29903,"mask_name":"reference/covid-exclude.txt","mask_positions":385,"max_n_positions":130000,"total_mem":8130560,"occupied_mem":2003584,"n_samples":1000,"compile_version":"0.9.4-dirty","compile_time":"2022-05-03 20:59:29+00:00"}
```
Note that there are now 1,000 samples in the server.

### Loading samples from a multifasta file: use of REST-API
An alternative is to write a script to load samples via the REST API /add_sample endpoint.  An example using the python requests library is [provided](doc/api.md).  An alternative is to use the [python client](pyclient/pycw_client.py), which provides an interface to the REST API, as well as starting and stopping Catwalk clients if required.  

### Stopping the server

If you use a nohup based approach, you may wish to kill the process when you have finished with the server.  Firstly, you can check that the server is running
```
    ps x | grep cw_server
```
The safest way to stop it is using the process id listed (such as 1234567)
```
    kill 1234567
```
You can also kill all catwalk servers if you want to do so
```
    pkill cw_server
```
You can check that the server has been killed
```
    ps x | grep cw_server
```

### Starting the web UI
    Start web interface as a background process.  See above for discussion on how to kill this after startup.
    ```nohup ./cw_webui &``` 

Open browser at `http://localhost:5001`
