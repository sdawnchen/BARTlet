% Calculates Cartesian product of two sets.
function [product] = cartprod(set1, set2)
    set1len = length(set1);
    set2len = length(set2);
    product = zeros(set1len * set2len, 2);
    start_row = 1;
    for i = 1:set1len
        end_row = start_row + set2len - 1;
        product(start_row : end_row, :) = [repmat(set1(i), set2len, 1), set2(:)];
        start_row = end_row + 1;
    end
end