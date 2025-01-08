function central_difference_study()
    % Define the function and its exact derivative
    f = @(x) sin(x);
    df_exact = @(x) cos(x);

    % Choose a point to evaluate the derivative
    x0 = pi/4;

    % Define a range of step sizes
    h = logspace(-1, -8, 15);

    % Initialize arrays to store errors and ratios
    errors = zeros(size(h));
    ratios = zeros(size(h) - 1);

    % Compute errors for each step size
    for i = 1:length(h)
        df_approx = central_difference(f, x0, h(i));
        errors(i) = abs(df_approx - df_exact(x0));
    end

    % Compute ratios of successive errors
    for i = 1:length(h)-1
        ratios(i) = errors(i) / errors(i+1);
    end

    % Plot the results
    figure;
    loglog(h, errors, 'b-o', 'LineWidth', 2);
    hold on;
    loglog(h, h.^2, 'r--', 'LineWidth', 2);
    xlabel('Step size (h)');
    ylabel('Error');
    title('Central Difference Error vs. Step Size');
    legend('Central Difference Error', 'O(h^2) Reference Line', 'Location', 'northwest');
    grid on;

    % Display the error ratios
    disp('Ratios of successive errors:');
    disp(ratios);

    % Compute and display the average ratio
    avg_ratio = mean(ratios);
    disp(['Average ratio: ', num2str(avg_ratio)]);
    
    % Compute and display the order of convergence
    order = log(errors(end-1) / errors(end)) / log(h(end-1) / h(end));
    disp(['Estimated order of convergence: ', num2str(order)]);
end

function df = central_difference(f, x, h)
    df = (f(x + h) - f(x - h)) / (2 * h);
end