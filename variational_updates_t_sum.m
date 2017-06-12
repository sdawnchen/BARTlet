function [mu_post, sigma_post_inv, xi] = ...
    variational_updates_t_sum(data, label, mu_prior, sigma_prior_inv, max_iterations, criterion)

% use  eqs from Jaakkola & Jordan
xi = 0.1;  % in bayes_logit_fit_iter, this seems to start at 0
sigma_prior_inv_prior = sigma_prior_inv;

L_last=-Inf;

% mu_lengths = nan(max_iterations, 1);

for iter = 1:max_iterations
    % perform updates to sigma_post_inv, mu_post, xi
   
%     sigma_post_inv = sigma_prior_inv_prior + 2 * lambda_xi.* (data * data');
    if iter>1
         lambda_xi = tanh(xi_n/2)./(4 * xi_n);
         term1 = data .* kron(lambda_xi,ones(size(data,1),1));
    else
        lambda_xi = tanh(xi/2)./(4 * xi);
        term1 = data * lambda_xi;
    end;
    sigma_post_inv = sigma_prior_inv_prior + 2 * term1* data';

    sigma_post = inv(sigma_post_inv);
    mu_post = sigma_post * (sigma_prior_inv_prior * mu_prior + data*label/2 );
%    xi = sqrt(data' * sigma_post * data + (data' * mu_post)^2); 

%     for datai = 1:size(data,2)
%         xi_n(datai) = sqrt(data(:,datai)' * sigma_post * data(:,datai) + (data(:,datai)' * mu_post)^2); 
%     end;

    xi_n = ((diag(data'*sigma_post*data) + (data'*mu_post).^2).^0.5)';
    
    mu_lengths(iter) = norm(mu_post);

%    L = (log_prediction(xi, mu_prior, sigma_prior_inv_prior, mu_post, sigma_post_inv));
%     L = 0;     
%     iter = iter + 1;
    
      % no stopping cretirion here! should work on this later. NOw just use
      % the maximum interations. Should update the calculation for L
%     if (L_last > L ) %%&& abs(L_last - L)>0.01*abs(L) 
%         fprintf('warning: Variational bound should not reduce, iter =  %d, Last bound %6.6f, current bound %6.6f\n',iter, L_last, L);
% %         break;
%     end
%     
%     if (abs(L_last - L) < abs(criterion * L))
%         break;
%     end
%     L_last = L;
%     Ldata(iter) = L; 
end
% fprintf('final iter: %d\n', iter);

if iter == max_iterations
    warning('Bayes:maxIter', ...
        'Computing predictive probability reached maximum number of iterations.');
end
% 
% figure;
% plot(mu_lengths(1:500));
% xlabel('Number of iterations');
% ylabel('Length of mean weight vector');

% xi
% pause;

% use silva's eqs
% while iter <= max_iterations && xi_diff >= criterion
%     % perform updates to sigma_post_inv, mu_post, xi
%     lambda_xi = tanh(xi/2)/(4 * xi);
%     sigma_post_inv = sigma_prior_inv + 2 * lambda_xi * data * data';
%     sigma_post = inv(sigma_post_inv);
%     mu_post = sigma_post * (sigma_prior_inv * mu_prior + (linked - 0.5) * data);
%     xi_old = xi;
%     xi = sqrt(data' * sigma_post * data + (data' * mu_post)^2);
%     xi_diff = abs(xi - xi_old);
%     iter = iter + 1;
% end
