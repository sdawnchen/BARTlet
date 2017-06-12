fprintf('Testing pairs from group %d\n', group);
num_pairs = size(pairs, 1);

sum_d_a = 0;

sum_obj1_mag_mean = 0;
sum_obj2_mag_mean = 0;
sum_obj1_mag_var = 0;
sum_obj2_mag_var = 0;

all_obj1_mag_means = zeros(num_pairs, 1);
all_obj2_mag_means = zeros(num_pairs, 1);

for pair = 1 : num_pairs
    obj1_vec = all_obj_vecs(pairs(pair, 1), :);
    obj2_vec = all_obj_vecs(pairs(pair, 2), :);
    
    [obj1_mag_mean, obj1_mag_var] = wsum_mean_var(mag_weight_means, mag_weight_cov, obj1_vec);
    [obj2_mag_mean, obj2_mag_var] = wsum_mean_var(mag_weight_means, mag_weight_cov, obj2_vec);
    
    % Scale magnitude variances based on distances from the reference
    % point's magnitude
    range = abs(ref_mag_mean - other_ref_mag_mean);
    ref_dist1 = abs(ref_mag_mean - obj1_mag_mean) / range;
    ref_dist2 = abs(ref_mag_mean - obj2_mag_mean) / range;
    
    if higher
        var_scale1 = a * exp(b_higher * ref_dist1);
        var_scale2 = a * exp(b_higher * ref_dist2);
    else
        var_scale1 = a * exp(b_lower * ref_dist1);
        var_scale2 = a * exp(b_lower * ref_dist2);
    end
    
    obj1_mag_var_scaled = obj1_mag_var * var_scale1;
    obj2_mag_var_scaled = obj2_mag_var * var_scale2;
    
    % Calculate d_a
    mag_diff_mean = obj1_mag_mean - obj2_mag_mean;
    d_a = mag_diff_mean / sqrt((obj1_mag_var_scaled + obj2_mag_var_scaled) / 2);
    
    %     fprintf('Animal 1 (%s) magnitude feature mean = %f, unscaled variance = %f, scaled variance = %f\n', ...
    %         all_obj_names{pairs(pair, 1)}, obj1_mag_mean, obj1_mag_var, obj1_mag_var_scaled);
    %     fprintf('Animal 2 (%s) magnitude feature mean = %f, unscaled variance = %f, scaled variance = %f\n', ...
    %         all_obj_names{pairs(pair, 2)}, obj2_mag_mean, obj2_mag_var, obj2_mag_var_scaled);
    %     fprintf('d_a: %f\n\n', d_a);
    
    sum_d_a = sum_d_a + d_a;
    sum_obj1_mag_mean = sum_obj1_mag_mean + obj1_mag_mean;
    sum_obj2_mag_mean = sum_obj2_mag_mean + obj2_mag_mean;
    sum_obj1_mag_var = sum_obj1_mag_var + obj1_mag_var_scaled;
    sum_obj2_mag_var = sum_obj2_mag_var + obj2_mag_var_scaled;
    
    all_obj1_mag_means(pair) = obj1_mag_mean;
    all_obj2_mag_means(pair) = obj2_mag_mean;
end

avg_d_a = sum_d_a / num_pairs;
avg_obj1_mag_mean = sum_obj1_mag_mean / num_pairs;
avg_obj2_mag_mean = sum_obj2_mag_mean / num_pairs;
avg_obj1_mag_var = sum_obj1_mag_var / num_pairs;
avg_obj2_mag_var = sum_obj2_mag_var / num_pairs;
