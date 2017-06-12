% Creates the O (order_constraints) and S (sim_constraints) matrices for
% passing into RankSVM.
% descend_ranks: A vector containing the ranks of all objects in descending
% order (i.e., a lower rank means we want the magnitude of that object to
% be higher).
% gen_sim_constraints: Whether to generate a non-empty S matrix.

function [order_constraints, sim_constraints] = ranksvm_constraints(descend_ranks, pairs, gen_sim_constraints)
num_objs = length(descend_ranks);
num_pairs = size(pairs, 1);

order_constraints = zeros(num_pairs, num_objs);
sim_constraints = [];
order_consi = 0;
sim_consi = 0;

for pairi = 1 : num_pairs
    obj1 = pairs(pairi, 1);
    obj2 = pairs(pairi, 2);
    rank1 = descend_ranks(obj1);
    rank2 = descend_ranks(obj2);
    if rank1 < rank2
        order_consi = order_consi + 1;
        order_constraints(order_consi, obj1) = 1;
        order_constraints(order_consi, obj2) = -1;
    elseif rank1 > rank2
        order_consi = order_consi + 1;
        order_constraints(order_consi, obj1) = -1;
        order_constraints(order_consi, obj2) = 1;
    elseif gen_sim_constraints
        sim_consi = sim_consi + 1;
        sim_constraints(sim_consi, num_objs) = 0;
        sim_constraints(sim_consi, obj1) = 1;
        sim_constraints(sim_consi, obj2) = -1;
    end
end

order_constraints = sparse(order_constraints(1 : order_consi, :));
sim_constraints = sparse(sim_constraints);
