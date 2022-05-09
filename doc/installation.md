## Installing the software

### Operating system
* We recommend using linux; the system has only been tested on linux but we anticipate it will work on Mac OS X
* The [python client](../pyclient/pycw_client.py) will not work on Windows, because it uses linux-specific commands to start and stop Catwalk instances, but the server itself may well do so, although we have not tested this.  Please let us know if you have experience using this software on Windows.


### Installing nim 

* The software requires version >= 1.4.8 of Nim. 

#### Recommended installation method

The following approach works on bash linux systems, and is the one we have used. It assumes you are putting nim in the home directory, but you can edit the paths below as necessary.

1. Nim requires gcc, which is preinstalled on most linux systems:
```
sudo apt install gcc
```

2. Download and extract nim:

```
cd ~
wget https://nim-lang.org/download/nim-1.6.4-linux_x64.tar.xz
tar xf nim-1.6.4-linux_x64.tar.xz
```

3. to be able to run nim from any directory, add it to the `PATH` variable (replace ```yourusername``` with your username, e.g. ```john.smith```):
```
echo 'PATH=$PATH:/home/yourusername/nim-1.6.4/bin' >> .bashrc
```

4. When you run `nimble install` (the nim package manager), it puts binaries into `~/.nimble/bin`, so add that too (replace ```yourusername``` with your username, e.g. ```john.smith```):
```
echo 'PATH=$PATH:/home/yourusername/.nimble/bin' >> .bashrc
```

5. Source the bashrc file (this loads the environment variables):
```
source ~/.bashrc
```
6. Confirm it is working:
```
$ nim -v
Nim Compiler Version 1.4.8 [Linux: amd64]
```

#### Other options for installation:
* See the [Nim installation instructions](https://nim-lang.org/install.html) from the Nim development team
* Package managers may contain nim ```sudo apt install nim``` but these tend to lag behind the language releases.
* There are instructions for [using conda](https://anaconda.org/conda-forge/nim), an approach we have not tested. 

### Building (Compiling) Catwalk

Catwalk can be compiled in two modes.   
In the catwalk directory into which you have cloned the repository, run one of these commands:  

**option 1**: the catwalk server will keep a record of sequences loaded into it in a [cache](cache.md), comprising flat files on disc, and automatically reload on startup. 

    nimble -y build -d:release -d:danger

or  

**option 2**: the catwalk server will not maintain a local cache.  On restart, the client will need to reload records.  This may be desirable if an [application is using Catwalk as component](https://github.com/davidhwyllie/findneighbour4).

    nimble -y build -d:release -d:danger -d:no_serialisation

Either option will work for unit testing. 

Both options create three binaries: `cw_server`, `cw_client`, `cw_webui`.

#### Compiler Warnings
Various compiler warnings may be issued by recent Nim versions.  These can be safely ignored.  

#### Expected output
Catwalk is a server application.  The Catwalk server `cw_server` stores the sequences in RAM and performs distance computations.

The `cw_client` and `cw_webui`, applications target the server using a command line and Web User interface ,respectively.

Use of these applications is described [here](use.md)


### Unit tests
Optionally, you can run unit tests.  There is a script to download nim, compile catwalk, and run a set of tests on  both server and python client.  This process is similar to the Github Actions continuous integration step which occurs when the software is updated.

These tests are run using a python virtual environment, and runs tests through a python client.

Install all dependencies into a virtual environment.  The skip-lock switch makes the virtual environment process much faster.
```
    pipenv install --skip-lock
```
Make the run_tests script executable
```
    chmod +x run_tests.sh
```
And run the tests 
```
    ./run_tests.sh
```

All tests should pass.