
function [bin_edges_x, bin_edges_y, nbins_x, nbins_y] = create_bin_edges(InputSessions, cleaned_data_col)
% create_bin_edges calculates the intervals of each bin for the x- and y-
% coordinates, using all animals' data for both directions so that the workspace is
% standardized across them
        %   Inputs:
        %       AllSessionsAllAnimals - contains all joystick data for both
        %       directions for all animals
        %       nbins_x - the number of bins to place that x-coordinates in
        %       nbins_y - the number of bins to place that y-coordinates in
        %       cleaned_data_col - an integer specifying in which column to
        %       find the cleaned trajectory data in the cell array of all
        %       animal data (AllSessionsAllAnimals)

        %   Outputs:
        %       bin_edges_x - the values specifying the bin edges for the
        %       x-coordinates
        %       bin_edges_y - the values specifying the bin edges for the
        %       y-coordinates

    direction_col1 = 1;
    [animal_min_x1, animal_min_y1, animal_max_x1, animal_max_y1] = get_all_animal_mins_maxs(InputSessions, cleaned_data_col, direction_col1);
    direction_col2 = 2;
    [animal_min_x2, animal_min_y2, animal_max_x2, animal_max_y2] = get_all_animal_mins_maxs(InputSessions, cleaned_data_col, direction_col2);

    % find min x and y coordinate values to use for creating bin edges
    % bin edges will be evenly spaced intervals beginning from the
    % min and max x and y values
    min_x = min([animal_min_x1, animal_min_x2]);
    min_y = min([animal_min_y1, animal_min_y2]);
    max_x = max([animal_max_x1, animal_max_x2]);
    max_y = max([animal_max_y1,animal_max_y2]);


    % specify desired bin length and determine number of bins based on that
    bin_length_x = 0.25;
    nbins_x = ceil((max_x - min_x) / bin_length_x);
    bin_length_y = 0.25;
    nbins_y = ceil((max_y - min_y) / bin_length_y);
    
    bin_edges_x = linspace(min_x, max_x, nbins_x);
    bin_edges_y = linspace(min_y, max_y, nbins_y);

end


function [min_x, min_y, max_x, max_y] = get_all_animal_mins_maxs(AllSessionsAllAnimals, cleaned_data_col, direction_col)
% get_all_animal_mins_maxs finds the minimum and maximum x- and y-
% coordinates for all animals in one push or pull direction
        %   Inputs:
        %       AllSessionsAllAnimals - contains all joystick data for both
        %       directions for all animals
        %       cleaned_data_col - an integer specifying in which column to
        %       find the cleaned trajectory data in the cell array of all
        %       animal data (AllSessionsAllAnimals)
        %       direction_col - an integer specifying which direction
        %       (push/pull) to compute bin edges for

        %   Outputs:
        %       min_x - minimum x-value for all animals in one direction
        %       min_y - minimum y-value for all animals in one direction
        %       max_x - maximum x-value for all animals in one direction
        %       max_y - maximum y-value for all animals in one direction

    % find the mins and max's of each session
    num_animals = size(AllSessionsAllAnimals, 1);
    animal_min_x = zeros(num_animals, 1);
    animal_min_y = zeros(num_animals, 1);
    animal_max_x = zeros(num_animals, 1);
    animal_max_y = zeros(num_animals, 1);
    num_saved_animals = 0;

    for animal = 1:num_animals
        disp(animal)
        one_animal_all_clean_data = AllSessionsAllAnimals{animal, cleaned_data_col};
        % ensure that there is an animal saved here
        if ~isempty(one_animal_all_clean_data)
            one_dir_data = one_animal_all_clean_data(:, direction_col);
            one_animal_list = find_one_animal_mins_maxs(one_dir_data);

            % ensure that there is trajectory data for this direction
            if ~isempty(one_animal_list)
                num_saved_animals = num_saved_animals + 1;
                animal_min_x(num_saved_animals, 1) = one_animal_list(1);
                animal_min_y(num_saved_animals, 1) = one_animal_list(2);
                animal_max_x(num_saved_animals, 1) = one_animal_list(3);
                animal_max_y(num_saved_animals, 1) = one_animal_list(4);
            end
        end
        
    end

    
    % if we didn't fill array because not all animals have trajectories in
    % this direction, then only consider the nonzero array entries
    animal_min_x = animal_min_x(1:num_saved_animals, 1);
    animal_min_y = animal_min_y(1:num_saved_animals, 1);
    animal_max_x = animal_max_x(1:num_saved_animals, 1);
    animal_max_y = animal_max_y(1:num_saved_animals, 1);

    min_x = min(animal_min_x);
    min_y = min(animal_min_y);
    max_x = max(animal_max_x);
    max_y = max(animal_max_y);

end

function return_list = find_one_animal_mins_maxs(one_animal_data)
% find_one_animal_mins_maxs calculates the minimum and maximum values for
% all x- and y- coordinates, for one animal's data
        %   Inputs:
        %       one_animal_data - contains all joystick data for all
        %       sessions for one animal

        %   Outputs:
        %       return_list - a matrix of four values, containing the
        %       mininmum x-coordinate, minimum y-coordinate, maximum
        %       x-coordinate, and maximum y-coordinate

    num_sessions = size(one_animal_data, 1);
    all_min_x = zeros(num_sessions, 1);
    all_min_y = zeros(num_sessions, 1);
    all_max_x = zeros(num_sessions, 1);
    all_max_y = zeros(num_sessions, 1);
    session_count = 1;

    % for each session, save the four min/max x/y values
    for i = 1:num_sessions
        session_data = one_animal_data{i, 1};
        mins = cellfun(@min, session_data, 'UniformOutput', false); % minimum values for each column of session_data
        num_empty = sum(sum(cellfun(@isempty, mins)));

        if num_empty ~= size(session_data, 1) * size(session_data, 2)
            mins_mat = cell2mat(mins);
            
            min_x = min(mins_mat(:, 7));
            all_min_x(session_count, 1) = min_x;
            min_y = min(mins_mat(:, 8));
            all_min_y(session_count, 1) = min_y;
    
            maxs = cellfun(@max, session_data, 'UniformOutput', false); % maximum values for each column of session_data
            maxs_mat = cell2mat(maxs);
            max_x = max(maxs_mat(:, 7));
            all_max_x(session_count, 1) = max_x;
            max_y = max(maxs_mat(:, 8));
            all_max_y(session_count, 1) = max_y;
            session_count = session_count + 1;
        end
    end
    session_count = session_count - 1;

    % if we didn't fill the matrices, then only consider the nonzero array entries
    all_min_x = all_min_x(1:session_count, 1);
    all_min_y = all_min_y(1:session_count, 1);
    all_max_x = all_max_x(1:session_count, 1);
    all_max_y = all_max_y(1:session_count, 1);

    return_list = [min(all_min_x), min(all_min_y), max(all_max_x), max(all_max_y)];
end