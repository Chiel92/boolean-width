from .graph import Graph
from .bitset import BitSet
from .utils import DictChain

from random import randint, choice, random
from copy import deepcopy


class Bipartite(Graph):

    def __init__(self, group1=None, group2=None):
        Graph.__init__(self)

        self.group1 = group1 or BitSet()
        self.group2 = group2 or BitSet()

        for v in self.vertices:
            self.neighborhoods[v] = BitSet()

    @property
    def vertices(self):
        return self.group1 | self.group2

    def add(self, vertices, group):
        """Add a new vertex to the graph."""
        if not self.vertices.disjoint(vertices):
            raise ValueError('Graph already contain some of [{}]'.format(vertices))

        if group == 1:
            self.group1 |= vertices
        elif group == 2:
            self.group2 |= vertices
        else:
            raise ValueError

        for v in vertices:
            self.neighborhoods[v] = BitSet()

    def remove(self, vertices):
        """Remove vertices from the graph."""
        if not vertices in self.vertices:
            raise ValueError('Graph don\'t contain some of [{}]'.format(vertices))

        for v in vertices:
            for w in self(v):
                self.disconnect(v, w)

        for v in vertices:
            if v in self.group1:
                self.group1 -= v
            else:
                self.group2 -= v

        for v in vertices:
            del self.neighborhoods[v]

    def connect(self, v, w):
        """Connect two vertices."""
        if not ((v in self.group1 and w in self.group2)
                or
                (v in self.group2 and w in self.group1)):
            raise ValueError

        Graph.connect(self, v, w)

    def subgraph(self, vertices):
        """Return a graph which is the subgraph of self induced by given vertex subset."""
        graph = Bipartite(self.group1 & vertices, self.group2 & vertices)

        for v in graph.vertices:
            graph.neighborhoods[v] &= vertices

        return graph

    def bipartite_complement(self):
        """Construct a graph representing the bipartite complement of self."""
        graph = Bipartite(self.group1, self.group2)

        for v in graph.group1:
            for w in graph.group2:
                if not v in self[w]:
                    graph.connect(v, w)

        return graph

    def gridify(self, width=None):
        """TODO"""
        if not width:
            width = len(self.vertices)

        size = len(self.vertices)
        counter = size

        graph = Graph(self.vertices, self.neighborhoods)

        for _ in range(width):
            for _ in self.vertices:
                new = BitSet.from_identifier(counter)
                original = BitSet.from_identifier(counter % size)
                graph.add(new)
                for original_neighbor in self.neighborhoods[original]:
                    new_neighbor_id = (original_neighbor.identifier
                                       + size * (counter // size))
                    try:
                        graph.connect(new, BitSet.from_identifier(new_neighbor_id))
                    except ValueError:
                        try:
                            graph.connect(new, BitSet.from_identifier(new_neighbor_id - size))
                        except ValueError:
                            pass

                counter += 1

        # TODO: add vertical edges
        return graph

    @staticmethod
    def generate_random(nr_vertices, nr_edges=0):
        if not 0 <= nr_edges <= (nr_vertices / 2) ** 2:
            raise ValueError

        if not nr_edges:
            nr_edges = 0.5

        if nr_edges < 1:
            # Split the number of vertices on both sides
            size1 = randint(1, nr_vertices - 1)
            size2 = nr_vertices - size1

            # For both groups create vertices
            group1 = range(size1)
            group2 = range(size1, size1 + size2)

            graph = Bipartite(BitSet.from_identifier(*group1), BitSet.from_identifier(*group2))

            # Add random edges between groups
            for v in graph.group1:
                for w in graph.group2:
                    if random() < 0.5:
                        graph.connect(v, w)
            return graph
        else:
            # Split the number of vertices on both sides
            # such that enough edges can be placed
            while 1:
                size1 = randint(1, nr_vertices - 1)
                size2 = nr_vertices - size1
                if size1 * size2 >= nr_edges:
                    break

            # For both groups create vertices
            group1 = range(size1)
            group2 = range(size1, size1 + size2)

            graph = Bipartite(BitSet.from_identifier(*group1), BitSet.from_identifier(*group2))

            # Add random edges between groups
            for _ in range(nr_edges):
                while 1:
                    v = BitSet.from_identifier(choice(group1))
                    w = BitSet.from_identifier(choice(group2))
                    if not w in graph[v]:
                        break
                graph.connect(v, w)

            return graph
