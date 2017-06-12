% Calculates magnitudes on all 4 continua for the 44 Leuven (or 77 topics)
% animals, using the "positive" one-place predicates (e.g., large).

tic;
clear all;

input = 'leuven';%'topics';%
which_pairs = 'top3bot3vsall_rand100';%'all';%'top3bot3vsall';%'top1bot1vsall';%'top5bot5vsall';%'rand100';%
use_sim_constraints = false;%true;%   % whether to use similarity constraints when running RankSVM
prior_variance = 1;

num_samples = 1000;
dataset = 'hm';

if strcmp(input, 'topics')
    corpus = '_wiki_';
    sample_str = 'concat213_30r0.8';
    load(sprintf('data_topics_sel_dims%s%s.mat', corpus, sample_str));
    num_dims = num_sel_dims;
    prior_scale = 10;
elseif strcmp(input, 'leuven')
    corpus = '';
    sample_str = '';
    prior_scale = 5;
end

highlow_matfolder = sprintf('results/%s/weights', input);

continua_names = {'size', 'fierceness', 'intelligence', 'speed'};
num_continua = 4;
headings = {'Animal', 'Rating', 'Mag mean', 'Mag var'};
results_folder = sprintf('results/%s/magnitudes', input);
if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end
results_file = sprintf('%s/%s_mag_%s_rankprior_%s_sim%d_var%g_scale%d.xlsx', results_folder, ...
    input, dataset, which_pairs, use_sim_constraints, prior_variance, prior_scale);

% For variational method
max_iter = 5000;                % maximum number of iterations
criterion = 0.00001;            % criterion for convergence

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load('data_animals_hm_ratings.mat');
all_obj_ratings_vecs = all_obj_vecs;
load(sprintf('data_animals_hm_%s%s%s_processed.mat', input, corpus, sample_str));
all_obj_vecs = all_obj_vecs(to_hm_indices, :);
if strcmp(dataset, 'leuven')
    load('data_animals_hm_leuven.mat', 'all_obj_names', 'all_hm_indices', 'to_hm_indices');
    all_obj_vecs = all_obj_vecs(all_hm_indices, :);
end
all_obj_ratings_vecs = all_obj_ratings_vecs(all_hm_indices(to_hm_indices), :);
all_obj_names = all_obj_names(to_hm_indices);
num_objs = length(all_obj_names);

% Go through all continua
for conti = 1 : num_continua
    continuum = continua_names{conti};
    xlswrite(results_file, headings, continuum, 'A1');
    row = 2;
    
    all_obj_ratings = all_obj_ratings_vecs(:, conti);
    
    % Get the 1-place predicate weights
    load(sprintf('%s/%s_%s_revdata0_rankprior_%s_sim%d_var%g_scale%d.mat', highlow_matfolder, ...
        input, continuum, which_pairs, use_sim_constraints, prior_variance, prior_scale));
    mag_weight_means = mu_high;
    mag_weight_cov = sigma_high;
    
    % Calculate the magnitude mean & variance
    animal_mag_means = zeros(num_objs, 1);
    animal_mag_vars = zeros(num_objs, 1);
    for animal = 1 : num_objs
        animal_vec = all_obj_vecs(animal, :);
        [mag_mean, mag_var] = wsum_mean_var(mag_weight_means, mag_weight_cov, animal_vec);
        animal_mag_means(animal) = mag_mean;
        animal_mag_vars(animal) = mag_var;
    end
    
    % Calculate correlations between ratings and magnitude means
    Pearsons_r = corr(all_obj_ratings, animal_mag_means, 'type', 'Pearson');
    Spearmans_rho = corr(all_obj_ratings, animal_mag_means, 'type', 'Spearman');
    corr_data = {'Correlations', 'Pearson', Pearsons_r;
        '', 'Spearman', Spearmans_rho};
    
    % Sort all results in descending order of predicted magnitude
    % mean
    [animal_mag_means, sort_order] = sort(animal_mag_means, 'descend');
    sorted_obj_names = all_obj_names(sort_order);
    sorted_obj_ratings = all_obj_ratings(sort_order);
    animal_mag_vars = animal_mag_vars(sort_order);
    
    % Write the results to file
    xlswrite(results_file, sorted_obj_names, continuum, sprintf('A%d', row));
    xlswrite(results_file, [sorted_obj_ratings animal_mag_means animal_mag_vars], continuum, sprintf('B%d', row));
    xlswrite(results_file, corr_data, continuum, ['A' num2str(num_objs + 3)]);
    row = row + num_objs;
end

toc;
