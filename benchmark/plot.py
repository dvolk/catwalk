import statistics
import json
import sys

import matplotlib.pyplot as plt

data = json.loads(open(sys.argv[1]).read())

c = 0
for k, v in data.items():
    plt.scatter(range(len(v)), v, 1)
    c = c + 1

fig = plt.gcf()
fig.set_size_inches(18.5, 10.5)
plt.savefig("all_comparison_times.png", dpi=400)
plt.close()

distances = data.keys()
averages = [statistics.mean(row) for row in data.values()]
errors = [statistics.stdev(row) for row in data.values()]
data_size = len(data[list(data.keys())[0]])
plt.xlabel("SNP Distance")
plt.ylabel("Seconds")
plt.title(
    f"Average (n={data_size}) time taken for comparisons for different SNP distances"
)
plt.errorbar(distances, averages, errors, elinewidth=1, capsize=0, fmt=".")
fig = plt.gcf()
fig.set_size_inches(18.5, 10.5)
plt.savefig("bars.png")
