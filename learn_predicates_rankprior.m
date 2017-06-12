% Learns all 4 "positive" one-place predicates (e.g., large) using the
% specified RankSVM prior.

tic;
clear all;

input = 'leuven';%'topics';%
which_pairs = 'top3bot3vsall_rand100';%'all';%'top5bot5vsall';%'top3bot3vsall';%'top1bot1vsall';%'rand100';%
use_sim_constraints = false;%true;%   % whether to use similarity constraints when running RankSVM
prior_variance = 1;

continua_names = {'size', 'fierceness', 'intelligence', 'speed'};
num_continua = length(continua_names);

num_train_pos_vec = 20;
num_train_opp_vec = num_train_pos_vec;

if strcmp(input, 'topics')
    corpus = '_wiki_';
    sample_str = 'concat213_30r0.8';
    prior_scale = 10;
else
    corpus = '';
    sample_str = '';
    prior_scale = 5;
end
scale_factor = 100;

ranksvm_folder = sprintf('results/%s/weights/ranksvm', input);
weights_folder = sprintf('results/%s/weights', input);
if ~exist(weights_folder, 'dir')
    mkdir(weights_folder);
end

% For variational method
max_iter = 5000;                % maximum number of iterations
criterion = 0.00001;            % criterion for convergence

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load(sprintf('data_animals_hm_%s%s%s_processed.mat', input, corpus, sample_str));

for conti = 1 : num_continua
    continuum = continua_names{conti};
    fprintf('Learning about %s\n', continuum);
    
    load(sprintf('data_animals_%s_ratings.mat', continuum));
    num_high_objs = length(high_obj_names);
    num_low_objs = length(low_obj_names);
    num_med_objs = length(med_obj_names);
    
    % Get training data
    if strcmp(input, 'leuven')
        % The Leuven high/low/med objects are not subsets of the larger
        % set of objects, so must process their vectors separately
        inputfile = sprintf('data_animals_%s_leuven_processed.mat', continuum);
        if exist(inputfile, 'file')
            load(inputfile)
        else
            load(sprintf('data_animals_%s_leuven.mat', continuum));
            
            % Remove the non-selected features
            load(sprintf('data_%s_sel_dims.mat', input));
            high_obj_vecs = high_obj_vecs(:, sel_dims);
            low_obj_vecs = low_obj_vecs(:, sel_dims);
            med_obj_vecs = med_obj_vecs(:, sel_dims);
            
            % Center each selected dimension if desired
            load(sprintf('data_%s_dim_means.mat', input));
            dim_means = dim_means(sel_dims);
            high_obj_vecs = high_obj_vecs - repmat(dim_means, num_high_objs, 1);
            low_obj_vecs = low_obj_vecs - repmat(dim_means, num_low_objs, 1);
            med_obj_vecs = med_obj_vecs - repmat(dim_means, num_med_objs, 1);
            
            % Scale all features
            high_obj_vecs = high_obj_vecs * scale_factor;
            low_obj_vecs = low_obj_vecs * scale_factor;
            med_obj_vecs = med_obj_vecs * scale_factor;
            save(inputfile, 'high_obj_names', 'high_obj_vecs', ...
                'low_obj_names', 'low_obj_vecs', 'med_obj_names', ...
                'med_obj_vecs');
        end
    else
        % For other inputs, the high/low/med objects are subsets of the
        % entire set of objects, so just take their processed vectors
        [junk, indices] = ismember(high_obj_names, all_obj_names);
        high_obj_vecs = all_obj_vecs(indices, :);
        [junk, indices] = ismember(low_obj_names, all_obj_names);
        low_obj_vecs = all_obj_vecs(indices, :);
        [junk, indices] = ismember(med_obj_names, all_obj_names);
        med_obj_vecs = all_obj_vecs(indices, :);
    end
    
    % Load weights learned by RankSVM as the prior mean
    load(sprintf('%s/%s_%s_%s_pairs_sim%d', ranksvm_folder, input, continuum, which_pairs, use_sim_constraints));
    mu_prior_pred = weights * prior_scale;
    sigma_prior_pred = eye(length(weights)) * prior_variance;
    
    % Learn weights for HIGH
    for traini = 1 : length(num_train_pos_vec)
        num_train_pos = num_train_pos_vec(traini);
        num_train_opp = num_train_opp_vec(traini);
        train_pos_vecs = high_obj_vecs(randsample(num_high_objs, num_train_pos), :);
        train_opp_vecs = low_obj_vecs(randsample(num_low_objs, num_train_opp), :);
    
        traindata = [train_pos_vecs; train_opp_vecs];
        trainlabels = [ones(num_train_pos, 1); -ones(num_train_opp, 1)];
        [mu_high, sigma_high, sigma_inv_high] = train_batch(traindata, ...
            trainlabels, mu_prior_pred, sigma_prior_pred, max_iter, criterion);
        mu_lengths(traini) = norm(mu_high);
    end

    % Learn weights for LOW
    [mu_low, sigma_low, sigma_inv_low] = ...
        train_batch(traindata, -trainlabels, -mu_prior_pred, sigma_prior_pred, max_iter, criterion);
    
    save(sprintf('%s/%s_%s_revdata0_rankprior_%s_sim%d_var%g_scale%d.mat', weights_folder, input, continuum, ...
        which_pairs, use_sim_constraints, prior_variance, prior_scale), ...
        'mu_high', 'mu_low', 'sigma_high', 'sigma_low', 'sigma_inv_high', 'sigma_inv_low');
end
toc;