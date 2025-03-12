% script for calculating trajectory metrics on trajectories that have been
% divided from raw data

function metrics = compute_trajectory_metrics(AllTrajectories, GoingTrajectories, bin_edges_x, bin_edges_y, nbins_x, nbins_y)
    % compute_trajectory_metrics calculates various metrics on an animal's
    % given trajectories
        %   Inputs:
        %       AllTrajectories - a cell array containing all the trajectories to
        %       be analyzed
        %       bin_edges_x - the values specifying the bin edges for the
        %       x-coordinates
        %       bin_edges_y - the values specifying the bin edges for the
        %       y-coordinates
        %       nbins_x - the number of bins to place that x-coordinates in
        %       nbins_y - the number of bins to place that y-coordinates in
        %
        %   Outputs:
        %       metrics - a struct containing the trajectory metrics 

    [all_trajectories, tortuosities, Velocities_full_traj, avg_velocities_full_traj] = create_all_trajectories_tortuosities(AllTrajectories);
    
    X = all_trajectories(:,7);
    Y = all_trajectories(:,8);

    [N,~,~] = histcounts2(X,Y, bin_edges_x, bin_edges_y); % N is a 39x39 containing the number of vectors in each bin
    index_x = discretize(X, bin_edges_x); % get bin number each x coordinate belongs to 
    index_y = discretize(Y, bin_edges_y); % get bin number each y coordinate belongs to 
    num_visited_bins = sum(sum(N(:,:) ~= 0)); % the number of bins that the JS has passed through

    % visited area in milimeters squared
    bin_size_x = bin_edges_x(2) - bin_edges_x(1);
    bin_size_y = bin_edges_y(2) - bin_edges_y(1);
    area_mm_squared = num_visited_bins * bin_size_x * bin_size_y;

    % data structures for calculating mean angular deviation and angular
    % mean later
    [angles_for_mean, angles_for_std, angles_for_std_1d, vectors_2d] = get_angles_vectors_in_bins(nbins_x, nbins_y, all_trajectories, index_x, index_y, N);
    [means_per_bin, weights_for_mean, weights_for_std] = get_means_per_bin_weights(nbins_x, nbins_y, bin_edges_x, bin_edges_y, N, vectors_2d);

    % calculate weighted circular mean 
    %angles_for_mean_1d = all_trajectories(:,11);
    %rad_weighted_mean_angle = weighted_circ_mean(angles_for_mean_1d, weights_for_mean);
    %deg_weighted_mean_angle = rad_weighted_mean_angle * (180/pi);
    
    % calculate circular st dev with code from package
    %[rad_std, ~] = weighted_circ_std(angles_for_std_1d, weights_for_std); % rad_std is the angular deviation for a whole session
    [rad_mean_per_bin, deg_mean_per_bin, rad_std_per_bin, all_std] = unweighted_mean_std_per_bin(nbins_x, nbins_y, angles_for_mean, angles_for_std, N);

    % mean angular deviation
    rad_mean_angular_std = mean(all_std);

    % calculate velocity between first and last point of GoingTrajectories,
    % where the portions of reaching, or going, in the trajectories are saved
    velocities_start_to_max = zeros(size(GoingTrajectories, 1), 1);
    v_count = 0;
    for i = 1:size(GoingTrajectories, 1)
        going_trajectory = GoingTrajectories{i, 1};
        if ~isempty(going_trajectory)
            first_x = going_trajectory(1, 7);
            first_y = going_trajectory(1, 8);
            last_x = going_trajectory(end, 7);
            last_y = going_trajectory(end, 8);
            dist = sqrt((last_x - first_x)^2 + (last_y - first_y)^2);
            time_change = (going_trajectory(end, 1) - going_trajectory(1, 1)); %/ 1000; % convert miliseconds to seconds by dividing by 1000
            velocities_start_to_max(i) = dist / time_change;
            v_count = v_count + 1;
        end
    end

    % remove zeros at the end if there were unfilled spaces due to empty
    % cell in GoingTrajectories
    velocities_start_to_max = velocities_start_to_max(1:v_count, 1);

    % save data in metrics struct to return
    metrics.tortuosities = tortuosities;
    metrics.avg_tortuosity = mean(tortuosities);
    metrics.N = N;
    metrics.num_visited_bins = num_visited_bins;
    metrics.area_mm_squared = area_mm_squared;
    metrics.angles_for_mean = angles_for_mean;
    metrics.angles_for_std = angles_for_std;
    metrics.vectors_2d = vectors_2d;
    metrics.means_per_bin = means_per_bin;
    metrics.all_std = all_std;
    metrics.rad_means_per_bin = rad_mean_per_bin;
    metrics.deg_means_per_bin = deg_mean_per_bin;
    metrics.rad_std_per_bin = rad_std_per_bin;
    metrics.rad_mean_angular_std = rad_mean_angular_std;
    metrics.Velocities = Velocities_full_traj;
    metrics.avg_velocities_full_traj = avg_velocities_full_traj;
    metrics.velocities_start_to_max = velocities_start_to_max;

