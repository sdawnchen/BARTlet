% Runs RankSVM with the specified ordered pairs (which_pairs) and saves the
% resulting weights. Also calculates magnitudes according to the RankSVM
% weights for the 44 Leuven (or 77 topics) animals.

clear all;

input = 'leuven';%'topics';%
% Which ordered pairs to give to RankSVM
which_pairs = 'top3bot3vsall_rand100';%'top5bot5vsall';%'rand5adj';%'top3bot3vsall';%'top1bot1vsall';%'all';%'rand100';'eq20all';%
use_sim_constraints = false;%true;%   % whether to use similarity constraints when running RankSVM

continua_names = {'size', 'fierceness', 'intelligence', 'speed'};
num_continua = length(continua_names);

if strcmp(input, 'topics')
    corpus = '_wiki_';
    sample_str = 'concat213_30r0.8';
else
    corpus = '';
    sample_str = '';
end

headings = {'Animal', 'Rating', 'Magnitude'};
weights_folder = sprintf('results/%s/weights/ranksvm', input);
if ~exist(weights_folder, 'dir')
    mkdir(weights_folder);
end
results_folder = sprintf('results/%s/magnitudes', input);
if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end
results_file = sprintf('%s/%s_mag_ranksvm_%s_pairs_sim%d.xlsx', ...
    results_folder, input, which_pairs, use_sim_constraints);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load data
load('data_animals_hm_ratings.mat');
all_obj_ratings_vecs = all_obj_vecs;
load(sprintf('data_animals_hm_%s%s%s_processed.mat', input, corpus, sample_str));
all_obj_ratings_vecs = all_obj_ratings_vecs(all_hm_indices(to_hm_indices), :);
all_obj_names = all_obj_names(to_hm_indices);
all_obj_vecs = all_obj_vecs(to_hm_indices, :);
num_objs = length(all_obj_names);

% Determine the pairs to use
pairs = get_pair_indices(which_pairs, num_objs);

for conti = 1 : num_continua
    continuum = continua_names{conti};
    fprintf('Learning about %s\n', continuum);
    xlswrite(results_file, headings, continuum);
    
    % Sort the objects in descending order of their ratings on this
    % continuum, and find their true ranks
    [sorted_obj_ratings, sort_order] = sort(all_obj_ratings_vecs(:, conti), 'descend');
    sorted_obj_names = all_obj_names(sort_order);
    sorted_obj_vecs = all_obj_vecs(sort_order, :);
    ranks = num_objs + 1 - tiedrank(sorted_obj_ratings); % in descending order of rating
    
    % Run RankSVM to get the weights
    [order_constraints, sim_constraints] = ranksvm_constraints(ranks, pairs, use_sim_constraints);
    num_order_cons = size(order_constraints, 1);
    num_sim_cons = size(sim_constraints, 1);
    order_penalties = zeros(num_order_cons, 1) + 0.1;
    sim_penalties = zeros(num_sim_cons, 1) + 0.1;
    weights = ranksvm_with_sim(sorted_obj_vecs, order_constraints, sim_constraints, order_penalties, sim_penalties);
        
    % Save the weights
    filename = sprintf('%s_%s_%s_pairs_sim%d', input, continuum, which_pairs, use_sim_constraints);
    save(sprintf('%s/%s.mat', weights_folder, filename), 'weights');
    
    % Calculate magnitudes
    sorted_obj_mags = zeros(num_objs, 1);
    for animi = 1 : num_objs
        sorted_obj_mags(animi) = sorted_obj_vecs(animi, :) * weights;
    end
    
    % Calculate correlations
    Pearsons_r = corr(sorted_obj_ratings, sorted_obj_mags, 'type', 'Pearson');
    Spearmans_rho = corr(sorted_obj_ratings, sorted_obj_mags, 'type', 'Spearman');
    corr_data = {'Correlations', 'Pearson', Pearsons_r;
                    '', 'Spearman', Spearmans_rho};
                
    % Re-sort results in descending order of predicted magnitude
    [resorted_obj_mags, sort_order] = sort(sorted_obj_mags, 'descend');
    resorted_obj_names = sorted_obj_names(sort_order);
    resorted_obj_ratings = sorted_obj_ratings(sort_order);
    
    % Write results to file
    xlswrite(results_file, [resorted_obj_names num2cell(resorted_obj_ratings) num2cell(resorted_obj_mags)], continuum, 'A2');
    xlswrite(results_file, corr_data, continuum, ['A' num2str(num_objs + 3)]);
    
    % Draw a scatterplot
%     figure;
%     scatter(sorted_obj_ratings, sorted_obj_mags);
%     xlabel('Human Magnitude Rating');
%     ylabel('Predicted Magnitude');
%     saveas(gcf, sprintf('%s/%s.fig', results_folder, filename));
end