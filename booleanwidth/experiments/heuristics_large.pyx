from ..lboolw import compute_lboolw
from ..lboolc import compute_lboolc
from ..heuristic import (greedy, greedy_cost, check_decomposition, random_decomposition,
                         greedy_light, lun, min_cover_size, new_lun, relative_neighborhood,
                         minfront, new_lun, neighborhood_size, greedy_light_single_start,
                         min_cover_front, lun_mincover,
                         relative_neighborhood_dense, relative_neighborhood_sparse
                         )
from .common import generate_random_graphs, compute_data, compute_avg_data, plot_data

from numpy import arange, mean, linspace, logspace
import matplotlib.pyplot as plt
import math

graphsize = 80
p_values = [round(p, 5) for p in arange(0.05, 1, 0.05)] # Linear
#p_values = list(logspace(-10, 0, 19, endpoint=False)) # Logarithmic
#print(p_values)
samples = 20
total_nr = samples * len(p_values)
codomain = 30

def run():
    inputdir = 'input/random80/' # Must end with slash
    outputdir = 'experiment-data/heuristics_large/' # Must end with slash

            #('random', random),
    experiments = [
            #('relative_neighborhood_sparse', relative_neighborhood_sparse),
            #('relative_neighborhood_dense', relative_neighborhood_dense),
            #('relative_neighborhood', relative_neighborhood),
            #('relative_neighborhood', relative_neighborhood),
            #('greedy', None)
            ]
    for experiment_name, score_function in experiments:
        def compute(graph):
            decomposition = greedy_light_single_start(graph, score_function)
            value = check_decomposition(graph, decomposition)
            #value = greedy(graph)[0]
            return value
        def avg(values):
            #return math.log(mean(values)/graphsize, 2)
            return math.log(mean(values), 2)

        #generate_random_graphs(graphsize, p_values, samples, inputdir)
        compute_data(inputdir, outputdir, experiment_name, compute, total_nr)
        compute_avg_data(outputdir, experiment_name, avg, total_nr)


    filenames = [
            #'random',
            #'relative_neighborhood',
            #'relative_neighborhood_dense',
            'relative_neighborhood_sparse',
            #'greedy_lboolw',
            #'lun_single',
            #'lun',
            #'rn', 'mf',
            #'frank_lun',
            #'frank_rn',
            #'new_lun',
            #'rn_single',
            #'rn2',
            #'minfront_single',
            #'mf2',
            #'mf3',
            #'mf5',
            #'lun_mincover', 'rn_mincover',
            #'min_cover_front_single', 'minfront_single', 'mincover_single'
            ]
    plot_data(outputdir, filenames, filenames, graphsize, codomain)
