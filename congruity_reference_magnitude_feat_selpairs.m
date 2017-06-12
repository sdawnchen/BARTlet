% Tests the congruity effect. Uses all 4 levels of size (full range) when levels is set
% to '' and only the middle 2 levels of size (restricted range) when levels
% is set to '_middle2'.

tic;
clear all;

input = 'leuven';%'topics';%
levels = '';%'_middle2';%   % '': all levels (and all 4 continua), '_middle2': middle 2 levels for size

% For RankSVM prior
which_pairs = 'top3bot3vsall_rand100';%'all';%'top3bot3vsall';%'top5bot5vsall';%'rand100';%
use_sim_constraints = false;%true;%   % whether to use similarity constraints when running RankSVM
prior_variance = 1;

% Parameters for the exponential function that scales the variance of the
% magnitude feature based on distance from the reference point's magnitude
a = 0.1;        % Scaling factor when on top of reference point
b_higher = 4.6; % "Slope" of the exponential--unmarked relation should have gentler slope
b_lower = 5.3;	% Marked relation should have steeper slope

if strcmp(input, 'topics')
    corpus = '_wiki_';
    corpus_folder = ['/' strtrim(regexprep(corpus, '_', ' '))];
    sample_str = 'concat213_30r0.8';
    samples_folder = '/concat chains';
    load(sprintf('data_topics_sel_dims%s%s.mat', corpus, sample_str));
    num_dims = num_sel_dims;
    prior_scale = 10;
elseif strcmp(input, 'leuven')
    corpus = '';
    corpus_folder = '';
    sample_str = '';
    samples_folder = '';
    prior_scale = 5;
end
num_train_pos = 20;
num_train_opp = 20;

highlow_matfolder = sprintf('results/%s/weights', input);

continua_names = {'size', 'fierceness', 'intelligence', 'speed'};
if strcmp(levels, '')
    num_continua = 4;
else
    num_continua = 1;
end
headings = {'Pair group', 'Avg d_a', 'Avg obj1 mag mean', 'Avg obj2 mag mean', 'Avg obj1 mag var', 'Avg obj2 mag var'};

results_folder = sprintf('results/%s/congruity', input);
if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end
results_file = sprintf('%s/%s_cong%s_a%g_b%g_%3.1f_%s_x%d.xls', ...
    results_folder, input, levels, a, b_higher, b_lower, which_pairs, prior_scale);

% For variational method
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
    
    % Get test pairs
    load(sprintf('data_congruity_%s_selpairs_%s%s.mat', input, continuum, levels));
    num_pair_groups = length(congruity_pairnames);
    
    test_pairs = cell(num_pair_groups, 1);
    test_animals = [];
    num_pairs_each_group = zeros(num_pair_groups, 1);
    avg_dists = zeros(num_pair_groups, 1);
    
    for group = 1 : num_pair_groups
        pairs = find_str_indices(congruity_pairnames{group}, all_obj_names);
        num_pairs_each_group(group) = size(pairs, 1);
        avg_dists(group) = sum(abs(all_obj_ratings_vecs(pairs(:, 1), conti) - ...
            all_obj_ratings_vecs(pairs(:, 2), conti))) / size(pairs, 1);
        test_pairs{group} = pairs;
        test_animals = [test_animals; pairs(:)];
    end
    
    % Find the unique set of test animals
    test_animals = unique(test_animals);
    num_test_animals = length(test_animals);
    
    % Go through both the higher and lower relations
    for higher = [1 0]
        relation = get_relation_name(conti, higher);
        fprintf('Testing %s\n', relation);

        xlswrite(results_file, headings, relation, 'A1');
        row = 2;
        
        % Get 1-place predicate weights
        load(sprintf('%s/%s_%s_revdata%d_rankprior_%s_sim%d_var%g_scale%d.mat', highlow_matfolder, ...
            input, continuum, 0, which_pairs, use_sim_constraints, prior_variance, prior_scale));
        
        mag_weight_means = mu_high;
        mag_weight_cov = sigma_high;
        
        % Find the reference point
        % Calculate the mean magnitude for all test animals
        test_animal_mags = zeros(num_test_animals, 1);
        for animal = 1 : num_test_animals
            animal_vec = all_obj_vecs(test_animals(animal), :);
            test_animal_mags(animal) = animal_vec * mag_weight_means;
        end
        
        % Take the animal with the highest/lowest mean magnitude
        % to be the reference point
        if higher
            [ref_mag_mean, index] = max(test_animal_mags);
            [other_ref_mag_mean, other] = min(test_animal_mags);
        else
            [ref_mag_mean, index] = min(test_animal_mags);
            [other_ref_mag_mean, other] = max(test_animal_mags);
        end
        ref_animal_name = all_obj_names{test_animals(index)};
        other_ref_animal_name = all_obj_names{test_animals(other)};
        
        % Evaluate performance on the pairs within each group pair and
        % record them
        for group = 1 : num_pair_groups
            pairs = test_pairs{group};
            evaluate_congruity_magnitude_feat_selpairs;
            xlswrite(results_file, [group avg_d_a avg_obj1_mag_mean avg_obj2_mag_mean avg_obj1_mag_var ...
                avg_obj2_mag_var], relation, sprintf('A%d', row));
            row = row + 1;
        end
    end
end

toc;
