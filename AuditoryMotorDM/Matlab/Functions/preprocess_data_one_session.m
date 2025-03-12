% script to prepocess data before we calculate trajectory metrics

function [CleanedData, unique_data, GoingTrajectories] = preprocess_data_one_session(session_data)
    % preprocess_data_one_session divides the raw data into trajectories,
    % removing coordinates that are likely not to be part of the mouse's
    % joystick movements during the trial (such as resting the joystick at
    % the origin)
        %   Inputs:
        %       session_data - one entry for one animal in the full
        %       dataset, representing all the joystcik data for that one
        %       session
        %
        %   Outputs:
        %       CleanedData - a cell array with 2 entries, each containing
        %       the individual trajectories for the push and pull
        %       directions
        %       normalized_session_data - contains the session data in one
        %       matrix, after removing repeated vectors and normalizing the
        %       data, see normalize_data function for more details

    CleanedData = cell(1, 2);
    GoingTrajectories = cell(1, 2);
    % remove repeated vectors
    unique_data = get_unique_vectors(session_data);

    % divide each trial into individual trajectories and assign each to
    % either being push or pull
    trajectories = cell(1, 1);
    push_pull_classes = cell(1, 1);
 
    [trajectories, noise_trajectories, push_pull_classes] = get_trajectories(unique_data, trajectories, push_pull_classes);
    [dir1_traj, dir2_traj] = find_push_pull(trajectories, push_pull_classes);
    CleanedData{1, 1} = dir1_traj;
    CleanedData{1, 2} = dir2_traj;    
    
    % identify going portions for both directions (useful for calculating
    % velocity later)
    [GoingTraj1, ~] = divide_vectors_dist(dir1_traj);
    [GoingTraj2, ~] = divide_vectors_dist(dir2_traj);
    GoingTrajectories{1, 1} = GoingTraj1;
    GoingTrajectories{1, 2} = GoingTraj2; 

end

