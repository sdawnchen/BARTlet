% Returns a list of pairs (as an n-by-2 matrix of their indices) given the
% description string (which_pairs) and number of objects.
%
% The description string may have several parts, separated by "_". Note
% that if randomly chosen pairs are desired, this part (e.g., "rand100")
% should come last to ensure that the randomly chosen pairs don't overlap
% with the other pairs.

function [pairs] = get_pair_indices(which_pairs, num_objs)
parts = regexp(which_pairs, '_', 'split');
pairs = [];
for parti = 1 : length(parts)
    part = parts{parti};
    
    rand_pairs = regexp(part, '^rand(\d+)', 'tokens', 'once');
    chosen_items = regexp(part, '(?<level>top|bot|mid|eq)(?<num>\d+)', 'names');
    pairing = regexp(part, '(all|adj|vsall)$', 'tokens', 'once');
    
    if ~isempty(rand_pairs)
        % Randomly select pairs that don't overlap with the pairs already chosen (and their reverses)
        num_rand_pairs = str2double(rand_pairs{1});
        all_pairs = allpairs(1 : num_objs);
        if isempty(pairs)
            poss_pairs = all_pairs;
        else
            reverse_pairs = [pairs(:, 2) pairs(:, 1)];
            poss_pairs = setdiff(all_pairs, [pairs; reverse_pairs], 'rows');
        end
        num_poss_pairs = size(poss_pairs, 1);
        pairi = randsample(num_poss_pairs, num_rand_pairs);
        pairs = [pairs; poss_pairs(pairi, :)];
        
    elseif ~isempty(pairing)
        % Create a list of the main objects of interest
        if isempty(chosen_items)
            main_objs = 1 : num_objs;
        else
            main_objs = [];
            for choseni = 1 : length(chosen_items)
                level = chosen_items(choseni).level;
                num_chosen = str2double(chosen_items(choseni).num);
                if strcmp(level, 'top') % top objects
                    chosen = 1 : num_chosen;
                elseif strcmp(level, 'bot') % bottom objects
                    chosen = num_objs - num_chosen + 1 : num_objs;
                elseif strcmp(level, 'mid') % objects in the middle
                    num_other_objs = num_objs - num_chosen;
                    num_each_extreme = num_other_objs / 2;
                    if ceil(num_each_extreme) == num_each_extreme  % num_each_extreme is an integer
                        chosen = num_each_extreme + 1 : num_objs - num_each_extreme;
                    else
                        chosen = ceil(num_each_extreme) : num_objs - ceil(num_each_extreme);   % will have 1 more obj from top
                    end
                elseif strcmp(level, 'eq')  % choose objects that are about equally spaced apart
                    intervals = divide_evenly(num_objs, num_chosen - 1);
                    chosen = [1 cumsum(intervals)'];
                end
                main_objs = [main_objs; chosen'];
            end
        end
        
        % Form various pairs between the main/other objects
        pairing = pairing{1};
        if strcmp(pairing, 'all')   % all possible pairs
            pairs = [pairs; allpairs(main_objs)];
        elseif strcmp(pairing, 'adj')   % adjacent pairs
            obj1_inds = main_objs(1:end-1);
            obj2_inds = main_objs(2:end);
            pairs = [pairs; [obj1_inds obj2_inds]];
        elseif strcmp(pairing, 'vsall') % pairs formed between the main objects and all other objects
            other_objs = setdiff(1 : num_objs, main_objs);
            within_pairs = allpairs(main_objs);
            across_pairs = cartprod(main_objs, other_objs);
            pairs = [pairs; within_pairs; across_pairs];
        end
    end
end

% Make sure that no object is paired with itself and that each pair is in
% ascending order and appears only once in the list
pairs(pairs(:, 1) == pairs(:, 2), :) = [];
for pairi = 1 : size(pairs, 1)
    pairs(pairi, :) = sort(pairs(pairi, :));
end
pairs = unique(pairs, 'rows');
