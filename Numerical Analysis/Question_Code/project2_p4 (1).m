function simpsons_rule_study()
    % Define the function to integrate and its exact integral
    f = @(x) exp(x);
    exact_integral = exp(1) - 1;  % Integral of exp(x) from 0 to 1

    % Define the integration limits
    a = 0;
    b = 1;

    % Define a range of subinterval counts (must be even)
    n_values = 2.^(2:12);

    % Initialize arrays to store errors and ratios
    errors = zeros(size(n_values));
    ratios = zeros(size(n_values) - 1);

    % Compute errors for each number of subintervals
    for i = 1:length(n_values)
        approx_integral = simpsons_rule(f, a, b, n_values(i));
        errors(i) = abs(approx_integral - exact_integral);
    end

    % Compute ratios of successive errors
    for i = 1:length(n_values)-1
        ratios(i) = errors(i) / errors(i+1);
    end

    % Compute step sizes
    h_values = (b - a) ./ n_values;

    % Plot the results
    figure;
    loglog(h_values, errors, 'b-o', 'LineWidth', 2);
    hold on;
    loglog(h_values, h_values.^4, 'r--', 'LineWidth', 2);
    xlabel('Step size (h)');
    ylabel('Error');
    title("Simpson's Rule Error vs. Step Size");
    legend("Simpson's Rule Error", 'O(h^4) Reference Line', 'Location', 'northwest');
    grid on;

    % Display the error ratios
    disp('Ratios of successive errors:');
    disp(ratios);

    % Compute and display the average ratio
    avg_ratio = mean(ratios);
    disp(['Average ratio: ', num2str(avg_ratio)]);
    
    % Compute and display the order of convergence
    order = log(errors(end-1) / errors(end)) / log(h_values(end-1) / h_values(end));
    disp(['Estimated order of convergence: ', num2str(order)]);
end

function I = simpsons_rule(f, a, b, n)
    if mod(n, 2) ~= 0
        error('n must be even for Simpson''s rule');
    end
    
    h = (b - a) / n;
    x = a:h:b;
    y = f(x);
    
    I = h/3 * (y(1) + 4*sum(y(2:2:end-1)) + 2*sum(y(3:2:end-2)) + y(end));
end