from .bitset import (iterate, subsets, subsets_of_size, size, invert, tostring, subtract,
                        index, domain, contains)
from .dynamicprogramming import booldimtable, compute_booldim

# New fast exact algos

def compute_lboolw_decomposition(G):
    lboolw, booldim = compute_lboolw_space(G)
    decomposition = construct_lboolw_decomposition(lboolw, booldim, G.vertices)
    return lboolw[G.vertices], decomposition, booldim

def compute_lboolw_space(G):
    k = 1
    while 1:
        result = compute_lboolw_with_upperbound_space(G, k)
        if result == False:
            k *= 2
        else:
            return result

def compute_lboolw(G):
    k = 1
    while 1:
        result = compute_lboolw_with_upperbound(G, k)
        if result == False:
            k *= 2
        else:
            return result

def compute_lboolw_with_upperbound_space(G, k):
    #print('Upperbound: {}'.format(k))
    V = G.vertices

    booldim = {}
    booldim[0L] = 1
    compute_booldim_space(G, k, booldim, 0, set([0]))

    lboolw = {}
    lboolw[0L] = 0

    for i in range(1, size(V) + 1):
        for X in subsets_of_size(V, i):
            for v in iterate(X):
                X_v = subtract(X, v)
                if X_v in lboolw and X in booldim and lboolw[X_v] <= k:
                    if X not in lboolw:
                        lboolw[X] = max(booldim[X], lboolw[X_v])
                    else:
                        lboolw[X] = min(lboolw[X], max(booldim[X], lboolw[X_v]))

    if V in lboolw:
        return lboolw, booldim
    else:
        return False

def compute_booldim_space(G, k, booldim, X, UN_X):
    for v in iterate(G.vertices - X):
        Y = X | v
        if Y not in booldim:
            UN_Y = compute_next_un(G, Y, v, UN_X)
            booldim[Y] = len(UN_Y)
            if booldim[Y] <= k:
                compute_booldim_space(G, k, booldim, Y, UN_Y)

def compute_next_un(G, X, v, UN_X_v):
    """Compute UN of X, based on the UN of X-v"""
    U = set()
    for S in UN_X_v:
        U.add(subtract(S, v))
        #U.add(subtract(S, v) | (G.neighborhoods[v] & invert(subtract(X, v), domain(G.vertices))))
        U.add(subtract(S, v) | (G.neighborhoods[v] & (G.vertices - subtract(X, v))))
    return U


# NOTE: lbw(X) also takes booldim(X) into account

def compute_lboolw_with_upperbound(G, k):
    print('Upperbound: {}'.format(k))
    V = G.vertices

    lboolw = {}
    lboolw[0L] = 0
    booldim = {}
    booldim[0L] = 1
    un = {}
    un[0L] = {0L}

    for i in range(1, size(V) + 1):
        #for X in subsets(V, i, i): # Improve filtering
        for X in subsets_of_size(V, i):
            for v in iterate(X):
                X_v = subtract(X, v)
                if X_v in lboolw and lboolw[X_v] <= k:
                    if X not in booldim:
                        un[X] = compute_next_un(G, X, v, un[X_v])
                        booldim[X] = len(un[X])

                    if X not in lboolw:
                        lboolw[X] = max(booldim[X], lboolw[X_v])
                    else:
                        lboolw[X] = min(lboolw[X], max(booldim[X], lboolw[X_v]))


    if V in lboolw:
        return lboolw, booldim
    else:
        return False


def construct_lboolw_decomposition(lboolw, booldim, subset, bound=None):
    if bound == None:
        bound = lboolw[subset]

    if size(subset) > 1:
        for v in iterate(subset):
            # TODO: fix if statement
            if (v in lboolw and lboolw[v] <= bound and (subtract(subset, v)) in lboolw and
                    lboolw[subtract(subset, v)] <= bound):
                yield booldim[subset - v], (v, subset - v)
                yield from construct_lboolw_decomposition(lboolw, booldim, subset - v, bound)
                break

def print_un(un):
    print('{{{}}}'.format(', '.join(tostring(s) for s in un)))


# Old algos

def linearboolwidthtable(graph):
    """
    bwtable[A] contains the booleanwidth of the subtree of all cuts inside A.
    The cut which produced A itself is thus not included.
    """
    booldim = booldimtable(graph)

    cdef long v, A, B

    # Init table
    bwtable = {}
    for v in iterate(graph.vertices):
        if graph.neighborhoods[v] == 0L:
            bwtable[v] = 1
        else:
            bwtable[v] = 2

    # Solve recurrence
    for A in subsets(graph.vertices, 2):
        bwtable[A] = min(max(booldim[B], booldim[A - B],
                             bwtable[B], bwtable[A - B])
                         for B in iterate(A))

    return bwtable, booldim


