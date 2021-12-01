"""
A catwalk client for python

Tested on Linux with python 3.9
Uses linux-specific commands to run the server, so is not expected to work on Windows.

unittests:
pipenv run python -m unittest test/test_pycw_client.py

A component of the findNeighbour4 system for bacterial relatedness monitoring
Copyright (C) 2021 David Wyllie david.wyllie@phe.gov.uk
repo: https://github.com/davidhwyllie/findNeighbour4

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT License as published
by the Free Software Foundation.  See <https://opensource.org/licenses/MIT>, and the LICENSE file.

"""

import shlex
import time
import json
import requests
import logging
import os
import psutil
import uuid
import warnings


class CatWalkServerInsertError(Exception):
    """insert failed"""

    def __init__(self, expression, message):
        self.expression = expression
        self.message = message


class CatWalkServerDeleteError(Exception):
    """delete failed"""

    def __init__(self, expression, message):
        self.expression = expression
        self.message = message


class CatWalkServerDidNotStartError(Exception):
    """the catwalk server did not start"""

    def __init__(self, expression, message):
        self.expression = expression
        self.message = message


class CatWalkBinaryNotAvailableError(Exception):
    """no catwalk binary"""

    def __init__(self, expression, message):
        self.expression = expression
        self.message = message

class CatWalkMultipleServersRunningError(Exception):
    """multiple catwalk servers with identical specification are running"""

    def __init__(self, message):
        self.message = message

