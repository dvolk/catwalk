# run_simulation.sh
pipenv install . --skip-lock

# launch server in one terminal
./cw_server --instance-name=test_sim --reference-filepath=reference/nc_045512.fasta --mask-filepath=reference/covid-exclude.txt

# generate simulated datasets in another
pipenv run python3 introduce_n.py

# load data
pipenv run python3 

# in python shell
import requests
requests.post("http://localhost:5000/add_samples_from_mfsl", json={"filepath": "/home/ubuntu/catwalk_sim/benchmark/sim/mutated_sequences.fa"})
exit()

# run benchmark in linux shell
pipenv run python3 ../bench.py -N 1000 -d $(seq -s ',' 0 25) > sim_test.json

# produce output
pipenv run python3 ../plot.py sim_test.json
