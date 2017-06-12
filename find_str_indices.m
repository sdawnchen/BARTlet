% Searches the dictionary for each string in words_cell2D (an at most
% 2-dimensional cell array) and returns the indices of the strings within
% the dictionary. The resulting indices matrix is the same size as
% words_cell2D if all the strings were found. If any string was not found,
% that entire row is deleted. (This is useful when words_cell2D contains
% pairs of animals; if one animal in a pair is invalid, the entire pair is
% invalid.)

function [indices] = find_str_indices(words_cell2D, dictionary)
    indices = zeros(size(words_cell2D));
    rows_to_remove = [];
    for col = 1 : size(words_cell2D, 2)
        for row = 1 : size(words_cell2D, 1)
            index = find(strcmp(words_cell2D{row, col}, dictionary));
            if isempty(index)
                indices(row, col) = NaN;
                fprintf('Could not find %s!\n', words_cell2D{row, col});
                if ~any(rows_to_remove == row)
                    rows_to_remove = [rows_to_remove; row];
                end
            else
                indices(row, col) = index;
            end
        end
    end
    indices(rows_to_remove, :) = [];
end