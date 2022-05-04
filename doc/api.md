## HTTP API

Catwalk provides the following HTTP API endpoints (examples are given with the Python Requests library, and assume the server is running on port 5000).

### /info

Returns server information such which reference is used, memory used, version, etc.

    >>> requests.get("http://localhost:5000/info").json()

### /list_samples

Returns a JSON array of sample names loaded into the server.

    >>> requests.get("http://localhost:5000/list_samples").json()

### /add_sample

Add a sample to catwalk

    >>> requests.post("http://localhost:5000/add_sample", json={ "name": sample_name,
                                                                 "sequence": "ACGTACGT",
                                                                 "keep": True })

### /neighbours/<sample_name>/<distance>

Get a array of tuples [[neighbour_name, distance]] of neighbours of sample_name up to the SNP cut-off distance.

    >>> requests.get("http://localhost:5000/neighbours/sample_name/20").json()

### /add_samples_from_mfsl

Add samples to catwalk in the multifasta singleline format.

    >>> requests.post("http://localhost:5000/add_samples_from_mfsl", json={"filepath": "mysamples.fa"})

The filepath must be readable from the catwalk server.

This is faster than sending the sequences over HTTP with /add_sample. For maximum performance, use fast storage such as SSD drives.  [Example usage](doc/use.md)

### /add_sample_from_refcomp
Add a sequence, supplying not a complete sequence (as in a fasta file), but just differences from the reference sequence.  Here is an example where there is an A at 10,11,12 and a G at 13,14 relative to the reference.

    >>> ref_compressed_sequence = {
        'A':[10,11,12],
        'C':[],
        'G':[13,14],
        'T':[],
        'N':[]
    }
    >>> requests.post("http://localhost:5000/add_sample_from_refcomp", json={ "name": sample_name,
                                                                 "refcomp": json.dumps(ref_compressed_sequence),
                                                                 "keep": True })

### /remove_sample/<sample_name>

Remove a sample from catwalk

    >>> requests.get("http://localhost:5000/remove_sample/sample_name")

## Python client
### 

A [python interface to Catwalk](../pyclient/pycw_client.py), which is linux-specific, provides a class offering
* starting and stopping catwalk instances
* interactions with all endpoints exposed by the server.
Its use is documented in docstrings.
