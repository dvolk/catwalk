# CatWalk

## Description

CatWalk is a service where you insert bacterial fasta files and then query relationships between them.

## Status

*Experimental*

## Requirements

- nim >= 1.0.0

## Building

    nimble build

This creates two binaries: `cw_server` and `cw_client`

## Using cw_server

    ./cw_server

## Using cw_client

    ./cw_client
    Usage:
      cw_client {SUBCMD}  [sub-command options & parameters]
    where {SUBCMD} is one of:
      help           print comprehensive or per-cmd help
      info           
      add_sample     
      neighbours     
      list_samples   
      process_times  

## Performance

It's pretty good but if you want it even faster you can compile manually:

    nim c -d:release -d:danger --opt:speed src/cw_server
    nim c -d:release -d:danger --opt:speed src/cw_client

## TODO

- Configuration/command-line arguments for cw_server
- Better EW emulation
- Web UI
- Lower memory usage (current ~700kb/sample)
- Faster performance

## Misc

`utils/plot_array.py` is a script that can take dumps from `cw_client process_times` and draw graphs like so:

![](https://gitea.mmmoxford.uk/dvolk/catwalk/raw/branch/master/doc/perf.png)