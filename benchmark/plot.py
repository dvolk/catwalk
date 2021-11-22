import statistics
import json
import sys

import matplotlib.pyplot as plt
from scipy.stats import pearsonr
import numpy as np


filename = sys.argv[1]
data = json.loads(open(filename).read())
distance_times = data["distance_times"]
sample_counts = data["sample_counts"]
sample_names = data["sample_names"]
number_of_samples = data["number_of_samples"]
distances = distance_times.keys()
averages = [statistics.mean(row.values()) for row in distance_times.values()]

# plot 1

fig = plt.gcf()
ax1 = fig.add_subplot(111)

errors = [statistics.stdev(row.values()) for row in distance_times.values()]
data_size = len(distance_times[list(distance_times.keys())[0]])
plt.xlabel("SNP Distance")
plt.ylabel("Seconds")
plt.errorbar(
    distances,
    averages,
    errors,
    elinewidth=1,
    capsize=0,
    color="r",
    label="Average time taken for comparison",
)
fig = plt.gcf()
fig.set_size_inches(18.5, 10.5)
# plt.savefig(f"{filename}-bars.png")
# plt.close()

# plot 2

n_counts = dict()
for sample_name in sample_names:
    n_counts[sample_name] = sample_counts[sample_name]["N"]

ax2 = ax1.twinx()
ax2.set_ylim(-1, 1)

npos_corrs = dict()
for distance in distances:
    xs = list()
    ys = list()
    for sample_name in sample_names:
        xs.append(n_counts[sample_name])
        ys.append(distance_times[distance][sample_name])
    npos_corrs[distance] = pearsonr(xs, ys)[0]

ax2.plot(
    distances,
    npos_corrs.values(),
    color="g",
    label="Correlation between number of unknown positions and comparison time",
)

fig.set_size_inches(18.5, 10.5)
plt.xlabel("Comparison distance")
plt.ylabel("Correlation")
# plt.savefig(f"{filename}-n_corr.png")
# plt.close()

# plot 3

diff_count = dict()
for sample_name in sample_names:
    c = (
        sample_counts[sample_name]["A"]
        + sample_counts[sample_name]["C"]
        + sample_counts[sample_name]["G"]
        + sample_counts[sample_name]["T"]
    )
    # print(c)
    diff_count[sample_name] = c


npos_corrs = dict()
for distance in distances:
    xs = list()
    ys = list()
    for sample_name in sample_names:
        xs.append(diff_count[sample_name])
        ys.append(distance_times[distance][sample_name])
    npos_corrs[distance] = pearsonr(xs, ys)[0]

ax2.plot(
    distances,
    npos_corrs.values(),
    color="b",
    label="Correlation between distance from reference and comparison time",
)

lines, labels = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax2.legend(lines + lines2, labels + labels2, loc=4)

fig.set_size_inches(13, 9)
plt.xlabel("Comparison distance")
plt.ylabel("Correlation")
plt.tight_layout()
plt.savefig(f"{filename}-acgt_corr.png")
plt.close()

# plot 4

# print(list(np.array_split(sorted(data), 2)))

sorted_by_unknown_positions = sorted(
    [{"sample_name": k, "unknown_positions": v["N"]} for k, v in sample_counts.items()],
    key=lambda x: x["unknown_positions"],
)

data1, _, _, data2 = np.array_split(sorted_by_unknown_positions, 4)
# print(data1, data2)

ax1 = plt.gca()
fig = plt.gcf()

xs = distances
ys = list()
errs = list()
for distance in distances:
    vs = list()
    for v in data1:
        sample_name = v["sample_name"]
        unknown_positions = v["unknown_positions"]
        distance_time = distance_times[distance][sample_name]
        vs.append(distance_time)
    ys.append(statistics.mean(vs))
    errs.append(statistics.stdev(vs) / 2)
print(ys)
ax1.errorbar(xs, ys, errs, color="b")

xs = distances
ys = list()
errs = list()
for distance in distances:
    vs = list()
    for v in data2:
        sample_name = v["sample_name"]
        unknown_positions = v["unknown_positions"]
        distance_time = distance_times[distance][sample_name]
        vs.append(distance_time)
    ys.append(statistics.mean(vs))
    errs.append(statistics.stdev(vs) / 2)
print(ys)
ax1.errorbar(xs, ys, errs, color="r")

fig.set_size_inches(13, 9)
plt.xlabel("Comparison distance")
plt.ylabel("Time [s]")
ax1.set_xticks(ax1.get_xticks()[::5])
plt.title(
    "Comparison time for samples with lowest and highest 25% of unknown positions (red is highest)"
)
plt.savefig(f"{filename}-unknownpos2525.png")
plt.close()

# plot 5

# print(list(np.array_split(sorted(data), 2)))

sorted_by_unknown_positions = sorted(
    [
        {"sample_name": k, "refdist": v["A"] + v["C"] + v["G"] + v["T"]}
        for k, v in sample_counts.items()
    ],
    key=lambda x: x["refdist"],
)

data1, _, _, data2 = np.array_split(sorted_by_unknown_positions, 4)
# print(data1, data2)

ax1 = plt.gca()
fig = plt.gcf()

xs = distances
ys = list()
errs = list()
for distance in distances:
    vs = list()
    for v in data1:
        sample_name = v["sample_name"]
        refdist = v["refdist"]
        distance_time = distance_times[distance][sample_name]
        vs.append(distance_time)
    ys.append(statistics.mean(vs))
    errs.append(statistics.stdev(vs) / 2)
print(ys)
ax1.errorbar(xs, ys, errs, color="b")

xs = distances
ys = list()
errs = list()
for distance in distances:
    vs = list()
    for v in data2:
        sample_name = v["sample_name"]
        refdist = v["refdist"]
        distance_time = distance_times[distance][sample_name]
        vs.append(distance_time)
    ys.append(statistics.mean(vs))
    errs.append(statistics.stdev(vs) / 2)
print(ys)
ax1.errorbar(xs, ys, errs, color="r")

fig.set_size_inches(13, 9)
plt.xlabel("Comparison distance")
plt.ylabel("Time [s]")
ax1.set_xticks(ax1.get_xticks()[::5])
plt.title(
    "Comparison time for samples with lowest and highest 25% distance from reference (red is highest)"
)
plt.savefig(f"{filename}-refdist2525.png")
plt.close()
