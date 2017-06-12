% Tests the distance effect.

tic;
clear all;

input = 'leuven';%'topics';%
which_pairs = 'top3bot3vsall_rand100';%'all';%'top3bot3vsall';%'top5bot5vsall';%'rand100';%
use_sim_constraints = false;%true;%   % whether to use similarity constraints when running RankSVM
prior_variance = 1;

higher = 1;

a = 0.1;
if higher
    b = 4.6;
else
    b = 5.3;
end

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
min_feat_diff = 0.5; % minimum difference between two animals on the feature of interest for the pair to be used in training or test
headings = {'Distance', '# pairs', 'Avg d_a'};
results_folder = sprintf('results/%s/distance', input);
if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end
results_file = sprintf('%s/%s_dist_a%g_b%g_higher%d_%s_x%d.xls', ...
    results_folder, input, a, b, higher, which_pairs, prior_scale);

if strcmp(input, 'leuven')  % make 4 dist bins for Leuven
    dist_bins = [0.5; 1.5; 3; 5.5; 10];
    dist_bins_str = {'0.5 to 1.5'; '1.5 to 3'; '3 to 5.5'; '5.5 to 10'};
else
    dist_bins = [0.5; 2; 4; 6; 8; 10];
    dist_bins_str = {'0.5 to 2'; '2 to 4'; '4 to 6'; '6 to 8'; '8 to 10'};
end
num_bins = length(dist_bins) - 1;


% For variational method
a0 = 5;
b0 = 1;
max_iter = 5000;                % maximum number of iterations
criterion = 0.00001;            % criterion for convergence

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load('data_animals_hm_ratings_processed.mat');
all_obj_ratings_vecs = all_obj_vecs;
load(sprintf('data_animals_hm_%s%s%s_processed.mat', input, corpus, sample_str));
all_obj_ratings_vecs = all_obj_ratings_vecs(all_hm_indices(to_hm_indices), :);
num_objs = length(all_obj_names);

fprintf('Input is %s\n', input);

% Go through all continua
for conti = 1 : num_continua
    continuum = continua_names{conti};
    fprintf('Testing %s\n', continuum);
    xlswrite(results_file, headings, continuum, 'A1');
    row = 2;
    
    % Sort the animals based on the tested relation such that the
    % higher relation holds between successive pairs of animals when going
    % down the list
    [sorted, sort_order] = sort(all_obj_ratings_vecs(:, conti), 'descend');
    sorted_obj_ratings_vecs = all_obj_ratings_vecs(sort_order, :);
    sorted_obj_names = all_obj_names(sort_order);
    sorted_obj_vecs = all_obj_vecs(sort_order, :);
    
    % Create the positive test pairs, removing all pairs that do
    % not satisfy the minimum difference criterion.
    test_pairs = allpairs(1 : num_objs);
    test_pairs(abs(sorted_obj_ratings_vecs(test_pairs(:, 1), conti) - ...
        sorted_obj_ratings_vecs(test_pairs(:, 2), conti)) < min_feat_diff, :) = [];
    num_test_pairs = size(test_pairs, 1);
    
    % Get 1-place predicate weights
    load(sprintf('%s/%s_%s_revdata0_rankprior_%s_sim%d_var%g_scale%d.mat', highlow_matfolder, ...
        input, continuum, which_pairs, use_sim_constraints, prior_variance, prior_scale));
    mag_weight_means = mu_high;
    mag_weight_cov = sigma_high;
    
    % Find the reference point
    % Calculate the mean magnitude for all test animals
    all_animal_mags = zeros(num_objs, 1);
    for animal = 1 : num_objs
        animal_vec = sorted_obj_vecs(animal, :);
        all_animal_mags(animal) = animal_vec * mag_weight_means;
    end
    
    % Take the animal with the highest mean magnitude
    % to be the reference point, and the animal with the lowest mean
    % magnitude to be the other reference point
    if higher
        [ref_mag_mean, index] = max(all_animal_mags);
        [other_ref_mag_mean, other] = min(all_animal_mags);
    else
        [ref_mag_mean, index] = min(all_animal_mags);
        [other_ref_mag_mean, other] = max(all_animal_mags);
    end
    ref_range = abs(ref_mag_mean - other_ref_mag_mean);
    
    ref_animal_name = sorted_obj_names{index};
    other_ref_animal_name = sorted_obj_names{other};
    
    % Evaluate performance
    evaluate_distbins_magnitude_feat;
    xlswrite(results_file, dist_bins_str, continuum, sprintf('A%d', row));
    xlswrite(results_file, [num_pairs_each_bin avg_d_as], continuum, sprintf('B%d', row));
    row = row + num_bins;
end

toc;
