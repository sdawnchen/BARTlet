all_d_as = zeros(num_test_pairs, 1);
all_dists = zeros(num_test_pairs, 1);

for pair = 1 : num_test_pairs
    obj1_vec = sorted_obj_vecs(test_pairs(pair, 1), :);
    obj2_vec = sorted_obj_vecs(test_pairs(pair, 2), :);
    
    [obj1_mag_mean, obj1_mag_var] = wsum_mean_var(mag_weight_means, mag_weight_cov, obj1_vec);
    [obj2_mag_mean, obj2_mag_var] = wsum_mean_var(mag_weight_means, mag_weight_cov, obj2_vec);
    
    ref_dist1 = abs(ref_mag_mean - obj1_mag_mean) / ref_range;
    ref_dist2 = abs(ref_mag_mean - obj2_mag_mean) / ref_range;
    
    var_scale1 = a * exp(b * ref_dist1);
    var_scale2 = a * exp(b * ref_dist2);
    
    obj1_mag_var_scaled = obj1_mag_var * var_scale1;
    obj2_mag_var_scaled = obj2_mag_var * var_scale2;
    
    % Calculate d_a
    mag_diff_mean = obj1_mag_mean - obj2_mag_mean;
    d_a = mag_diff_mean / sqrt((obj1_mag_var_scaled + obj2_mag_var_scaled) / 2);
    all_d_as(pair) = d_a;
    
    dist = abs(sorted_obj_ratings_vecs(test_pairs(pair, 1), conti) - ...
        sorted_obj_ratings_vecs(test_pairs(pair, 2), conti));
    all_dists(pair) = dist;
end

avg_d_as = zeros(num_bins, 1);
num_pairs_each_bin = zeros(num_bins, 1);
for bin = 1 : num_bins
    if bin < num_bins
        indices = and(all_dists >= dist_bins(bin), all_dists < dist_bins(bin + 1));
    else
        indices = and(all_dists >= dist_bins(bin), all_dists <= dist_bins(bin + 1));
    end
    avg_d_as(bin) = mean(all_d_as(indices));
    num_pairs_each_bin(bin) = sum(indices);
end