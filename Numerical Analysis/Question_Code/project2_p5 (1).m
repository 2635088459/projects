function least_squares_exponential()
    % Define the function
    f = @(x) exp(-x.^2);
    
    % Define the domain
    domain = [-5, 5];
    
    % Define the degrees for approximation
    degrees = [2, 4, 6, 8];
    
    % Generate points for plotting
    x = linspace(domain(1), domain(2), 1000);
    y = f(x);
    
    % Create figure
    figure('Position', [100, 100, 1200, 800]);
    
    % Polynomial approximations
    subplot(2, 1, 1);
    plot(x, y, 'k-', 'LineWidth', 2);
    hold on;
    title('f(x) = e^{-x^2} - Polynomial Approximations');
    xlabel('x');
    ylabel('y');
    
    for n = degrees
        coeffs = least_squares_polynomial(f, domain(1), domain(2), n);
        y_approx = polyval(flip(coeffs), x);
        plot(x, y_approx, 'LineWidth', 1.5);
    end
    
    legend(['Original', arrayfun(@(n) ['n = ', num2str(n)], degrees, 'UniformOutput', false)]);
    hold off;
    
    % Trigonometric approximations
    subplot(2, 1, 2);
    plot(x, y, 'k-', 'LineWidth', 2);
    hold on;
    title('f(x) = e^{-x^2} - Trigonometric Approximations');
    xlabel('x');
    ylabel('y');
    
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
        b(i) = integral(@(x) f(x) .* x.^(i-1), a, b);
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
            b(i) = integral(@(x) f(x+c), -L, L);
        elseif i <= n+1
            b(i) = integral(@(x) f(x+c) .* cos((i-1)*pi*x/L), -L, L);
        else
            b(i) = integral(@(x) f(x+c) .* sin((i-n-1)*pi*x/L), -L, L);
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