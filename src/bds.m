function [xopt, fopt, exitflag, output] = bds(fun, x0, options)
%BDS solves unconstrained optimization problems without using derivatives by
%blockwise direct search methods.
%
%   BDS supports in MATLAB R2017b or later.
%
%   XOPT = BDS(FUN, X0) returns an approximate minimizer XOPT of the function
%   FUN, starting the calculations at X0. FUN must accept a vector input X and
%   return a scalar.
%
%   XOPT = BDS(FUN, X0, OPTIONS) performs the computations with the options in
%   OPTIONS. OPTIONS should be a structure with the following fields.
%
%   Algorithm                   Algorithm to use. It can be "cbds" (cyclic 
%                               blockwise direct search) "pbds" (randomly 
%                               permuted blockwise direct search), "rbds" 
%                               (randomized blockwise direct search), "ds"
%                               (the classical direct search), "pads" (parallel 
%                               blockwise direct search). "scbds" (symmetric
%                               blockwise direct search). Default: "cbds".
%   Scheme                      Scheme to use. It can be "cyclic", "random", "parallel",
%                               Default: "cyclic".
%   num_blocks                  Number of blocks. A positive integer. 
%                               Default: ceil(num_directions/2), where num_directions
%                               is the number of directions used to define the polling
%                               directions.
%   MaxFunctionEvaluations      Maximum of function evaluations. A positive integer.
%   direction_set               A matrix whose columns will be used to define
%                               the polling directions. If options does not
%                               contain direction_set, then the polling
%                               directions will be {e_1, -e_1, ..., e_n, -e_n}.
%                               Otherwise, it should be a nonsingular n-by-n matrix.
%                               Then the polling directions will be
%                               {d_1, -d_1, ..., d_n, -d_n}, where d_i is the
%                               i-th column of direction_set. If direction_set
%                               is not singular, then we will revise the
%                               direction_set to make it linear independent.
%                               See get_direction_set.m for details. Default: eye(n).
%   is_noisy                    A flag deciding whether the problem is noisy or
%                               not. Default: false.
%   expand                      Expanding factor of step size. A real number
%                               no less than 1. It depends on the dimension of
%                               the problem and whether the problem is noisy or
%                               not and the Algorithm. Default: 2.
%   shrink                      Shrinking factor of step size. A positive number
%                               less than 1. It depends on the dimension of the
%                               problem and whether the problem is noisy or not
%                               and the Algorithm. Default: 0.5.
%   alpha_threshold             The threshold of the step size. When the step
%                               size shrinks, the step size will be updated to
%                               be the maximum of alpha_threshold and shrink*alpha.
%                               It should be strictly less than StepTolerance.
%                               A positive number. Default: 1e-3*StepTolerance.
%   forcing_function            The forcing function used for deciding whether
%                               the step achieves a sufficient decrease. A
%                               function handle.
%                               Default: @(alpha) alpha^2. See also reduction_factor.
%   reduction_factor            Factors multiplied to the forcing function when
%                               deciding whether the step achieves a sufficient decrease.
%                               A 3-dimentional vector such that
%                               reduction_factor(1) <= reduction_factor(2) <= reduction_factor(3),
%                               reduction_factor(1) >= 0, and reduction_factor(2) > 0.
%                               reduction_factor(0) is used for deciding whether
%                               to update
%                               the base point;
%                               reduction_factor(1) is used for deciding whether
%                               to shrink the step size;
%                               reduction_factor(2) is used for deciding whether
%                               to expand the step size.
%                               Default: [0, eps, eps]. See also forcing_function.
%   StepTolerance               Lower bound of the step size. If the step size is
%                               smaller than StepTolerance, then the algorithm
%                               terminates.A (small) positive number. Default: 1e-10.
%   ftarget                     Target of the function value. If the function value
%                               is smaller than or equal to ftarget, then the
%                               algorithm terminates. A real number. Default: -Inf.
%   polling_inner               Polling strategy in each block. It can be "complete" or
%                               "opportunistic". Default: "opportunistic".
%   cycling_inner               Cycling strategy employed within each block. It
%                               is used only when polling_inner is "opportunistic".
%                               It can be 0, 1, 2, 3, 4. See cycling.m for details.
%                               Default: 3.
%   with_cycling_memory         Whether the cycling strategy within each block memorizes
%                               the history or not. It is used only when polling_inner
%                               is "opportunistic". Default: true.
%                               A positive integer. Default: 1.
%   batch_size                  Suppose that batch_size is k. In each iteration,
%                               k blocks are randomly selected to visit. A positive
%                               integer less than or equal to num_blocks.
%                               Default: num_blocks.
%   replacement_delay           Suppose that replacement_delay is r. If replacement_delay > 0 
%                               and block i is selected at iteration k, then it will not 
%                               be selected at iterations k+1, ..., k+r. The value of 
%                               replacement_delay should be an nonnegative integer less than or 
%                               equal to floor(num_blocks/batch_size)-1.                               
%                               Default: floor(num_blocks/batch_size)-1.
%   seed                        The seed for random number generator. Default: "shuffle".
%   use_estimated_gradient_stop Whether to use the estimated gradient to stop
%                               the algorithm. If it is true and the problem is
%                               not noisy and each block will be visited once in
%                               each iteration, then the algorithm will estimate
%                               the gradient of the function at the best point
%                               encountered so far when the sufficient decrease
%                               condition is not achieved in the previous iteration.
%                               It is an optional termination criterion.
%                               Default: false.
%   output_xhist                Whether to output the history of points visited.
%                               Default: false.
%   output_alpha_hist           Whether to output the history of step sizes.
%                               Default: false.
%   output_block_hist           Whether to output the history of blocks visited.
%                               Default: false.
%   verbose                     a flag deciding whether to print during the computation.
%                               Default: false, which means no printing. If verbose
%                               is true, then the function values, the corresponding
%                               point, and the step size will be printed in each
%                               function evaluation.
%
%   [XOPT, FOPT] = BDS(...) returns an approximate minimizer XOPT and its function value FOPT.
%
%   [XOPT, FOPT, EXITFLAG] = BDS(...) also returns an EXITFLAG that indicates the exit
%   condition. The possible values of EXITFLAG are 0, 1, 2, and 3.
%
%   0    The StepTolerance of the step size is reached.
%   1    The target of the objective function is reached.
%   2    The maximum number of function evaluations is reached.
%   3    The maximum number of iterations is reached.
%
%   [XOPT, FOPT, EXITFLAG, OUTPUT] = BDS(...) returns a
%   structure OUTPUT with the following fields.
%
%   fhist        History of function values.
%   xhist        History of points visited (if output_xhist is true).
%   alpha_hist   History of step size for every iteration (if output_alpha_hist is true).
%   blocks_hist  History of blocks visited (if output_block_hist is true).
%   funcCount    The number of function evaluations.
%   message      The information of EXITFLAG.
%
%   ***********************************************************************
%   Authors:    Haitian LI (hai-tian.li@connect.polyu.hk)
%               and Zaikun ZHANG (zaikun.zhang@polyu.edu.hk)
%               Department of Applied Mathematics,
%               The Hong Kong Polytechnic University
%   ***********************************************************************
%   All rights reserved.
%

