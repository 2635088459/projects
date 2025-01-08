function least_squares_tan_x()
    % Define the function
    u = @(x) tan(x);
    
    % Define the domain
    domain = [-pi/2, pi/2];
    
    % Define the degrees for approximation
    degrees = [2, 4, 6, 8];
    
    % Plot the function and its approximations
    plot_approximations(u, 'u(x) = tan(x)', domain, degrees);
    
    % Compute and display error metrics
    compute_error_metrics(u, domain, degrees);
end

function plot_approximations(f, f_name, domain, degrees)
    figure('Name', f_name, 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);
    
    % Exclude the endpoints to avoid infinite values
    x = linspace(domain(1) + 0.01, domain(2) - 0.01, 1000);
    y = f(x);
    
    % Plot original function
    subplot(2, 1, 1);
    plot(x, y, 'k-', 'LineWidth', 2);
    hold on;
    title([f_name, ' - Polynomial Approximations']);
    ylim([-10, 10]);  % Limit y-axis for better visibility
    
    % Compute and plot polynomial approximations
    for n = degrees
        coeffs = least_squares_polynomial(f, domain(1), domain(2), n);
        y_approx = polyval(flip(coeffs), x);
        plot(x, y_approx, 'LineWidth', 1.5);
    end
    
    legend(['Original', arrayfun(@(n) ['n = ', num2str(n)], degrees, 'UniformOutput', false)]);
    hold off;
    
    % Plot original function
    subplot(2, 1, 2);
    plot(x, y, 'k-', 'LineWidth', 2);
    hold on;
    title([f_name, ' - Trigonometric Approximations']);
    ylim([-10, 10]);  % Limit y-axis for better visibility
    
    % Compute and plot trigonometric approximations
    for n = degrees
        coeffs = least_squares_trig(f, domain(1), domain(2), n);
        y_approx = trig_approx(coeffs, x, domain(1), domain(2));
        plot(x, y_approx, 'LineWidth', 1.5);
    end
    
    legend(['Original', arrayfun(@(n) ['n = ', num2str(n)], degrees, 'UniformOutput', false)]);
    hold off;
end

function coeffs = least_squares_polynomial(f, a, b, n)
    % Create the matrix A and vector b
    A = zeros(n+1, n+1);
    b = zeros(n+1, 1);
    
    for i = 1:n+1
        for j = 1:n+1
            A(i,j) = integral(@(x) x.^(i+j-2), a, b);
        end
        b(i) = integral(@(x) f(x) .* x.^(i-1), a, b, 'ArrayValued', true);
    end
    
    % Solve the system Ax = b
    coeffs = A \ b;
end

function coeffs = least_squares_trig(f, a, b, n)
    % Create the matrix A and vector b
    A = zeros(2*n+1, 2*n+1);
    b = zeros(2*n+1, 1);
    
    L = (b - a) / 2;
    c = (a + b) / 2;
    
    for i = 1:2*n+1
        for j = 1:2*n+1
            if i == 1 && j == 1
                A(i,j) = 2*L;
            elseif i <= n+1 && j <= n+1
                A(i,j) = integral(@(x) cos((i-1)*pi*x/L) .* cos((j-1)*pi*x/L), -L, L);
            elseif i <= n+1 && j > n+1
                A(i,j) = integral(@(x) cos((i-1)*pi*x/L) .* sin((j-n-1)*pi*x/L), -L, L);
            elseif i > n+1 && j <= n+1
                A(i,j) = integral(@(x) sin((i-n-1)*pi*x/L) .* cos((j-1)*pi*x/L), -L, L);
            else
                A(i,j) = integral(@(x) sin((i-n-1)*pi*x/L) .* sin((j-n-1)*pi*x/L), -L, L);
            end
        end
        
        if i == 1
            b(i) = integral(@(x) f(x+c), -L+0.01, L-0.01, 'ArrayValued', true);
        elseif i <= n+1
            b(i) = integral(@(x) f(x+c) .* cos((i-1)*pi*x/L), -L+0.01, L-0.01, 'ArrayValued', true);
        else
            b(i) = integral(@(x) f(x+c) .* sin((i-n-1)*pi*x/L), -L+0.01, L-0.01, 'ArrayValued', true);
        end
    end
    
    % Solve the system Ax = b
    coeffs = A \ b;
end

function y = trig_approx(coeffs, x, a, b)
    n = (length(coeffs) - 1) / 2;
    L = (b - a) / 2;
    c = (a + b) / 2;
    x_shifted = x - c;
    
    y = coeffs(1) / 2;
    for k = 1:n
        y = y + coeffs(k+1) * cos(k*pi*x_shifted/L) + coeffs(n+k+1) * sin(k*pi*x_shifted/L);
    end
end

function compute_error_metrics(f, domain, degrees)
    % Exclude the endpoints to avoid infinite values
    x = linspace(domain(1) + 0.01, domain(2) - 0.01, 1000);
    y = f(x);
    
    fprintf('Error Metrics:\n');
    fprintf('%-10s %-15s %-15s %-15s %-15s\n', 'n', 'Poly Max Error', 'Poly L2 Error', 'Trig Max Error', 'Trig L2 Error');
    
    for n = degrees
        % Polynomial approximation
        coeffs_poly = least_squares_polynomial(f, domain(1), domain(2), n);
        y_poly = polyval(flip(coeffs_poly), x);
        max_error_poly = max(abs(y - y_poly));
        l2_error_poly = sqrt(trapz(x, (y - y_poly).^2));
        
        % Trigonometric approximation
        coeffs_trig = least_squares_trig(f, domain(1), domain(2), n);
        y_trig = trig_approx(coeffs_trig, x, domain(1), domain(2));
        max_error_trig = max(abs(y - y_trig));
        l2_error_trig = sqrt(trapz(x, (y - y_trig).^2));
        
        fprintf('%-10d %-15.6e %-15.6e %-15.6e %-15.6e\n', n, max_error_poly, l2_error_poly, max_error_trig, l2_error_trig);
    end
end