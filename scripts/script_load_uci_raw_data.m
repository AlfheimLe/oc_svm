subject = 5;
activity = 0;   % set to 0 for all activities by subject.
columns = [1 2];
limit_range = 10000;

data_file_path = 'data/uci/matlab_xyz_train.txt';

% check wheter to prefetch data
if ~exist('data', 'var')
    if exist( data_file_path, 'file')
        data = csvread(data_file_path);
    else
        data_x        = csvread('data/uci/body_gyro_x_train.txt');
        data_y        = csvread('data/uci/body_gyro_y_train.txt');
        data_z        = csvread('data/uci/body_gyro_z_train.txt');


        % Filter every even row, because it is double due to sliding window
        data_x        = data_x(1:2:end,:);
        data_y        = data_y(1:2:end,:);
        data_z        = data_z(1:2:end,:);

        data_x = reshape(data_x', [], 1);
        data_y = reshape(data_y', [], 1);
        data_z = reshape(data_z', [], 1);

        data   = [data_x data_y data_z];

        csvwrite(data_file_path, data);
    end
end

data = data(:,[1 2]);

data_subject  = csvread('data/uci/subject_train.txt');
data_activity = csvread('data/uci/y_train.txt');

labels        = {'WALKING', 'WALKING_UPSTAIRS', 'WALKING_DOWNSTAIRS', 'SITTING', 'STANDING', 'LAYING'};

data_subject  = data_subject(1:2:end,:);
data_activity = data_activity(1:2:end,:);

rows_of_subject = find(data_subject == subject);

%%% activity filter
if activity
    rows_of_subject_and_activity = find(data_activity(rows_of_subject, :) == activity);
    rows_of_subject = rows_of_subject_and_activity;
end
%%%





max_end = min( (rows_of_subject(1) - 1) * 128 + limit_range, rows_of_subject(end) * 128 - 1);
max_end = rows_of_subject(end) * 128 - 1;

expanded_rows_for_subject = (rows_of_subject(1)) * 128 : max_end;

data_for_subject = data(expanded_rows_for_subject, :);

if activity
    activity_for_subject = ones(length(expanded_rows_for_subject), 1) * activity;
else
    activity_for_subject = data_activity(rows_of_subject, :);

    for i = 1 : length(activity_for_subject)
        activity = activity_for_subject(i);
        activity_for_subject(i,1:128) = ones(128, 1) * activity;
    end

    activity_for_subject = reshape(activity_for_subject', 1, []);
end


change_points = [];
prev = activity_for_subject(1);
for i = 1 : length(activity_for_subject)
    if activity_for_subject(i) ~= prev
        change_points(end+1) = i;
    end
    prev = activity_for_subject(i);
end

range = 1:length(data_for_subject);

size(range)
size(data_for_subject)

range = 1:length(data_for_subject)/2;
size(range)
data_for_subject = data_for_subject(range,:);

figure(5);
clf;

size(range)
size(data_for_subject)

[ax, h1, h2] = plotyy(range, data_for_subject, range, activity_for_subject(range) );
set(ax(1), 'YLim', [floor(min(min(data(range,:))) * 100)/100 ceil(max(max(data(range,:))) * 100)/100]);
% draw_vertical_lines(change_points, 'r');

set(ax(2), 'YLim', [1 6], 'YTick', 1:6, 'YTickLabel', labels );
set(h2, 'LineWidth', 2);



