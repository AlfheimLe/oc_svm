function [change_points, ratios, handles, handles_fig_5] = calculate_changepoints( properties, fields, method, closeness, outlier_fraction, varargin )
%CALCULATE_CHANGEPOINTS Summary of this function goes here
%   Detailed explanation goes here

    if nargin < 2; fields = {'thresholds'}; end
    if nargin < 3; method = 'threshold';    end
    if nargin < 4; closeness = 10;          end
    if nargin < 5; outlier_fraction = 0.1;  end % The fraction of ourliers, should be the same as the C parameter used for SVDD
    
%     change_points = data_values(change_points, 1);
%     ratios = data_values(ratios(:,1), 1);
%     change_points = unique(change_points(:,2));
%     ratios = unique(ratios(:,2

    if strcmp(class(fields), 'char')
        fields = {fields};
    end
    
    switch method
        
        case 'threshold'
            disp('- Using thresholding method');
            
            high = varargin{1};
            low  = varargin{2};
                
            if length(fields) == 1
                disp(['- For a single field ' fields{1}]);
                [change_points, ratios, shadow_points] = thresholding_single(properties, fields, high, low, outlier_fraction);
                
%             else
%                 disp(['- For multiple fields ' cell2mat(fields) ]);
%                 [change_points, ratios, shadow_points] = thresholding_multiple(properties, fields, high, low, outlier_fraction);
            end
            
        otherwise
            disp('---')
            disp('Error: Unsupported change detection method.');
            disp('Supported methods include:');
            disp('   - threshold (high, low)');
    end
    
    % Merge change points
    change_points
    change_points_merged = merge_changepoints(change_points, closeness);
%     change_points_merged = change_points(:,2);
            
    ratios;
    
    % Plot ratios and changepoint in new figure
    sfigure(5); clf;
    
    % Set plot width and height
%     screenSize = get(0,'ScreenSize');
%     plot_width  = screenSize(3);
%     plot_height = screenSize(4) / 4;
%     set(gcf,'Position',[0 (plot_height * 1.3) plot_width plot_height]);
    
    handle_plot = plot(ratios(:,1), ratios(:,2));
    
    handles_vertical        = draw_vertical_lines(change_points_merged, 'r');
%     handles_vertical_shadow = draw_vertical_lines(shadow_points(:,2), 'r', 1, '--');
%     handles_vertical        = horzcat(handles_vertical', handles_vertical_shadow')';
    
    handles_horizontal = draw_horizontal_lines([high low], 'r');
    
    %     set(gca, 'XTick', 0:roundn(length(ratios(:,1))/50, 1):ratios(end,1));
    set(gca, 'XTick', 0:2:ratios(end,1));
    set(gca, 'YTick', 0:0.2:max(ratios(:,2)));
    xlim([0 ratios(end,1)]);
    
    % Add empty axis, to create equal spacing with other plots
%     addaxis([],[]);
%     addaxis([],[]);
%     addaxis([],[]);
    
    % Plot change points in original data figure
    sfigure(4);
    handles = draw_vertical_lines(change_points_merged, 'b');
    
    handles_fig_5 = horzcat(handle_plot, handles_vertical', handles_horizontal');
    xlim([0 ratios(end,1)]);
    change_points = change_points_merged;
    set(gca, 'XTick', 0:2:ratios(end,1));
end


function [change_points, ratios, shadow_points] = thresholding_single(properties, field, high, low, outlier_fraction)
    % Use the thresholding method. Sum all the ratios of the data series
    % indicated by the fields.
    
    column = 3;     % Assume first column is time, second index, third has value

    data_values = cell2mat(values(properties, field));
    
    if nargin < 3; high = 3;  end
    if nargin < 4; low = 0.2; end
    
    % Determine block sizes
    block_size = data_values(1,1) - data_values(3,1) + data_values(2,1) - 1;
    
    change_points = [1 1 0]; %zeros(size(data_values),2);
    shadow_points = [1 1 0];
    ratios = zeros(size(data_values, 1),2);
    
    block_size
    outlier_fraction
    
    for i = 2 : length(data_values)
        
        time = data_values(i, 1);
        
        series = data_values(change_points(end,1):i,column);
        r = ratio(series);
        ratios(i,:) = [time r];
        
        % Skip if last change point was within a certain range
%         if (i - change_points(end, 1)) < 10 
%             continue;
%         end
        
        if r > high
            disp(['High treshold at i: ' num2str(i) ', time: ' num2str(time) ', value r:' num2str(r) ])
            change_points(end+1,:) = [i time 0];
        end
        
        % TODO: check block-compenstation for low values
        
        if r < low
            disp(['Low treshold at i: ' num2str(i) ', time: ' num2str(time) ', value r:' num2str(r) ])
%             disp(['Corrected to time ' num2str(time-block_size+outlier_fraction*block_size) ])
%             change_points(end+1,:) = [i time-block_size+outlier_fraction*block_size 1];
            change_points(end+1,:) = [i time 1];
            shadow_points(end+1,:) = [i time 1];
            
            % NOTE: compensate for block size
            % TODO: also, a fraction C of block size need to be added
            % again, because those datapoints were first regarded as
            % outliers.
        end
    end
    change_points = sortrows(change_points, 2);
    
    [C, ai, ci] = unique(change_points(:,2), 'stable');
    change_points = change_points(ai,:);
    
    change_points;
end