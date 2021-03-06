function [intervals, beta] = piecewise_linearreg(points, lambda)
% PIECEWISE_LINEARREG Finds the set of line segments that most closely fit
% the given points with regularization parameter lambda.
%
%   NOTE: For best results, pick lambda around 0.01.
    n = size(points, 1);

    % Sort (x, y) pairs in ascending order by x coordinate
    points_sorted = sortrows(points);
    
    % X matrix and y vector
    X = [ones(n, 1) points_sorted(:, 1)];
    y = points_sorted(:, 2);
    
    % Matrix of parameter estimates
    Beta = zeros(n, n, 2);
    
    % Need the sum of squared errors
    error = zeros(n);

    
    % Calculate linear regression parameters and errors for each data interval
    for i = 1:(n - 1)
        for j = (i + 1):n
            % Do the slice
            X_slice = X(i:j, :);
            % Cache the transpose since we'll use it twice
            X_slice_t = X_slice';
            % Slice y
            y_slice = y(i:j);
            
            % Calculate the parameters
            Beta(i, j, :) = pinv(X_slice_t*X_slice) * X_slice_t * y_slice;
            
            % Calculate the error
            errors = y_slice - X_slice * reshape(Beta(i, j, :), 2, 1);
            error(i, j) = dot(errors, errors) / (j - i);
        end
    end
        
    % Store the total (not marginal) cost for each step
    % Initialize each element at infinity so the reigning champion
    % algorithm will work
    cost = Inf(n, 1);
    cost(1) = lambda;
    cost(2) = lambda;
    
    % The subsolution i to use for each solution k
    prev = ones(n, 1);
    
    % Calculate the cost and last segment endpoint for each subsolution
    for k = 3:n
        % Do i = 1 outside the loop because it breaks indexing into cost
        cost(k) = error(1, k) + lambda;
        for i = 2:k
            % Reigning champion algorithm for min and argmin
            new_cost = error(i, k) + lambda + cost(i - 1);
            if new_cost < cost(k)
                cost(k) = new_cost;
                prev(k) = i;
            end
        end
    end
    
    % Generate the output
    intervals = zeros(n, 2);
    beta = zeros(n, 2);
    
    % k is the index we're looking at, going backwards from n
    % m is the output size
    k = n;
    m = 0;
    while k > 1
        m = m + 1;
        beta(m, :) = Beta(prev(k), k, :);
        intervals(m, :) = [X(prev(k), 2) X(k, 2)];
        k = prev(k) - 1;
    end
    
    % Only return as many rows as necessary, and reverse the order so they
    % go from lowest to highest x
    intervals = intervals(m:-1:1, :);
    beta = beta(m:-1:1, :);
end