% Set options to an empty structure if it is not provided.
if nargin < 3
    options = struct();
end

% Transpose x0 if it is a row.
x0_is_row = isrow(x0);
x0 = double(x0(:));

% Get the dimension of the problem.
n = length(x0);

% Set the default value of debug_flag. If options do not contain debug_flag, then
% debug_flag is set to false.
if isfield(options, "debug_flag")
    debug_flag = options.debug_flag;
else
    debug_flag = false;
end

% Get the direction set.
D = get_direction_set(n, options);
% Get the number of blocks.
num_directions = size(D, 2);

% Set the default value of scheme.
scheme_list = ["cyclic", "random", "parallel"];
if isfield(options, "scheme") && ~ismember(lower(options.scheme), scheme_list)
    error("The scheme should be one of the following: cyclic, random, parallel.\n");
end

% Set the default value of num_blocks and batch_size.
if isfield(options, "num_blocks")
    num_blocks = options.num_blocks;
else
    % num_blocks = ceil(num_directions / 2);
    % Avoid using division to get num_blocks to avoid numerical issues.
    % In our case, num_directions is 2*n, so num_blocks is n.
    num_blocks = n;
end

% Preprocess the number of blocks.
if isfield(options, "num_blocks")
    if options.num_blocks > num_directions
        error("The number of blocks should be less than or equal to the number of directions.\n");
    end
    if options.num_blocks > n
        warning("The number of blocks should be less than or equal to the dimension of the problem.\n");
        warning("The number of blocks is set to be the minimum of the number of directions and the dimension of the problem.\n");
        options.num_blocks = min(num_directions, n);
    end