function unique_vectors = get_unique_vectors(trajectory)
    % get_unique_vectors builds a matrix of the trajectory without repeated
    % vectors, and calculates the vectors and angle for each coordinate 
        %   Inputs:
        %       trajectory - a matrix containing raw joystick measurements,
        %       where column 1 is time, column 2 is the x- coordinate, and
        %       column 3 is the y-coordinate
        %
        %   Outputs:
        %       unique_vectors - a matrix containing the raw joystick
        %       measurements (that don't repeat coordinate pairs), and
        %       appends the vectors (difference between the current and
        %       next coordinates) in columns 4 and 5, and the angle using
        %       the vector components in column 6

    desired_length = 1;
    len = size(trajectory, 1);
    time = trajectory(:,1);

    % convert Arduino locations as milimeters - temporarily commenting out
    % until we know what the measurements are in ComineXYAlltimes
    % trajectory(:, 2) = trajectory(:, 2) * 0.5;
    % trajectory(:, 3) = trajectory(:, 3) * 0.5;

    X = trajectory(:, 2);
    Y = trajectory(:, 3);
    unique_vectors = zeros(len, 8);
    num_vectors = 0;
    count_pos_direction = 1;
    start = 1;
    
    % remove noise of small x-y coordinates that are Arduino noise
    % ensure that all coordinates are above 240
    for count = 1:len - 1
        if X(count) > -5 && Y(count) > -5 % X(count) > 240 && Y(count) > 240 %X(count) > 480 && Y(count) > 480
            start = count;
            break
        end
    end
    
    for count = start:len - 1
        % compute vector
        vector = [X(count + 1) - X(count), Y(count + 1) - Y(count)];    
        magnitude = norm(vector);
        % ensure we're counting a movement from one bin to another, not
        % counting the zero vector if joystick stays in the same bin over more than 1
        % timestep 
        if vector(1) ~= 0 || vector(2) ~= 0
            unique_vectors(count_pos_direction, 1) = time(count, 1); % save time
            unique_vectors(count_pos_direction, 2) = X(count, 1); % save x coordinate
            unique_vectors(count_pos_direction, 3) = Y(count, 1); %  save y coordinate
            unique_vectors(count_pos_direction, 4) = vector(1, 1) * (desired_length / magnitude); % x component of vector
            unique_vectors(count_pos_direction, 5) = vector(1, 2) * (desired_length / magnitude); % y component of vector
            unique_vectors(count_pos_direction, 6) = wrapTo2Pi(atan2(unique_vectors(count_pos_direction, 5), unique_vectors(count_pos_direction, 4))); % angle
            
            unique_vectors(count_pos_direction, 7) = X(count, 1); % save x coordinate
            unique_vectors(count_pos_direction, 8) = Y(count, 1); %  save y coordinate
            unique_vectors(count_pos_direction, 9) = vector(1, 1) * (desired_length / magnitude); % x component of vector
            unique_vectors(count_pos_direction, 10) = vector(1, 2) * (desired_length / magnitude); % y component of vector
            unique_vectors(count_pos_direction, 11) = wrapTo2Pi(atan2(unique_vectors(count_pos_direction, 5), unique_vectors(count_pos_direction, 4))); % angle
            
            count_pos_direction = count_pos_direction + 1;
            num_vectors = num_vectors + 1;
        end
        
    end
    unique_vectors = unique_vectors(1:num_vectors,:);

end

function trial_vectors = normalize_data(trial_vectors, median_x, median_y) %, std_x, std_y)
    % normalize_data uses the median and standard deviations for the x- and
    % y- coordinates to normalize the joystick coordinates in trial_vectors
        %   Inputs:
        %       trial_vectors - a matrix of one trial's joystick data,
        %       where the first column is time, the second column is the
        %       raw x value, the third column is the raw y value, the
        %       fourth and fifth columns are the x and y components of the vector at that
        %       coordinate, and the sixth column is the angle at which the
        %       joystick is being moved
        %       median_x - median x value of the full session 
        %       median_y - median y value of the full session
        %       std_x - standard deviation x value of the full session
        %       std_y - standard deviation y value of the full session
        %   Outputs:
        %       trial_vectors - modifies the input, adding columns 7 and 8:
        %       normalized x- and y- coordinatess, columns 9 and 10: x- and
        %       y- components of the vector calculated from the normalized
        %       vector, and column 11 the angle of this coordinate

    % calculate normalized x- and y- coordinates by subtracting median and
    % dividing by standard deviation
    for i = 1:size(trial_vectors, 1)
        x = trial_vectors(i, 2);
        y = trial_vectors(i, 3);
        trial_vectors(i, 7) = (x - median_x); % / std_x;
        trial_vectors(i, 8) = (y - median_y); % / std_y;
    end

    % calculate vector for the movement between each coordinate,
    % standardizing the length of each vector to be 1
    desired_length = 1;
    for i = 1:size(trial_vectors, 1) - 1
        X = trial_vectors(:, 7);
        Y = trial_vectors(:, 8);
        vector = [X(i + 1) - X(i), Y(i + 1) - Y(i)];    
        magnitude = norm(vector);
        trial_vectors(i, 9) = vector(1, 1) * (desired_length / magnitude); % x component of vector
        trial_vectors(i, 10) = vector(1, 2) * (desired_length / magnitude); % y component of vector
        trial_vectors(i, 11) = wrapTo2Pi(atan2(trial_vectors(i, 10), trial_vectors(i, 9))); % angle
    end

    % remove values like 10 or 50k+ that aren't part of the trajectory
    mask = trial_vectors(:,2) > 350 & trial_vectors(:,3) > 350 & trial_vectors(:,3) < 600 & trial_vectors(:,2) < 600;
    trial_vectors = trial_vectors(mask, :);
end