end


function [all_trajectories, tortuosities, Velocities, avg_velocities] = create_all_trajectories_tortuosities(AllTrajectories)
    % create_all_trajectories_tortuosities calculates various metrics on an animal's
        %   Inputs:
        %       AllTrajectories - a cell array containing all the trajectories to
        %       be analyzed
        %
        %   Outputs:
        %       all_trajectories - a 2d matrix containing all coordinates of
        %       the joystick movements
        %       tortuosities - a matrix containing one tortuosity value per
        %       trajectory

    % store all x- and y- coordinates in all_trajectories
    num_cols = size(AllTrajectories{1,1}, 2);%11;
    num_total_points = sum(cellfun(@numel, AllTrajectories) ./ num_cols);
    all_trajectories = zeros(num_total_points(1), num_cols);

    % store all tortuosities in 'tortuosities'
    num_trajectories = size(AllTrajectories, 1);
    tortuosities = zeros(num_trajectories, 1);
    row_count = 1;
    Velocities = cell(size(AllTrajectories, 1),1);
    avg_velocities = zeros(num_trajectories, 1);

    for i = 1:size(AllTrajectories, 1) % access all trajectories in allTrials
        current_trajectory = AllTrajectories{i,1};
        total_path_length = 0;
        traj_velocities = zeros(size(current_trajectory, 1), 1);
        for j = 1:size(current_trajectory, 1) % traverse through each movement in each trajectory
            x1 = current_trajectory(j,7); % x coordinate
            y1 = current_trajectory(j,8); % y coordinate
            all_trajectories(row_count, :) = current_trajectory(j, :);
            row_count = row_count + 1;
            
            % as we traverse through a trajectory, calculate path movement from
            % current pair of coordinates to the next pair of coordinates
            if j ~= size(current_trajectory, 1) % if we're not at the last movement, we can access the next pair of coordinates
                x2 = current_trajectory(j+1,7);
                y2 = current_trajectory(j+1,8);
    
                % distance between current coordinates and next coordinates
                total_path_length = total_path_length + sqrt((x2 - x1)^2 + (y2 - y1)^2);

                % calculate velocity between each point
                dist_btwn_2_points = sqrt((x2 - x1)^2 + (y2 - y1)^2);
                time_change = (current_trajectory(j + 1, 1) - current_trajectory(j, 1)); %/ 1000; % divide by 1000 to get seconds instead of miliseconds
                traj_velocities(j) = dist_btwn_2_points / time_change;
            end
        end
    
        % Euclidean distance between first and last point on the path 
        if ~isempty(current_trajectory) 
            first = [current_trajectory(1,2), current_trajectory(1,3)];
            last = [current_trajectory(end, 2), current_trajectory(end, 3)];
            dist_first_last = sqrt((last(1) - first(1))^2 + (last(2) - first(2))^2);
            
            if dist_first_last ~= 0 % we can't divide by zero, so ensure dist_first_last is nonzero
                % divide total path length by the distance btwn first and last point
                tortuosities(i) = total_path_length / dist_first_last;
            end

            % save velocities for this trajectory in Velocities cell array
            Velocities{i, 1} = traj_velocities;
            avg_velocities(i) = mean(traj_velocities);
           
        end
    end