end

if isfield(options, "batch_size")
    batch_size = options.batch_size;
else
    batch_size = num_blocks;
end

% Ensure batch_size does not exceed num_blocks.
if batch_size > num_blocks
    warning("The number of batch_size should be less than or equal to the number of blocks.");
    fprintf("\n!!! THE NUMBER OF BATCH_SIZE IS SET TO BE THE NUMBER OF BLOCKS !!!\n");
    batch_size = num_blocks;
end

% Set the default value of scheme if it is not provided.
if ~isfield(options, "scheme")
    scheme = get_default_constant("scheme");
else
    scheme = lower(options.scheme);
end

% Set the default Algorithm of BDS, which is "cbds".
Algorithm_list = ["ds", "cbds", "pbds", "rbds", "pads"];
if isfield(options, "Algorithm") && ~ismember(lower(options.Algorithm), Algorithm_list)
    error("The Algorithm input is invalid");
end
if isfield(options, "Algorithm")
    options.Algorithm = lower(options.Algorithm);
    switch lower(options.Algorithm)
        case "ds"
            num_blocks = 1;
            batch_size = 1;
        case "cbds"
            num_blocks = n;
            batch_size = n;
            scheme = "cyclic";
        case "pbds"
            num_blocks = n;
            batch_size = n;
            scheme = "random";
        case "rbds"
            num_blocks = n;
            batch_size = 1;
            options.replacement_delay = floor(num_blocks/batch_size)-1;
            scheme = "random";
        case "pads"
            num_blocks = n;
            batch_size = n;
            scheme = "parallel";
        otherwise
            error("The Algorithm input is invalid");
    end
end

% Determine the indices of directions in each block.
direction_set_indices = divide_direction_set(n, num_blocks);

% Check the inputs of the user when debug_flag is true.
if debug_flag
    verify_preconditions(fun, x0, options);
end

% If FUN is a string, then convert it to a function handle.
if ischarstr(fun)
    fun = str2func(fun);
