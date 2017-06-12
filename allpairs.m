% Creates all pairs from a list of objects. Pairs are formed in ascending
% order and no object is paired with itself. The resulting matrix has
% n*(n-1)/2 rows and 2 columns; each row is a pair.
function [pairs] = allpairs(objs)
    % If objs is a row vector, convert it into a column vector
    if size(objs, 1) == 1
        objs = objs';
    end
    num_objs = length(objs);
    pairs = zeros(num_objs * (num_objs - 1) / 2, 2);
    start_row = 1;
    for i = 1 : num_objs - 1
        num_pairs = num_objs - i;
        end_row = start_row + num_pairs - 1;
        pairs(start_row : end_row, :) = [repmat(objs(i), num_pairs, 1), objs(i + 1 : end)];
        start_row = end_row + 1;
    end
end