end

function [angles_for_mean, angles_for_std, angles_for_std_1d, vectors_2d] = get_angles_vectors_in_bins(nbins_x, nbins_y, all_trajectories, index_x, index_y, N)
    % get_angles_vectors_in_bins creates cell arrays and matrices to hold
    % all angles and vectors
        %   Inputs:
        %       nbins_x - the number of bins to place that x-coordinates in
        %       nbins_y - the number of bins to place that y-coordinates in
        %       all_trajectories - a 2d matrix containing all coordinates of
        %       the joystick movements
        %       index_x - contains the bin numbers each x-coordinate
        %       belongs to
        %       index_y - contains the bin numbers each y-coordinate
        %       belongs to
        %       N - the output of binning the 2d joystick data using the
        %       histcounts function
        %
        %   Outputs:
        %       angles_for_mean - a 2d cell array containing all angles in
        %       their respective bins
        %       angles_for_std - a 2d cell array containing angles in the bins
        %       with at least 3 visits
        %       angles_for_std_1d - a one-dimensional matrix containing
        %       angles that occur in bins with at least 3 visits
        %       vectors_2d - a 2d cell array containing the vectors for
        %       each bin

    % find the vectors that correspond to each bin
    angles_for_mean = cell(nbins_x - 1, nbins_y - 1);
    angles_for_std = cell(nbins_x - 1, nbins_y - 1);
    angles_for_std_1d = zeros(1, sum(N(N(:,:) >= 3)));
    angles_for_std_1d_count = 1;
    vectors_2d = cell(nbins_x - 1, nbins_y - 1);

    for count = 1:size(all_trajectories, 1) - 1
        % get bin the current trajectory belongs to
        bin_x = index_x(count);
        bin_y = index_y(count);
        vector = [all_trajectories(count, 9), all_trajectories(count, 10)];
        vectors_2d{bin_x, bin_y} = [vectors_2d{bin_x, bin_y}; vector];
        
        angles_for_mean{bin_x, bin_y} = all_trajectories(count, 11);
        
        % only place an angle in a bin if it has 3 or more angles in that
        % bin, to calculate angular deviation later 
        if N(bin_x, bin_y) >= 3
            angles_for_std{bin_x, bin_y} = all_trajectories(count, 11);
            angles_for_std_1d(1, angles_for_std_1d_count) = all_trajectories(count, 11);
            angles_for_std_1d_count = angles_for_std_1d_count + 1;
        end
    end
end