function [occurrences1, occurrences2] = count_occurrences(vectors, col1, col2)
    % count_occurrences counts how many times each x- and y-
    % coordinate appears in the set of joystick data, called vectors
        %   Inputs:
        %       vectors - normalized joystick data
        %       col1 - the first column in vectors to count occurrences for
        %       col2 - the second column in vectors to count occurrences for
        %   Outputs:
        %       occurrences1 - for the chosen data in col1, occurrences1 is 
        %       a matrix containing the joystick values in the first column, 
        %       and the number of times they occur in the second column
        %       occurrences2 - for the chosen data in col2, occurrences2 is 
        %       a matrix containing the joystick values in the first column, 
        %       and the number of times they occur in the second column

    [counts1, values1] = groupcounts(vectors(:,col1));
    occurrences1 = zeros(size(counts1, 1), 2);
    occurrences1(:,1) = values1;
    occurrences1(:,2) = counts1;

    [counts2, values2] = groupcounts(vectors(:,col2));
    occurrences2 = zeros(size(counts2, 1), 2);
    occurrences2(:,1) = values2;
    occurrences2(:,2) = counts2;
end

function bool = is_important(vector_info, freq_components, js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y)
    % is_important determines whether a single vector is part of a
    % trajectory
        %   Inputs:
        %       vector_info - one row of joystick data for this vector
        %       freq_components - the most frequent vector components found
        %       in the dataset
        %       js_center_lower_x - the lower bound of the joystick origin in the x-axis
        %       js_center_upper_x - the upper bound of the joystick origin in the x-axis
        %       js_center_lower_y - the lower bound of the joystick origin in the y-axis
        %       js_center_upper_y - the upper bound of the joystick origin in the y-axis
        %   Outputs:
        %       bool - boolean that will be true if we should keep the
        %       vector, false if it should not be considered

    abs_vector = [abs(vector_info(1, 9)), abs(vector_info(1, 10))];
    vector = [vector_info(1, 9), vector_info(1, 10)];
    
    % condition 1: vector components are in freq_components
    component_bool = sum(ismember(freq_components, abs_vector(1))) && sum(ismember(freq_components, abs_vector(2)));

    % condition 2: x position in the center of the workspace
    x_pos = vector_info(1, 7);
    x_bool = x_pos >= js_center_lower_x && x_pos <= js_center_upper_x;

    % condition 3: position y in the center of the workspace too
    y_pos = vector_info(1, 8);
    y_bool = y_pos >= js_center_lower_y && y_pos <= js_center_upper_y;

    % if all conditions are met, this vector should be removed
    if component_bool && x_bool && y_bool
        bool = false;
    % if one of the conditions aren't met, it's an important vector
    else
        bool = true;
    end
end

% get the upper bound of the trajectory to keep
function upper_bound = get_upper_bound(lower_bound, vectors, freq_components, js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y)
    % get_upper_bound determines the index of the last vector to be
    % included in the given trajectory
        %   Inputs:
        %       lower_bound - the index of the start of the trajectory
        %       vectors - the joystick measurements dataset for this trial
        %       freq_components - the most frequent vector components found
        %       in the dataset
        %       js_center_lower_x - the lower bound of the joystick origin in the x-axis
        %       js_center_upper_x - the upper bound of the joystick origin in the x-axis
        %       js_center_lower_y - the lower bound of the joystick origin in the y-axis
        %       js_center_upper_y - the upper bound of the joystick origin in the y-axis
        %   Outputs:
        %       upper_bound - index of the last vector to be included in 
        %       the given trajectory

    upper_bound = lower_bound + 1;
    while upper_bound < size(vectors, 1)
       curr_vector_info = vectors(upper_bound, :);
       if is_important(curr_vector_info, freq_components, js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y) % we want to save this vector
           upper_bound = upper_bound + 1;
       else
           upper_bound = upper_bound - 1; % the vector we're considering now is unwanted, so return the bound of the previous wanted vector
           break
       end
    end
end