end
% Redefine fun to accept columns if x0 is a row, as we use columns internally.
fun_orig = fun;
if x0_is_row
    fun = @(x)fun(x');
end

% To avoid that the users bring some randomized strings.
if ~isfield(options, "seed")
    options.seed = get_default_constant("seed");
end
random_stream = RandStream("mt19937ar", "Seed", options.seed);

% Set the default value of noisy.
if isfield(options, "is_noisy")
    is_noisy = options.is_noisy;
else
    is_noisy = get_default_constant("is_noisy");
end

% Set the value of expand and shrink based on the dimension of the problem and the Algorithm,
% and whether the problem is noisy or not. The default values of expand and shrink are
% selected based on the S2MPJ problems (see https://github.com/GrattonToint/S2MPJ).
% If options contain expand or shrink, then expand or shrink is set to the corresponding value.
if ~isfield(options, "expand")
    % n == 1 is treated as a special case, and we can treat the Algorithm as "ds".
    if (isfield(options, "Algorithm") && strcmpi(options.Algorithm, "ds")) || n == 1 || (num_blocks == 1 && batch_size == 1)
        if numel(x0) <= 5
            expand = get_default_constant("ds_expand_small");
        else
            % Judge whether the problem is noisy or not.
            if is_noisy
                expand = get_default_constant("ds_expand_big_noisy");
            else
                expand = get_default_constant("ds_expand_big");
            end
        end
    else
        if numel(x0) <= 5
            expand = get_default_constant("expand_small");
        else
            if is_noisy
                expand = get_default_constant("expand_big_noisy");
            else
                expand = get_default_constant("expand_big");
            end
        end
    end
else
    expand = options.expand;
end

if ~isfield(options, "shrink")
    if (isfield(options, "Algorithm") && strcmpi(options.Algorithm, "ds")) || n == 1 || (num_blocks == 1 && batch_size == 1)
        if numel(x0) <= 5
            shrink = get_default_constant("ds_shrink_small");
        else
            if is_noisy
                shrink = get_default_constant("ds_shrink_big_noisy");
            else
                shrink = get_default_constant("ds_shrink_big");
            end
        end
    else
        if numel(x0) <= 5
            shrink = get_default_constant("shrink_small");
        else
            if is_noisy
                shrink = get_default_constant("shrink_big_noisy");
            else
                shrink = get_default_constant("shrink_big");
            end
        end
    end
else
    shrink = options.shrink;
end

% Set the value of reduction_factor.
if isfield(options, "reduction_factor")
    reduction_factor = options.reduction_factor;
else
    reduction_factor = get_default_constant("reduction_factor");
end

% Set the forcing function, which should be the function handle.
if isfield(options, "forcing_function")
    forcing_function = options.forcing_function;
else
    forcing_function = get_default_constant("forcing_function");
end

% Set polling_inner, which is the polling strategy employed within one block.
if ~isfield(options, "polling_inner")
    options.polling_inner = get_default_constant("polling_inner");
end

% Set cycling_inner, which represents the cycling strategy inside each block.
if isfield(options, "cycling_inner")
    cycling_inner = options.cycling_inner;
else
    cycling_inner = get_default_constant("cycling_inner");
end

% If replacement_delay is r, then the block that is selected in the current
% iteration will not be selected in the next r iterations. Note that replacement_delay cannot exceed
% floor(num_blocks/batch_size)-1. The reason we set the default value of replacement_delay to
% floor(num_blocks/batch_size)-1 is that the performance will be better when replacement_delay is larger.
if isfield(options, "replacement_delay")
    replacement_delay = min(options.replacement_delay, floor(num_blocks/batch_size)-1);
else
    replacement_delay = floor(num_blocks/batch_size)-1;
end

% fprintf("bds.m: expand = %f, shrink = %f, replacement_delay = %d\n", expand, shrink, replacement_delay);

% Set the boolean value of with_cycling_memory, which will be used in cycling.m.
% cycling.m decides the order of the directions in each block when we perform direct search
% in this block. This order is represented by direction_indices. If with_cycling_memory is true,
% then direction_indices is decided based on the last direction_indices; otherwise, it is
% decided based on the initial direction_indices.
if isfield(options, "with_cycling_memory")
    with_cycling_memory = options.with_cycling_memory;
else
    with_cycling_memory = get_default_constant("with_cycling_memory");
end

% Set the maximum number of function evaluations. If the options do not contain MaxFunctionEvaluations,
% it is set to MaxFunctionEvaluations_dim_factor*n, where n is the dimension of the problem.
if isfield(options, "MaxFunctionEvaluations")
    MaxFunctionEvaluations = options.MaxFunctionEvaluations;
else
    MaxFunctionEvaluations = get_default_constant("MaxFunctionEvaluations_dim_factor")*n;
end

% Set the maximum number of iterations.
% Each iteration will use at least one function evaluation. Setting maxit to MaxFunctionEvaluations will
% ensure that MaxFunctionEvaluations is exhausted before maxit is reached.
maxit = MaxFunctionEvaluations;

% Set the value of StepTolerance. The algorithm will terminate if the stepsize is less than
% the StepTolerance.
if isfield(options, "StepTolerance")
    alpha_tol = options.StepTolerance;
else
    alpha_tol = get_default_constant("StepTolerance");
end


if isfield(options, "grad_tol")
    grad_tol = options.grad_tol;
else
    grad_tol = get_default_constant("grad_tol");
end

% Set the value of alpha_threshold. If the step size is smaller than alpha_threshold, then the step size
% will be not allowed to shrink below alpha_threshold.
if isfield(options, "alpha_threshold")
    alpha_threshold = options.alpha_threshold;
else
    alpha_threshold = get_default_constant("alpha_threshold_ratio")*alpha_tol;
end

% Set the target of the objective function.
if isfield(options, "ftarget")
    ftarget = options.ftarget;
else
    ftarget = get_default_constant("ftarget");
end

% Decide whether to output the history of step sizes.
if isfield(options, "output_alpha_hist")
    output_alpha_hist = options.output_alpha_hist;
else
    output_alpha_hist = get_default_constant("output_alpha_hist");
end
% Initialize alpha_hist if output_alpha_hist is true and alpha_hist does not exceed the
% maximum memory size allowed.
try
    alpha_hist = NaN(num_blocks, maxit);
catch
    output_alpha_hist = false;
    warning("alpha_hist will be not included in the output due to the limit of memory." )
end


% Set the initial step sizes. If options do not contain the field of alpha_init, then the
% initial step size of each block is set to 1. If alpha_init is a positive scalar, then the initial step
% size of each block is set to alpha_init. If alpha_init is a vector, then the initial step size
% of the i-th block is set to alpha_init(i). If alpha_init is "auto", then the initial step size is
% set according to the coordinates of x0 with respect to the directions in D(:, 1 : 2 : 2*n-1).
if isfield(options, "alpha_init")
    if isscalar(options.alpha_init)
        alpha_all = options.alpha_init*ones(num_blocks, 1);
    elseif length(options.alpha_init) == num_blocks
        alpha_all = options.alpha_init;
    % elseif strcmpi(options.alpha_init,"auto")
    %     % x0_coordinates is the coordinates of x0 with respect to the directions in
    %     % D(:, 1 : 2 : 2*n-1), where D(:, 1 : 2 : 2*n-1) is a basis of R^n.
    %     x0_coordinates = D(:, 1 : 2 : 2*n-1) \ x0;
    %     alpha_all = 0.5 * max(1, abs(x0_coordinates));
    end
else
    alpha_all = ones(num_blocks, 1);
end
alpha_hist(:, 1) = alpha_all(:);

% Initialize the history of function values.
fhist = NaN(1, MaxFunctionEvaluations);

% Initialize the boolean variable to indicate whether the algorithm should return the history of visited points.
if isfield(options, "output_xhist")
    output_xhist = options.output_xhist;
else
    output_xhist = get_default_constant("output_xhist");
end
% If xhist exceeds the maximum memory size allowed, then we will not output xhist.
if output_xhist
    try
        xhist = NaN(n, MaxFunctionEvaluations);
    catch
        output_xhist = false;
        warning("xhist will be not included in the output due to the limit of memory.");
    end
end

% Decide whether to output the history of blocks visited.
if isfield(options, "output_block_hist")
    output_block_hist = options.output_block_hist;
else
    output_block_hist = get_default_constant("output_block_hist");
end
% Initialize the history of sufficient decrease value and the boolean value of whether the sufficient decrease
% is achieved or not.
if isfield(options, "output_sufficient_decrease")
    output_sufficient_decrease = options.output_sufficient_decrease;
else
    output_sufficient_decrease = get_default_constant("output_sufficient_decrease");
end

if isfield(options, "use_estimated_gradient_stop")
    use_estimated_gradient_stop = options.use_estimated_gradient_stop;
else
    use_estimated_gradient_stop = false;
end

% Initialize the history of sufficient decrease value and the boolean value of whether the sufficient decrease
% is achieved or not.
try
    decrease_value = zeros(num_blocks, MaxFunctionEvaluations);
catch
    warning("decrease_value will be not included in the output due to the limit of memory.");
end
try
    sufficient_decrease = true(num_blocks, MaxFunctionEvaluations);
catch
    warning("sufficient_decrease will be not included in the output due to the limit of memory.");
end

% Initialize the history of sufficient decrease value and the boolean value of whether the sufficient decrease
% is achieved or not when the problem is not noisy and each block will be visited once in each iteration,
% i.e., the Algorithm is "cbds" or "pbds" or "rbds" and batch_size is equal to num_blocks.
% The use of sufficient_decrease_value and sufficient_decrease is to estimate the gradient of the function
% at the best point encountered so far when the sufficient decrease condition is not achieved in the previous
% iteration. It is an optional termination criterion unless use_estimated_gradient_stop is true.
is_estimated_gradient_stop = use_estimated_gradient_stop && ~is_noisy && ...
    (((strcmpi(options.Algorithm, "cbds") || strcmpi(options.Algorithm, "pbds")) && num_blocks == n) ...
    || (strcmpi(options.Algorithm, "rbds") && batch_size == n));

% Decide whether to print during the computation.
if isfield(options, "verbose")
    verbose = options.verbose;
else
    verbose = get_default_constant("verbose");
end
% Initialize the history of blocks visited.
block_hist = NaN(1, MaxFunctionEvaluations);

% Initialize exitflag. If exitflag is not set elsewhere, then the maximum number of iterations
% is reached, and hence we initialize exitflag to the corresponding value.
exitflag = get_exitflag("MAXIT_REACHED");

% Initialize xbase and fbase. xbase serves as the "base point" for the computation in the next
% block, meaning that reduction will be calculated with respect to xbase. fbase is the function
% value at xbase.
xbase = x0;
% fbase_real is the real function value at xbase, which is the value returned by fun
% (not eval_fun).
[fbase, fbase_real] = eval_fun(fun, xbase);
if verbose
    fprintf("Function number %d, F = %.8f\n", 1, fbase_real);
    fprintf("The corresponding X is:\n");
    fprintf("%.8f  ", xbase(:)');
    fprintf("\n");
    fprintf("The corresponding alpha are:\n");
    fprintf("%.10e ", alpha_all);
    fprintf("\n");
end
% Initialize xopt and fopt. xopt is the best point encountered so far, and fopt is the
% corresponding function value.
xopt = xbase;
fopt = fbase;

% Initialize nf (the number of function evaluations), xhist (history of points visited), and
% fhist (history of function values).
nf = 1;
if output_xhist
    xhist(:, nf) = xbase;
end
% When we record fhist, we should use the real function value at xbase, which is fbase_real.
fhist(nf) = fbase_real;

terminate = false;
% Check whether FTARGET is reached by fopt. If it is true, then terminate.
if fopt <= ftarget
    information = "FTARGET_REACHED";
    exitflag = get_exitflag(information);

    % FTARGET has been reached at the very first function evaluation.
    % In this case, no further computation should be entertained, and hence,
    % no iteration should be run.
    maxit = 0;
end

% Initialize the block_indices, which is a vector containing the indices of blocks that we
% are going to visit iterately. Initialize the number of blocks visited also.
all_block_indices = (1:num_blocks);
num_visited_blocks = 0;
grad_hist = [];
% fopt_all(i) stores the best function value found in the i-th block after one iteration, 
% while xopt_all(:, i) holds the corresponding x. If a block is not visited during the iteration, 
% fopt_all(i) is set to NaN. Both fopt_all and xopt_all have a length of num_blocks, not batch_size, 
% as not all blocks might not be visited in each iteration, but the best function value across all 
% blocks must still be recorded.
fopt_all = NaN(1, num_blocks);
xopt_all = NaN(n, num_blocks);

for iter = 1:maxit

    % Use central difference to estimate the gradient of the function at xopt if the sufficient decrease
    % condition is not achieved in the previous iteration and the problem is not noisy.
    if is_estimated_gradient_stop && iter > 1 && ~any(sufficient_decrease(:, iter-1))
        if verbose
            fprintf("The Algorithm is %s and failed to achieve sufficient decrease " ...
                + "in the previous iteration.\n", options.Algorithm);
        end
        g = NaN(n, 1);
        % The following loop is to estimate the gradient at xopt using central difference, with the
        % function values stored in the previous iteration.
        for i = 1:n
            i_real = block_indices(i);
            g(i_real) = (fhist(nf - 2*(i_real - 1) - 1) - fhist(nf - 2*(i_real - 1))) / (2*alpha_hist(i_real, iter-1));
        end
        grad_hist = [grad_hist norm(g)];
        if min(grad_hist) < grad_tol || (length(grad_hist) > 1 && ...
                (grad_hist(1) - grad_hist(end)) / grad_hist(1) > (1 - 1e-6))
            if min(grad_hist) < grad_tol
                exitflag = get_exitflag("SMALL_ESTIMATE_GRADIENT");
            else
                exitflag = get_exitflag("ESTIMATED_GRADIENT_FULLY_REDUCED");
            end
            break;
        end
    end
    
    % Define block_indices, a vector that specifies both the indices of the blocks
    % and the order in which they will be visited during the current iteration.
    % The length of block_indices is equal to batch_size.
    % These blocks should not have been visited in the previous replacement_delay
    % iterations when the replacement_delay is nonnegative.
    unavailable_block_indices = unique(block_hist(max(1, (iter-replacement_delay) * batch_size) : (iter-1) * batch_size), 'stable');
    available_block_indices = setdiff(all_block_indices, unavailable_block_indices);

    % Select batch_size blocks randomly from the available blocks. The selected blocks
    % will be visited in this iteration.
    block_indices = available_block_indices(random_stream.randperm(length(available_block_indices), batch_size));
    
    % Choose the block visiting scheme based on options.scheme.
    switch scheme
        case "cyclic"
            block_indices = sort(block_indices);
        case "random"
            % block_indices = block_indices(random_stream.randperm(length(block_indices)));
        case "parallel"
            block_indices = all_block_indices;
        otherwise
            error('Invalid scheme input. The scheme should be one of the following: cyclic, random, parallel.\n');
    end

    for i = 1:length(block_indices)

        % i_real = block_indices(i) is the real index of the block to be visited. For example,
        % if block_indices is [1 3 2] and i = 2, then we are going to visit the 3rd block.
        i_real = block_indices(i);

        % Get indices of directions in the i_real-th block.
        direction_indices = direction_set_indices{i_real};

        % Set the options for the direct search within the i_real-th block.
        suboptions.FunctionEvaluations_exhausted = nf;
        suboptions.MaxFunctionEvaluations = MaxFunctionEvaluations - nf;
        suboptions.cycling_inner = cycling_inner;
        suboptions.with_cycling_memory = with_cycling_memory;
        suboptions.reduction_factor = reduction_factor;
        suboptions.forcing_function = forcing_function;
        suboptions.ftarget = ftarget;
        suboptions.polling_inner = options.polling_inner;
        suboptions.verbose = verbose;

        % Perform the direct search within the i_real-th block.
        [sub_xopt, sub_fopt, sub_exitflag, sub_output] = inner_direct_search(fun, xbase,...
            fbase, D(:, direction_indices), direction_indices,...
            alpha_all(i_real), suboptions);

        % Record the sufficient decrease value and the boolean value of whether the sufficient decrease
        % is achieved or not if is_estimated_gradient_stop is true.
        decrease_value(i_real, iter) = sub_output.decrease_value;
        sufficient_decrease(i_real, iter) = sub_output.sufficient_decrease;

        if verbose
            fprintf("The number of the block visited is: %d\n", i_real);
            fprintf("The corresponding alpha are:\n");
            fprintf("%.8e ", alpha_all);
            fprintf("\n");
        end

        % Record the index of the block visited.
        num_visited_blocks = num_visited_blocks + 1;
        block_hist(num_visited_blocks) = i_real;

        % Record the points visited by inner_direct_search if output_xhist is true.
        if output_xhist
            xhist(:, (nf+1):(nf+sub_output.nf)) = sub_output.xhist;
        end

        % Record the function values calculated by inner_direct_search,
        fhist((nf+1):(nf+sub_output.nf)) = sub_output.fhist;

        % Update the number of function evaluations.
        nf = nf+sub_output.nf;

        % Update the step size alpha_all according to the reduction achieved.
        if sub_fopt + reduction_factor(3) * forcing_function(alpha_all(i_real)) < fbase
            alpha_all(i_real) = expand * alpha_all(i_real);
        elseif sub_fopt + reduction_factor(2) * forcing_function(alpha_all(i_real)) >= fbase
            % if isfield(options, "Algorithm") && ~strcmpi(options.Algorithm, "ds")
            %     if shrink * alpha_all(i_real) < alpha_threshold
            %         fprintf("The step size of the block %d is smaller than alpha_threshold.++++++++\n", i_real);
            %     end
            % end
            % The following strategy is used to avoid the case that the step size of some block is too small such
            % that it can not be updated. It might work on some anisotropic functions, but with no theoretical guarantee.
            alpha_all(i_real) = max(shrink * alpha_all(i_real), alpha_threshold);
            %alpha_all(i_real) = shrink * alpha_all(i_real);
        end
        
        % Record the best function value and point encountered in the i_real-th block.
        fopt_all(i_real) = sub_fopt;
        xopt_all(:, i_real) = sub_xopt;

        % If the scheme is not "parallel", then we will update xbase and fbase after finishing the
        % direct search in the i_real-th block. For "parallel", we will update xbase and fbase after
        % one iteration of the outer loop.
        if ~strcmpi(scheme, "parallel")
            % Update xbase and fbase. xbase serves as the "base point" for the computation in the next block,
            % meaning that reduction will be calculated with respect to xbase, as shown above.
            % Note that their update requires a sufficient decrease if reduction_factor(1) > 0.
            if (reduction_factor(1) <= 0 && sub_fopt < fbase) ...
                    || sub_fopt + reduction_factor(1) * forcing_function(alpha_all(i_real)) < fbase
                xbase = sub_xopt;
                fbase = sub_fopt;
            end
        end

        % Retrieve the direction indices of the i_real-th block, which represent the order of the
        % directions in the i_real-th block when we perform the direct search in this block next time.
        direction_set_indices{i_real} = sub_output.direction_indices;

        % Terminate the computations if sub_output.terminate is true, which means that inner_direct_search
        % decides that the algorithm should be terminated for some reason indicated by sub_exitflag.
        if sub_output.terminate
            terminate = true;
            exitflag = sub_exitflag;
            break;
        end

        % Terminate the computations if the largest step size is below StepTolerance.
        if max(alpha_all) < alpha_tol
            terminate = true;
            exitflag = get_exitflag("SMALL_ALPHA");
            break;
        end
    end

    % Record the step size for every iteration if output_alpha_hist is true.
    % Why iter+1? Because we record the step size for the next iteration.
    alpha_hist(:, iter+1) = alpha_all;

    % Actually, fopt is not always the minimum of fhist after the moment we update fopt
    % since the value we used to iterate is not always equal to the value returned by the function.
    % See eval_fun.m for details.
    % assert(fopt == min(fhist));

    % For "parallel", we will update xbase and fbase only after one iteration of the outer loop.
    % During the inner loop, every block will share the same xbase and fbase.
    if strcmpi(scheme, "parallel")
        % Update xbase and fbase. xbase serves as the "base point" for the computation in the
        % next block, meaning that reduction will be calculated with respect to xbase, as shown above.
        % Note that their update requires a sufficient decrease if reduction_factor(1) > 0.
        if (reduction_factor(1) <= 0 && fopt < fbase) || fopt + reduction_factor(1) * forcing_function(min(alpha_all)) < fbase
            xbase = xopt;
            fbase = fopt;
        end
    end

    % Update xopt and fopt. Note that we do this only if the iteration encounters a strictly better point.
    % Make sure that fopt is always the minimum of fhist after the moment we update fopt.
    % The determination between fopt_all and fopt is to avoid the case that fopt_all is
    % bigger than fopt due to the update of xbase and fbase.
    % NOTE: If the function values are complex, the min function will return the value with the smallest 
    % norm (magnitude).
    [~, index] = min(fopt_all, [], "omitnan");
    if fopt_all(index) < fopt
        fopt = fopt_all(index);
        xopt = xopt_all(:, index);
    end

    % Terminate the computations if terminate is true.
    if terminate
        break;
    end

end

% Record the number of function evaluations in output.
output.funcCount = nf;

% Truncate the histories of the blocks visited, the step sizes, the points visited,
% and the function values.
if output_block_hist
    output.blocks_hist = block_hist(1:num_visited_blocks);
end
if output_alpha_hist
    output.alpha_hist = alpha_hist(:, 1:min(iter, maxit));
end
if output_sufficient_decrease
    output.sufficient_decrease = sufficient_decrease(:, 1:min(iter, maxit));
    output.decrease_value = decrease_value(:, 1:min(iter, maxit));
    output.grad_hist = grad_hist;
end
if output_xhist
    output.xhist = xhist(:, 1:nf);
end
output.fhist = fhist(1:nf);

% Set the message according to exitflag.
switch exitflag
    case {get_exitflag("SMALL_ALPHA")}
        output.message = "The StepTolerance of the step size is reached.";
    case {get_exitflag("MAXFUN_REACHED")}
        output.message = "The maximum number of function evaluations is reached.";
    case {get_exitflag("FTARGET_REACHED")}
        output.message = "The target of the objective function is reached.";
    case {get_exitflag("MAXIT_REACHED")}
        output.message = "The maximum number of iterations is reached.";
    case {get_exitflag("SMALL_ESTIMATE_GRADIENT")}
        output.message = "The estimated gradient tolerance is reached.";
    case {get_exitflag("ESTIMATED_GRADIENT_FULLY_REDUCED")}
        output.message = "The estimated gradient is fully reduced.";
    otherwise
        output.message = "Unknown exitflag";
end

% Transpose xopt if x0 is a row.
if x0_is_row
    xopt = xopt';
end

% verify_postconditions is to detect whether the output is valid when debug_flag is true.
if debug_flag
    verify_postconditions(fun_orig, xopt, fopt, exitflag, output);
end