function [means_per_bin, weights_for_mean, weights_for_std] = get_means_per_bin_weights(nbins_x, nbins_y, bin_edges_x, bin_edges_y, N, vectors_2d)
    % get_means_per_bin_weights creates cell arrays and matrices to hold
    % all angles and vectors
        %   Inputs:
        %       nbins_x - the number of bins to place that x-coordinates in
        %       nbins_y - the number of bins to place that y-coordinates in
        %       all_trajectories - a 2d matrix containing all coordinates of
        %       the joystick movements
        %       bin_edges_x - the values specifying the bin edges for the
        %       x-coordinates
        %       bin_edges_y - the values specifying the bin edges for the
        %       y-coordinates
        %       N - the output of binning the 2d joystick data using the
        %       histcounts function
        %       vectors_2d - a 2d cell array containing the vectors for
        %       each bin
        %
        %   Outputs:
        %       means_per_bin - a 2d matrix containing the mean x- and y-
        %       coordinates, mean x- and y- components of vectors, and mean
        %       angle for each bin
        %       weights_for_mean - a matrix containing the
        %       proportion of the number of vectors in each bin out of the 
        %       total number of vectors
        %       weights_for_std - a matrix containing the proportion of the
        %       number of vectors in each bin (containing 3 or more
        %       vectors) out of the total number of vectors

    num_visited_bins = sum(sum(N(:,:) ~= 0)); % the number of bins that the JS has passed through   
    
    means_per_bin = zeros(num_visited_bins, 5);
    means_per_bin_count = 1;

    num_vectors = sum(sum(N(:,:)));
    weights_for_mean = zeros(1, num_vectors);
    weights_for_mean_count = 1;
    num_vectors_over_three = sum(N(N(:,:) >= 3)); % number of vectors that belong to a bin containing 3 or more vectors
    weights_for_std = zeros(1, num_vectors_over_three);
    weights_for_std_count = 1;

    desired_length = 1;

    % for each bin, find mean values and determine weights associated with
    % each vector
    for row = 1:nbins_x - 1
        for col = 1:nbins_y - 1
            one_bin = vectors_2d{row, col};
            if ~isempty(one_bin)
                
                means_per_bin(means_per_bin_count, 1) = mean([bin_edges_x(row), bin_edges_x(row + 1)]); % find bin coordinate x
                means_per_bin(means_per_bin_count, 2) = mean([bin_edges_y(col), bin_edges_y(col + 1)]); % find bin coordinate y
                mean_x = mean(one_bin(:,1)); % find mean x component of vector
                mean_y = mean(one_bin(:,2)); % find mean y component of vector
                magnitude = norm([mean_x, mean_y]);

                means_per_bin(means_per_bin_count, 3) = mean_x * (desired_length / magnitude);
                means_per_bin(means_per_bin_count, 4) = mean_y * (desired_length / magnitude);
                means_per_bin(means_per_bin_count, 5) = atan2(mean_y, mean_x); % find angle
                means_per_bin_count = means_per_bin_count + 1;

                % determine the weighting of each vector based on how many
                % vectors there are in their corresponding bin
                for item = 1:size(one_bin, 1)
                    weights_for_mean(1, weights_for_mean_count) = N(row, col) / num_vectors;
                    if N(row, col) >= 3
                        weights_for_std(1, weights_for_std_count) = N(row, col) / num_vectors_over_three;
                    end
                end

            end
        end
    end
end

function [rad_mean_per_bin, deg_mean_per_bin, rad_std_per_bin, all_std] = unweighted_mean_std_per_bin(nbins_x, nbins_y, angles_for_mean, angles_for_std, N)
    % unweighted_mean_std_per_bin calculates unweighted circular mean and standard deviation for each bin
        %   Inputs:
        %       nbins_x - the number of bins to place that x-coordinates in
        %       nbins_y - the number of bins to place that y-coordinates in
        %       angles_for_mean - a 2d cell array containing all angles in
        %       their respective bins
        %       angles_for_std - a 2d cell array containing angles in the bins
        %       with at least 3 visits
        %       N - the output of binning the 2d joystick data using the
        %       histcounts function

        %   Outputs:
        %       rad_mean_per_bin - a 2d matrix containing the unweighted
        %       angular mean for each bin in radians
        %       deg_mean_per_bin - a 2d matrix containing the unweighted
        %       angular mean for each bin in degrees
        %       rad_std_per_bin - a 2d matrix containing the unweighted
        %       circular angular deviation for each bin containing 3 or
        %       more vectors, in radians

    rad_mean_per_bin = zeros(nbins_x - 1, nbins_y - 1); % 2D matrix to hold circular means
    rad_std_per_bin = zeros(nbins_x - 1, nbins_y - 1); % 2D matrix to hold standard deviations
    num_vectors_over_three = sum(sum(N(:,:) >= 3));
    all_std = zeros(1, num_vectors_over_three);
    count_all_std = 1;

    % for each bin, calculated unweighted circular mean and unweighted
    % angular deviation
    for row = 1:nbins_x - 1
        for col = 1:nbins_y - 1
            one_bin = angles_for_mean{row, col};
            if ~isempty(one_bin)
                rad_mean_per_bin(row, col) = unweighted_circ_mean(one_bin);
            end

            filtered_cell = angles_for_std{row, col};
            if ~isempty(filtered_cell)
                [st, ~] = unweighted_circ_std(filtered_cell, N(row, col));
                rad_std_per_bin(row, col) = st;
    
                % add standard deviation value to the 1D matrix counting them
                all_std(count_all_std) = st;
                count_all_std = count_all_std + 1;

            end
        end
    end
    
    % convert radians in rad_means_per_bin to degrees
    deg_mean_per_bin = zeros(nbins_x - 1, nbins_y - 1);
    for row = 1:nbins_x - 1
        for col = 1:nbins_y -1 
            deg_mean_per_bin(row, col) = rad_mean_per_bin(row, col) * (180/pi);
        end
    end
    
    % NaN the values of zero: bins where there are no vectors
    rad_mean_per_bin(rad_mean_per_bin == 0) = NaN;
    rad_std_per_bin(rad_std_per_bin == 0) = NaN;
    deg_mean_per_bin(deg_mean_per_bin == 0) = NaN;