def linear_decomposition(table, booldim, long A):
    """Reconstruct optimal linear decomposition from DP table."""
    bound = table[A]
    if size(A) > 1:
        for v in iterate(A):
            if (table[v] <= bound and booldim[v] <= bound
                    and booldim[A - v] <= bound and table[A - v] <= bound):
                yield booldim[A - v], (v, A - v)
                yield from linear_decomposition(table, booldim, A - v)

                break


def linearbooleanwidth(graph):
    bwtable, booldim = linearboolwidthtable(graph)
    return (bwtable[graph.vertices],
            #booldim,
            list(linear_decomposition(bwtable, booldim, graph.vertices)))


def dp_greedy_lbw(bwtable, booldim, long A, int universe):
    """A is unprocessed."""
    bound = bwtable[A]
    if size(A) > 1:
        print('trying greedy')
        # Try greedy step
        for B in iterate(A):
            if size(A) == universe:
                greedybound = 1
            else:
                greedybound = booldim[A]

            print('Current booldim', greedybound)
            print(tostring(B), booldim[A - B])
            if booldim[A - B] < greedybound:
                print('choosing {} greedy'.format(tostring(B)))
                yield (B, A - B)
                yield from dp_greedy_lbw(bwtable, booldim, B, universe)
                yield from dp_greedy_lbw(bwtable, booldim, A - B, universe)
                return
        print('No greedy step found, trying nongreedy')
        # Perform normal reconstruction
        for B in iterate(A):
            if (bwtable[B] <= bound and booldim[B] <= bound
                    and booldim[A - B] <= bound and bwtable[A - B] <= bound):
                print('choosing {} nongreedy'.format(tostring(B)))
                yield (B, A - B)
                yield from dp_greedy_lbw(bwtable, booldim, B, universe)
                yield from dp_greedy_lbw(bwtable, booldim, A - B, universe)
                return


def greedy_lbw(graph, depth=1):
    """Assumption: no islets"""
    todo = graph.vertices
    width = 0
    decomposition = []
    while size(todo) > 1:
        _, x = min(
                (max(compute_booldim(graph, todo - v), greedy_lookahead(graph, todo - v, depth - 1)), v)
                for v in iterate(todo)
            )
        bd = compute_booldim(graph, todo - x)
        decomposition.append((bd, (x, todo - x)))
        width = max(bd, width)
        todo -= x

    return width, decomposition


def greedy_lookahead(graph, todo, depth):
    if size(todo) < 2 or depth < 1:
        return 0

    return min(max(compute_booldim(graph, todo - v), greedy_lookahead(graph, todo - v, depth - 1))
                   for v in iterate(todo))


def relative_neighborhood_lbw(graph, depth=1):
    """Assumption: no islets"""
    todo = graph.vertices
    width = 0
    decomposition = []
    while size(todo) > 1:
        # Compute neighbor hood of Left
        N_left = 0L
        for v in iterate(graph.vertices - todo):
            N_left |= graph.neighborhoods[v]

        # Pick x with best ratio
        _, x = min((min(neighborhood_ratio(graph, N_left, v),
                    relative_neighborhood_lookahead(graph, todo - v, depth - 1)), v)
                    for v in iterate(todo))
        bd = compute_booldim(graph, todo - x)
        decomposition.append((bd, (x, todo - x)))
        width = max(bd, width)
        todo -= x

    return width, decomposition


def neighborhood_ratio(graph, N_left, v):
    internal = graph.neighborhoods[v] & N_left
    external = graph.neighborhoods[v] - internal
    try:
        return float(size(external)) / float(size(internal))
    except ZeroDivisionError:
        #return float('infty')
        return 999999999


def relative_neighborhood_lookahead(graph, todo, depth):
    if size(todo) < 2 or depth < 1:
        return 0

    # Compute neighbor hood of Left
    N_left = 0L
    for v in iterate(graph.vertices - todo):
        N_left |= graph.neighborhoods[v]

    return min(min(neighborhood_ratio(graph, N_left, v), relative_neighborhood_lookahead(graph, todo - v, depth - 1)) for v in iterate(todo))
