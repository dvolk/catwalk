# CatWalk

## Description

You put in the pasta!!

You get out the friendship!!

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

- configuration for cw_server
- lower memory usage
- faster performance
- better EW emulation

## Misc

`utils/plot_array.py` is a script that can take dumps from `cw_client process_times` and draw graphs like so:

![](https://gitea.mmmoxford.uk/dvolk/catwalk/raw/branch/master/doc/perf.png)