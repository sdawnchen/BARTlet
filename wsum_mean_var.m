% Calculates the mean and variance of the weighted sum of correlated random
% variables, given their means and covariance matrix.
function [new_mean, new_var] = wsum_mean_var(means, cov, weights)
    dim = length(weights);
    new_mean = reshape(weights, 1, dim) * reshape(means, dim, 1);
    
    temp_cov = zeros(dim, dim);
    for row = 1:dim
        temp_cov(row, :) = reshape(weights, 1, dim) .* cov(row, :);
    end
    for col = 1:dim
        temp_cov(:, col) = reshape(weights, dim, 1) .* temp_cov(:, col);
    end
    new_var = sum(sum(temp_cov));
end