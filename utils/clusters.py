"""Create a graphviz compatible output file from the neighbour list
dumped by compare_neighbours.py."""

import json

import argh
import networkx


def main(neighbours_file, cluster_distance):
    """Main function."""
    xs = json.loads(open(neighbours_file).read())

    ps = list()
    for name1, neighbours in xs.items():
        for name2, distance in neighbours:
            if distance <= int(cluster_distance):
                ps.append((name1, name2, distance))

    gs = networkx.Graph()

    for p in ps:
        gs.add_edge(p[0], p[1], weight=p[2])

    print(networkx.drawing.nx_pydot.to_pydot(gs).to_string())


if __name__ == "__main__":
    argh.dispatch_command(main)
