from graph import Graph, Vertex
from vertex import VertexSet
from random import randint, choice
from utils import DictChain


class Tree(Graph):

    def __init__(self):
        Graph.__init__(self)
        self.root = None

    def depth(self, root=None):
        root = root or self.root

        def recursion(vertex, parent):
            if len(vertex.neighbors) < 2:
                return 1
            return max(recursion(self[bchild], vertex) for bchild in vertex.neighbors
                       if not parent or self[bchild] != parent) + 1

        return recursion(root, None)

    def count_branches(self):
        """
        Count the number of branches, i.e. the sum of all branches exceeding degree 2.
        """
        return sum(len(v.neighbors) - 2 for v in self.vertices if len(v.neighbors) > 2)

    def count_branching_nodes(self):
        """
        Count the number of branches, i.e. the sum of all branches exceeding degree 2.
        """
        return sum(1 for v in self.vertices if len(v.neighbors) > 2)

    @staticmethod
    def generate_random(nr_vertices, maxdegree=3):
        if maxdegree < 2:
            raise ValueError

        graph = Tree()
        root = Vertex(0)
        graph.add_vertex(root)

        for i in range(1, nr_vertices):
            while 1:
                v = choice(graph.vertices)
                if len(v.neighbors) < maxdegree:
                    w = Vertex(i)
                    graph.add_vertex(w)
                    graph.connect(v, w)
                    break

        return graph

    @staticmethod
    def generate_random_binary(nr_vertices):
        graph = Tree()
        graph.root = Vertex(0)
        graph.add_vertex(graph.root)

        leaves = [graph.root]
        for i in range(1, nr_vertices):
            v = leaves[0]
            w = Vertex(i)
            graph.add_vertex(w)
            graph.connect(v, w)
            leaves.append(w)

            if len(v.neighbors) == 3:
                leaves.pop(0)

        return graph