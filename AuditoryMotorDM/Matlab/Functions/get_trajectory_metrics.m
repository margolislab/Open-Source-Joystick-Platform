% script for preprocessing joystick data and gathering trajectory metrics

function [num_visited_bins, two_d_workspace, mean_angular_devs, velocities, tortuosities, avg_tortuosity] = get_trajectory_metrics(ComineXYAlltimes)
% get_trajectory_metrics calls functions to preprocess data by removing repeated vectors, 
% dividing the session into individual trajectories, and finding the portions of the
% trajectories for the going direction. It also calls the function to
% compute the trajectory metrics
        %   Inputs:
        %       ComineXYAlltimes - a matrix with three columns: time,
        %       x-value, and y-value of the joystick

        %   Outputs:
        %       num_visited_bins - the number of bins visited in the
        %       workspace
        %       two_d_workspace - a two-dimensional matrix containing the
        %       number of visits per bin
        %       mean_angular_devs - the mean angular deviation for each bin
        %       contained in a two-dimensional matrix
        %       velocities - a vector containing the velocity for each
        %       trajectory
        %       tortuosities -a vector containing the tortuosities for each
        %       trajectory
        %       avg_tortuosity - the mean value of the tortuosities vector

    [CleanedData, all_normalized_data, GoingTrajectories] = preprocess_data_one_session(ComineXYAlltimes);
    AllSessions = cell(1,1);
    AllSessions{1, 1} = CleanedData;

    % create bin edges
    cleaned_data_col = 1;
    [bin_edges_x, bin_edges_y, nbins_x, nbins_y] = create_bin_edges(AllSessions, cleaned_data_col);

    % trajectory metrics
    metrics = trajectory_metrics_sept(CleanedData{1,1}, GoingTrajectories{1,1}, bin_edges_x, bin_edges_y, nbins_x, nbins_y);
    num_visited_bins = metrics.num_visited_bins;
    two_d_workspace = metrics.N;

    mean_angular_devs = metrics.rad_std_per_bin;
    velocities = metrics.velocities_start_to_max;
    tortuosities = metrics.tortuosities;
    avg_tortuosity = metrics.avg_tortuosity;
    

end