% return the four most common components
function freq_components = find_freq_components(x_vec_occurrences, y_vec_occurrences)
    % freq_components the three most occurring vector components (after 
    % taking the absolute value of them) and there are typically four values in total:
    % 0, 1, and a vector pair that frequently occurs with the other vectors
    % only containing 0, 1, or -1 (this vector pair usually differs per
    % animal)
        %   Inputs:
        %       x_vec_occurrences - the number of times each x component
        %       occurs in the data
        %       y_vec_occurrences - the number of times each y component
        %       occurs in the data
        %   Outputs:
        %       freq_components - a sorted array of the most frequently
        %       occurring vectors (four total)

    [vals_x, indices_x] = maxk(x_vec_occurrences(:,2), 3);
    components_x = x_vec_occurrences(indices_x, 1);

    [vals_y, indices_y] = maxk(y_vec_occurrences(:,2), 3);
    components_y = y_vec_occurrences(indices_y, 1);

    components = [components_x; components_y];
    freq_components = unique(components, 'sorted');
end

function window_important = is_window_important(vectors, curr_row, window_len, freq_components, js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y)
    % is_window_important determines whether the current window of vectors
    % we're considering is part of a trajectory
        %   Inputs:
        %       vectors - joystick data of the full trial
        %       curr_row - the index in the full dataset of the first vector 
        %       in this window (to ensure the full window length is in the bounds of the dataset)
        %       freq_components - the most frequent vector components found
        %       in the dataset
        %       js_center_lower_x - the lower bound of the joystick origin in the x-axis
        %       js_center_upper_x - the upper bound of the joystick origin in the x-axis
        %       js_center_lower_y - the lower bound of the joystick origin in the y-axis
        %       js_center_upper_y - the upper bound of the joystick origin in the y-axis
        %   Outputs:
        %       window_important - boolean representing whether this window
        %       is part of a trajectory


    bool_mat = zeros(1, window_len);
    if window_len + curr_row > size(vectors, 1)
        window_len = size(vectors, 1) - curr_row;
    end
    for count = 0:window_len - 1
        bool_mat(count + 1) = is_important(vectors(curr_row + count, :), freq_components, js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y);
    end

    % if all the entries in bool_mat are 1, then the sum is equal to teh
    % window length and we can keep the coordinates as part of the
    % trajectory
    if sum(bool_mat) == window_len
        window_important = true;
    else
        window_important = false;
    end

end

function result_bool = is_purely_noise(trajectory, freq_components) %, trajectories_count, session_num)
    % is_purely_noise determines whether the given identified trajectory
    % is likely to be noise that was accidentally labeled as a trajectory
        %   Inputs:
        %       trajectory - the joystick data for this trajectory
        %       freq_components - the most frequent vector components found
        %       in the dataset
        %   Outputs:
        %       result_bool - boolean that is true if we should not
        %       consider this trajectory (as it is noise), and false if we should

    % check if there is too little displacement of the joystick to count as
    % being a trajectory
    max_x = max(trajectory(:,7));
    max_y = max(trajectory(:,8));

    min_x = min(trajectory(:,7));
    min_y = min(trajectory(:,8));

    if max_x - min_x < 0.8
        dist_bool_x = true;
    else
        dist_bool_x = false;
    end

    if max_y - min_y < 0.8
        dist_bool_y = true;
    else
        dist_bool_y = false;
    end


    % check to see if the trajectory has components that we
    % don't want, with a for loop
    vec_bool = false;
    num_vectors_freq_components = 0;
    for i = 1:size(trajectory, 1)
        vector = [trajectory(i, 9), trajectory(i, 10)];
        num_vectors_freq_components = num_vectors_freq_components + (sum(ismember(freq_components, abs(vector(1)))) && sum(ismember(freq_components, abs(vector(2)))));
    end

    % if more than 80% of vectors contain frequent components, then vector
    % bool is true
    if num_vectors_freq_components >= size(trajectory, 1) * 0.8
        vec_bool = true;
    end
    
    result_bool = dist_bool_x && dist_bool_y && vec_bool;
    