class CatWalk:
    """start, stop, and communicate with a CatWalk server"""

    def __init__(
        self,
        cw_binary_filepath,
        reference_name,
        reference_filepath,
        mask_filepath,
        max_n_positions,
        bind_host,
        bind_port,
        identity_token=None,
        unittesting=False,
    ):
        """
        Start the catwalk process in the background, if it not running.
        Parameters:
        cw_binary_filepath
        reference_name
        reference_filepath
        mask_filepath
        max_n_positions
        bind_host
        bind_port

        identity_token: a string identifying the process.  If not provided, a guid is generated
        unittesting: if True, will shut down and restart (empty) any catwalk on bind_port on creation
        """

        no_catwalk_exe_message = """
The catWalk client could not find a CatWalk server application.  This is because either:
i) the cw_binary_filepath parameter was None
ii) the above, and there is no CW_BINARY_FILEPATH environment variable.  To set this, you insert a line like
CW_BINARY_FILEPATH=/path/to/cw/executable
in either
.bashrc - if you're not using a virtual environment
.env    - a file in the same directory as the PipFile, if you are using a virtual environment.
          This file is not committed into the repository, so you'll have to create it once in your installation.
"""
        # if cw_binary_filepath is "", we regard it as not specified (None)
        if cw_binary_filepath == "":
            cw_binary_filepath = None

        # if cw_binary_filepath is None, we check the env. variable CW_BINARY_FILEPATH and use that if present.
        if cw_binary_filepath is None:
            if "CW_BINARY_FILEPATH" in os.environ:
                cw_binary_filepath = os.environ["CW_BINARY_FILEPATH"]
            else:
                raise CatWalkBinaryNotAvailableError(
                    expression=None, message=no_catwalk_exe_message
                )
        if not os.path.exists(cw_binary_filepath):
            raise FileNotFoundError(
                "Was provided a cw_binary_filepath, but there is no file there {0}".format(
                    cw_binary_filepath
                )
            )

        # store parameters
        self.bind_host = bind_host
        self.bind_port = int(bind_port)  # has to be an integer
        self.cw_url = "http://{0}:{1}".format(bind_host, self.bind_port)
        self.cw_binary_filepath = cw_binary_filepath
        self.reference_filepath = reference_filepath
        self.mask_filepath = mask_filepath
        self.max_n_positions = int(max_n_positions)
        self.reference_name = reference_name
        self.instance_stem = "CatWalk-PORT-{0}".format(self.bind_port)
        if identity_token is None:
            identity_token = str(uuid.uuid1())
        self.instance_name = "{0}-MAXN-{1}-{2}".format(
            self.instance_stem, self.max_n_positions, identity_token
        )

        # start up if not running
        if unittesting and self.server_is_running():
            self.stop()  # removes any data from server  and any other running cws

        if not self.server_is_running():
            self.start()

        if not self.server_is_running():  # startup failed
            raise CatWalkServerDidNotStartError()

    def _running_servers(self):
        """ returns details of running servers matching the details of this server
        
        There should be either 0 or 1 of these only """

        servers = []
        for proc in psutil.process_iter():
            if "cw_server" in proc.name():
                cmdline_parts = proc.cmdline()
                for i, cmdline_part in enumerate(proc.cmdline()):
                    if cmdline_part == "--instance_name":
                        if cmdline_parts[i + 1].startswith(self.instance_stem):
                            servers.append(cmdline_parts)
        return servers

    def server_is_running(self):
        """returns true if the relevant process is running, otherwise false.
        
        The alternative strategy, returning true if a response is received by the server,
        can result in reporting false if the server is busy """


        servers = self._running_servers()
        if len(servers) == 0:
            return False
        elif len(servers) == 1:
            return True
        else:
            raise CatWalkMultipleServersRunningError(message = "{0} servers with specification {1} detected".format(len(servers), self.instance_stem))      # there cannot be multiple servers running
            
    def start(self):
        """starts a catwalk process in the background"""
        cw_binary_filepath = shlex.quote(self.cw_binary_filepath)
        instance_name = shlex.quote(self.instance_name)
        reference_filepath = shlex.quote(self.reference_filepath)
        mask_filepath = shlex.quote(self.mask_filepath)

        if not self.server_is_running():
            cmd = f"nohup {cw_binary_filepath} --instance_name {instance_name}  --bind_host {self.bind_host} --bind_port {self.bind_port} --reference_filepath {reference_filepath}  --mask_filepath {mask_filepath} --max_n_positions {self.max_n_positions} > cw_server_nohup.out &"
            logging.info("Attempting startup of CatWalk server : {0}".format(cmd))

            os.system(cmd)      # synchronous: will return when it has started

            time.sleep(1)       # short break to ensure it has started
        info = self.info()
        if info is None:
            raise CatWalkServerDidNotStartError()
        else:
            logging.info("Catwalk server running: {0}".format(info))

    def stop(self):
        """stops the catwalk server launched by this process, if running.  The process is identified by a uuid, so only one catwalk server will be shut down."""
        for proc in psutil.process_iter():
            if "cw_server" in proc.name():
                cmdline_parts = proc.cmdline()
                for i, cmdline_part in enumerate(proc.cmdline()):
                    if cmdline_part == "--instance_name":
                        if cmdline_parts[i + 1].startswith(self.instance_stem):
                            proc.kill()
        if self.server_is_running():
            warnings.warn(
                "Attempt to shutdown a catwalk process with name cw_server and --instance_name beginning with {0} failed.  It may be that another process (with a different instance name) is running on port {1}.  Review running processes (ps x) and kill residual processes on this port  manually if appropriate".format(
                    self.instance_stem, self.bind_port
                )
            )

    def stop_all(self):
        """stops all catwalk servers"""
        nKilled = 0
        for proc in psutil.process_iter():
            if "cw_server" in proc.name():
                proc.kill()
                nKilled += 1
        if nKilled > 0:
            warnings.warn(
                "Catwalk client.stop_all() executed. Kill instruction issues on {0} processes.  Beware, this will kill all cw_server processes on the server, not any specific one".format(
                    nKilled
                )
            )

    def info(self):
        """
        Get status information from catwalk
        """
        target_url = "{0}/info".format(self.cw_url)

        r = requests.get(target_url)
        r.raise_for_status()        # report errors

        return r.json()

    def _filter_refcomp(self, refcomp):
        """examines the keys in a dictionary, refcomp, and only lets through keys with a list
        This will remove Ms (linked to a dictionary) and invalid keys which are linked to an integer.
        These keys are not required by catwalk
        """
        refcompressed = {}
        for key in refcomp.keys():
            if isinstance(refcomp[key], set):
                refcompressed[key] = list(refcomp[key])
            elif isinstance(refcomp[key], list):
                refcompressed[key] = refcomp[key]
            else:
                pass  # drop everything else, such as invalid
        return refcompressed

    def add_sample_from_refcomp(self, name, refcomp):
        """
        Add a reference compressed (dict with ACGTN keys and list of positions as values) sample.
        Note, if the sample already exists, it will not be added twice.
        The json dict must have all keys: ACGTN, even if they're empty

        Returns:
        status code
        201 = added successfully
        200 = was already present
        """

        # note particular way of creating json, but catwalk accepts this (refcomp has to be in '')
        # cannot json serialise sets; use lists instead
        if refcomp is None:
            # issue warning, return
            logging.warning("Asked to reload catwalk with {0} but the refcomp was None".format(name))

        refcompressed = self._filter_refcomp(refcomp)
        payload = {"name": name, "refcomp": json.dumps(refcompressed), "keep": True}

        r = requests.post(
            "{0}/add_sample_from_refcomp".format(self.cw_url), json=payload
        )
        r.raise_for_status()
        if r.status_code not in [200, 201]:
            raise CatWalkServerInsertError(
                message="Failed to insert {0}; return code was {1}".format(name, r.text)
            )
        return r.status_code

    def remove_sample(self, name):
        """deletes a sample called name"""

        r = requests.get("{0}/remove_sample/{1}".format(self.cw_url, name))
        r.raise_for_status()
        if r.status_code not in [200]:
            raise CatWalkServerDeleteError(
                message="Failed to delete {0}; return code was {1}".format(name, r.text)
            )
        return r.status_code

    def neighbours(self, name, distance=None):
        """get neighbours.  neighbours are recomputed on demand.

        Parameters:
        name:  the name of the sample to search for
        distance: the maximum distance reported.  if distance is not supplied, 99 is used.
        """
        if not distance:
            logging.warning("no distance supplied. Using 99")
            distance = 99
        
        distance = int(distance)        # if a float, url contstruction may fail

        r = requests.get("{0}/neighbours/{1}/{2}".format(self.cw_url, name, distance))
        r.raise_for_status()
        j = r.json()
        return [(sample_name, int(distance_str)) for (sample_name, distance_str) in j]

    def sample_names(self):
        """get a list of samples in catwalk"""
        r = requests.get("{0}/list_samples".format(self.cw_url))
        r.raise_for_status()
        return r.json()
