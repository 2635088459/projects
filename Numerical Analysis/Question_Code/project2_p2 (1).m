function backward_difference_study()
    % Define the function and its exact derivative
    f = @(x) sin(x);
    df_exact = @(x) cos(x);

    % Choose a point to evaluate the derivative
    x0 = pi/4;

    % Define a range of step sizes
    h = logspace(-1, -10, 10);

    % Initialize arrays to store errors and ratios
    errors = zeros(size(h));
    ratios = zeros(size(h) - 1);

    % Compute errors for each step size
    for i = 1:length(h)
        df_approx = backward_difference(f, x0, h(i));
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
    loglog(h, h, 'r--', 'LineWidth', 2);
    xlabel('Step size (h)');
    ylabel('Error');
    title('Backward Difference Error vs. Step Size');
    legend('Backward Difference Error', 'O(h) Reference Line', 'Location', 'northwest');
    grid on;

    % Display the error ratios
    disp('Ratios of successive errors:');
    disp(ratios);

    % Compute and display the average ratio
    avg_ratio = mean(ratios);
    disp(['Average ratio: ', num2str(avg_ratio)]);
end

function df = backward_difference(f, x, h)
    df = (f(x) - f(x - h)) / h;
end