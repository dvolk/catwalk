"""Create plots based on data generated by bench.py."""

import json
import statistics
import sys

import argh
import matplotlib.pyplot as plt
import numpy as np
import scipy.stats


def go(filename):
    """Main function."""
    
    data = json.loads(open(filename).read())
    n_samples_analysed = data['number_of_samples']
    print("Number of samples analysed = ", n_samples_analysed)
    distance_times = data["distance_times"]
    sample_counts = data["sample_counts"]
    distances = distance_times.keys()
    averages = [statistics.mean(row.values()) for row in distance_times.values()]

    width = 4
    height = 4
    fig = plt.gcf()
    ax1 = fig.add_subplot(111)

    # plot 1
    # show the average comparison time for a sample against all samples for given
    # distances

    errors = [scipy.stats.sem(list(row.values())) for row in distance_times.values()]
    plt.xlabel("SNP Distance")
    plt.ylabel("Seconds")
    plt.ylim([0,4])
    ax1.errorbar(
        distances,
        averages,
        errors,
        elinewidth=1,
        capsize=0,
        color="r",
        label="Average time taken for comparison",
    )

    fig.set_size_inches(width, height)
    plt.title(f"Performance for dataset {sys.argv[1]}")
    ax1.set_xticks(ax1.get_xticks()[::5])
    save_file = f"{filename}-times.pdf"
    print(f"saving to {save_file}")
    plt.savefig(save_file)
    plt.close()

    # plot 2 (labelled A)
    # take the N samples above, sort by number of unknown positions, divide sorted
    # list into quarters and plot average comparison time against distance format
    # the four sets of samples

    sorted_by_unknown_positions = sorted(
        [
            {"sample_name": k, "unknown_positions": v["N"]}
            for k, v in sample_counts.items()
        ],
        key=lambda x: x["unknown_positions"],
    )

    dataS = np.array_split(sorted_by_unknown_positions, 4)
    linestyles = ["solid", "dotted", "dashed", "dashdot"]
    colors = ["blue", "red", "black", "cyan"]

    ax1 = plt.gca()
    fig = plt.gcf()

    for i, data in enumerate(dataS):
        xs = distances
        ys = list()
        errs = list()
        for distance in distances:
            vs = list()
            for v in data:
                sample_name = v["sample_name"]
                distance_time = distance_times[distance][sample_name]
                # express result as search time / number searched: allows comparison rate for TB and covide to be compared directly
                distance_time = distance_time / n_samples_analysed  
                distance_time = distance_time * 1e6
                vs.append(distance_time)
            ys.append(statistics.mean(vs))
            errs.append(scipy.stats.sem(vs))
        ax1.plot(
            xs,
            ys,
            color=colors[i],
            linestyle=linestyles[i],
            label=f"{i*25}%-{(i+1)*25}%",
        )

    # report standard errors
    for mean, stderr in zip(ys,errs):
        print(mean,stderr, stderr/mean)

    fig.set_size_inches(width, height)
    plt.xlabel("Comparison distance (SNVs)")
    plt.ylabel("Search time per sample in dataset [micros]")
    ax1.legend()
    #plt.title(f"Comparison time for # of unknown positions\n(dataset {sys.argv[1]})")
    plt.title(f"A")
    plt.ylim([0,4])
    ax1.set_xticks(ax1.get_xticks()[::5])
    save_file = f"{filename}-unknownpos.pdf"
    print(f"saving to {save_file}")
    plt.savefig(save_file)
    plt.close()

    # plot 3 (labelled 'B')
    # take the N samples above, sort by distance from reference, divide sorted
    # list into quarters and plot average comparison time against distance format
    # the four sets of samples

    sorted_by_unknown_positions = sorted(
        [
            {"sample_name": k, "refdist": v["A"] + v["C"] + v["G"] + v["T"]}
            for k, v in sample_counts.items()
        ],
        key=lambda x: x["refdist"],
    )

    dataS = np.array_split(sorted_by_unknown_positions, 4)

    ax1 = plt.gca()
    fig = plt.gcf()

    for i, data in enumerate(dataS):
        xs = distances
        ys = list()
        errs = list()
        for distance in distances:
            vs = list()
            for v in data:
                sample_name = v["sample_name"]
                distance_time = distance_times[distance][sample_name]
                # express result as search time / number searched: allows comparison rate for TB and covide to be compared directly
                distance_time = distance_time / n_samples_analysed
                distance_time = distance_time * 1e6
                vs.append(distance_time)
            ys.append(statistics.mean(vs))
            errs.append(scipy.stats.sem(vs))
        ax1.plot(
            xs,
            ys,
            color=colors[i],
            linestyle=linestyles[i],
            label=f"{i*25}%-{(i+1)*25}%",
        )

    fig.set_size_inches(width, height)
    plt.xlabel("Comparison distance (SNVs)")
    plt.ylabel("Search time per sample in dataset [micros]")
    ax1.legend()
    #plt.title(f"Comparison time by distance from reference\n(dataset {sys.argv[1]})")
    plt.title(f"B")
    plt.ylim([0,4])
    ax1.set_xticks(ax1.get_xticks()[::5])
    save_file = f"{filename}-refdist.pdf"
    print(f"saving to {save_file}")
    plt.savefig(save_file)
    plt.close()


if __name__ == "__main__":
    argh.dispatch_command(go)