end

function wrapped_angle = weighted_circ_mean(angles, weights_mean)
% weighted_circ_mean calculates weighted circular mean given angles
        %   Inputs:
        %       angles - one-dimensional matrix of angles
        %       weights_mean - one-dimensional matrix of the weights
        %       corresponding to each angle

        %   Outputs:
        %       wrapped_angle - one-dimensional matrix containing weighted
        %       circular means

    weighted_mean_angle = atan2(sum(weights_mean.*sin(angles)), sum(weights_mean.*cos(angles)));
    wrapped_angle = wrapTo2Pi(weighted_mean_angle);
end

function [std, std0] = weighted_circ_std(angles, weights_mean)
% weighted_circ_std calculates weighted circular angular deviation given
% angles, adapted from MATLAB Circular Statistics Toolbox
        %   Inputs:
        %       angles - one-dimensional matrix of angles
        %       weights_mean - one-dimensional matrix of the weights
        %       corresponding to each angle

        %   Outputs:
        %       std - one-dimensional matrix containing weighted
        %       circular angular deviations
        %       std0 - one-dimensional matrix containing weighted
        %       circular angular deviations, using a different formula to
        %       calculate standard deviation that the first way

    r = sum(weights_mean.*exp(1i*angles)); % weighted sum of angles
    r_length = abs(r)./sum(weights_mean); % length
    std = sqrt(2*(1-r_length)); % angular deviation
    std0 = sqrt(-2*log(r_length)); % circular standard deviation
end

function wrapped_angle = unweighted_circ_mean(angles)
% unweighted_circ_mean calculates weighted circular mean given angles
        %   Inputs:
        %       angles - one-dimensional matrix of angles

        %   Outputs:
        %       wrapped_angle - one-dimensional matrix containing weighted
        %       circular means

    mean_angle = atan2(mean(sin(angles)), mean(cos(angles)));
    wrapped_angle = wrapTo2Pi(mean_angle);
end

function [st, st0] = unweighted_circ_std(angles, num_angles)
% unweighted_circ_std calculates unweighted circular angular deviation given
% angles, adapted from MATLAB Circular Statistics Toolbox
        %   Inputs:
        %       angles - one-dimensional matrix of angles
        %       num_angles - the number of given angles

        %   Outputs:
        %       st - one-dimensional matrix containing weighted
        %       circular angular deviations
        %       st0 - one-dimensional matrix containing weighted
        %       circular angular deviations, using a different formula to
        %       calculate standard deviation that the first way

    r = sum(exp(1i*angles));
    r_length = abs(r)./num_angles;
    st = sqrt(2*(1-r_length)); % angular deviation
    st0 = sqrt(-2*log(r_length)); % circular standard deviation
end