end

function class = classify_push_pull(trajectory, js_center_upper_x)
    % classify_push_pull returns whether a trajectory is a push or pull
    % trial
        %   Inputs:
        %       trajectory - the joystick data for this trajectory
        %       js_center_upper_x - the upperbound x-value of the origin of the joystick
        %   Outputs:
        %       class - the classification of this trial, either 1 for push
        %       and 2 for pull

    max_x = max(trajectory(:,7));
    if max_x > js_center_upper_x % we have direction 1 (push)
        class = 1;
    else % we have direction 2 (pull)
        class = 2;
    end
end

function [js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y] = get_js_origin(x_coord_occurrences, y_coord_occurrences)
    % get_js_origin calculates the x- and y- upper and lower bounds of
    % where the origin of the joystick is likely to be, based on the most
    % frequent x- and y- values (where the animal keeps the joystick when
    % not completing a trajectory in a trial)
        %   Inputs:
        %       x_coord_occurrences - the x values in the data and how many
        %       times each appears
        %       y_coord_occurrences - the y values in the data and how many
        %       times each appears
        %   Outputs:
        %       js_center_lower_x - the lower bound of the joystick origin in the x-axis
        %       js_center_upper_x - the upper bound of the joystick origin in the x-axis
        %       js_center_lower_y - the lower bound of the joystick origin in the y-axis
        %       js_center_upper_y - the upper bound of the joystick origin in the y-axis

    % find most frequent x value
    [val_x, index_x] = maxk(x_coord_occurrences(:,2), 1);
    if index_x == 1
        k=4;
    end

    % if the most frequent x value is the smallest x value, then it will be
    % the lower bound
    if index_x ~= 1
        js_center_lower_x = x_coord_occurrences(index_x - 1, 1);
    else
        js_center_lower_x = val_x; % should be x value, not index
    end

    if index_x ~= size (x_coord_occurrences, 1)
        js_center_upper_x = x_coord_occurrences(index_x + 1, 1);
    else
        js_center_upper_x = val_x;
    end

    [val_y, index_y] = maxk(y_coord_occurrences(:,2), 1);
    if index_y ~= 1
        js_center_lower_y = y_coord_occurrences(index_y - 1, 1);
    else
        js_center_lower_y = val_y;
    end

    if index_y ~= size (y_coord_occurrences, 1)
        js_center_upper_y = y_coord_occurrences(index_y + 1, 1);
    else
        js_center_upper_y = val_y;
    end


end

% fill the cell array with the wanted trajectories
function [trajectories, noise_trajectories, push_pull_classes] = get_trajectories(vectors, trajectories, push_pull_classes)
    % get_trajectories divides the raw data into trajectories
        %   Inputs:
        %       vectors - matrix of normalized data of joystick coordinates
        %       for one trial
        %       trajectories - cell array to store individual trajectories
        %       push_pull_classes - cell array to store whether a
        %       trajectory is push (1) or pull (2)
        %
        %   Outputs:
        %       trajectories - modification of input cell array
        %       noise_trajectories - cell array containing purely noise
        %       trajectories (where there are small displacements of the
        %       joystick that aren't a real trajectory)
        %       push_pull_classes - modification of input cell array

    noise_trajectories = cell(8,1);
    noise_trajectories_count = 1;

    % trajectories_count will indicate where we should save new
    % trajectories based on how many there are already in the trajectories
    % cell array
    if size(trajectories, 1) == 1
        trajectories_count = 1;
    else
        trajectories_count = size(trajectories, 1) + 1;
    end
    i = 1;

    % get how many times each x- and y- coordinate appears in the data
    [x_coord_occurrences, y_coord_occurrences] = count_occurrences(vectors, 7, 8);
    [x_vec_occurrences, y_vec_occurrences] = count_occurrences(abs(vectors), 9, 10);

    % get the four most frequently found components of the vectors in the
    % trial data
    freq_components = find_freq_components(x_vec_occurrences, y_vec_occurrences);

    % calculate where the origin of the joystick is likely to be, defining
    % a lower and upper bound on the x- and y- axes
    [js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y] = get_js_origin(x_coord_occurrences, y_coord_occurrences);
    
    % start searching for trajectories in the trial data by applying a
    % sliding window on the data and determining if that window contains a
    % trajectory. if it does, then find the upper bound of that trajectory 
    % and continue looking for more trajectories
    window_len = 15;
    while i < size(vectors, 1) - 2
       
       % determine if this window of coordinates contains the start of a
       % trajectory
       if is_window_important(vectors, i, window_len, freq_components, js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y)
           lower_bound = i;
           % find the upper bound (where the trajectory ends)
           upper_bound = get_upper_bound(lower_bound, vectors, freq_components, js_center_lower_x, js_center_upper_x, js_center_lower_y, js_center_upper_y);
           trajectory = vectors(lower_bound:upper_bound, :);

           % test whether the algorithm identified a window of data that's
           % likely to be purely noise
           if ~is_purely_noise(trajectory, freq_components)
               trajectories{trajectories_count, 1} = trajectory;
               push_pull_classes{trajectories_count, 1} = classify_push_pull(trajectory, js_center_upper_x);
               trajectories_count = trajectories_count + 1;
           else
               noise_trajectories{noise_trajectories_count, 1} = trajectory;
               noise_trajectories_count = noise_trajectories_count + 1;
           end
           i = upper_bound + 1;
       else % check the next window of vectors
           i = i + 1; 
       end
              
    end
    
end

function [dir1, dir2] = find_push_pull(trajectories, classes)
    % find_push_pull creates structures dividing the trajectories into
    % their respective classes (push or pull)
        %   Inputs:
        %       trajectories - cell array containing all identified
        %       trajectories
        %       classes - cell array containing the classification for each
        %       trajectory
        %
        %   Outputs:
        %       dir1 - cell array containing all push trajectories 
        %       dir2 - cell array containing all pull trajectories 

    dir1 = cell(1,1);
    dir1_count = 1;
    dir2 = cell(1,1);
    dir2_count = 1;
    for i = 1:size(trajectories, 1)
        if classes{i, 1} == 1
            dir1{dir1_count, 1} = trajectories{i, 1};
            dir1_count = dir1_count + 1;
        else
            dir2{dir2_count, 1} = trajectories{i, 1};
            dir2_count = dir2_count + 1;
        end
    end

end

function [GoingTraj, ComingTraj] = divide_vectors_dist(one_session_trajectories) % given target vectors
% divide_vectors_dist divides the given trajectories into pieces that are
% considered as the "going" portion to the maximum point of displacement,
% and the "coming" portion returning to the joystick origin
    %   Inputs:
        %       one_session_trajectories - the trajectory to divide
        %
        %   Outputs:
        %       GoingTraj - cell array containing all going trajectories 
        %       ComingTraj - cell array containing all coming trajectories 

    ComingTraj = cell(size(one_session_trajectories, 1), 1);
    GoingTraj = cell(size(one_session_trajectories, 1), 1);

    for trajectory_index = 1:size(one_session_trajectories, 1)
        trajectory = one_session_trajectories{trajectory_index, 1};
        if ~isempty(trajectory)
            first = [trajectory(1, 7), trajectory(1, 8)];
            all_x = trajectory(:, 7);
            all_y = trajectory(:, 8);
            distances = sqrt((all_x - first(1)).^2 + (all_y - first(2)).^2); % find euclidean distance of all points from the first point
            [max_dist, max_index] = max(distances);
            GoingTraj{trajectory_index, 1} = trajectory(1:max_index,:);
            ComingTraj{trajectory_index, 1} = trajectory(max_index + 1:size(trajectory, 1), :);
        end
        
    end

end
