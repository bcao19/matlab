function data = get_data(signal_name, shot, varargin)

    
    % required parametes: signal_name, shot
    % optional parameter: data_tree
    % download data from east database, default database is 'east_1'
    % timerange is the range of time for download data
    % mwin is the time width for median filter, unit is ms
    % swin is the time width for smooth window, unit is ms
    % dedrift is decreased zero drif by the data before zero time
    % save_data for save the data as .csv file
    % origin is for no pressure transfer, any input 1
    % plot_data for plot data

    % if the signal name for vaccum pressure, transfer to H2 pressure (K=2.4)
    % if the signal name for puff pressure, transfer to pressure (APR262)
  
    data = 0;

    if nargin < 2
        disp('There is no enough parameters input');
        return
    end

    defaultdata_tree = 'east_1';
    excepteddata_tree = {'pcs_east', 'east', 'east_1', 'efitrt_east', 'eng_tree', 'analysis', ...
                         'fscope_east', 'pf_east'};
    defaulttimerange = 0;
    defaultmwin = 0;
    defaultswin = 0;
    defaultdedrift = 0;
    defaultsave_data = '0';
    defaultorigin = 0;
    defaultplot_data = [0, 0];

    p = inputParser;
    validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x >= 0);

    addRequired(p, 'signal_name', @ischar);
    addRequired(p, 'shot', validScalarPosNum);
    addOptional(p, 'data_tree', defaultdata_tree, @(x) any(validatestring(x, excepteddata_tree)));
    addParameter(p, 'timerange', defaulttimerange, @(x) isnumeric(x) && (max(x) > 0));
    addParameter(p, 'mwin', defaultmwin, validScalarPosNum);
    addParameter(p, 'swin', defaultswin, validScalarPosNum);
    addParameter(p, 'dedrift', defaultdedrift, validScalarPosNum);
    addParameter(p, 'save_data', defaultsave_data, @ischar);
    addParameter(p, 'origin', defaultorigin, @(x) x==1);
    addParameter(p, 'plot_data', defaultorigin);

   

    parse(p, signal_name, shot, varargin{:});

    shot = p.Results.shot;
    signal_name = p.Results.signal_name;
    data_tree = p.Results.data_tree;
    timerange = p.Results.timerange;
    mwin = p.Results.mwin;
    swin = p.Results.swin;
    dedrift = p.Results.dedrift;
    save_data = p.Results.save_data;
    origin = p.Results.origin;
    plot_data = p.Results.plot_data;

 
  
    shot_num = num2str(shot);

  
    mdsconnect('202.127.204.12');
  
    signal_time = ['dim_of(\', signal_name, ')'];
    signal_name = ['\', signal_name];
  
  
    mdsopen(data_tree, shot);
  
    a = mdsvalue(signal_name);
    a_time = mdsvalue(signal_time);
    mdsclose;
  
    if length(a) ~= length(a_time) 
        a = 0;
        a_time = 0;
    end
  

  
  
    %data = [a_time, a];
  
    %reduce zero drift
    if dedrift ~= 0
        ans = 0;
        index = find(a_time < -2);
        if length(index) < 10
            index = where(a_time < 0);
        end
        if length(index) > 10
            ans = mean(a(index));
        end
        a = a-ans;
    end
  
  
    %median filter
    if mwin ~= 0
        dt = a_time(3)-a_time(2);
        dt = dt*1000;
        mwin = floor(mwin/dt);
        a = medfilt1(a, mwin);
    end
  

    %smooth
    if swin ~=0
        dt = a_time(3)-a_time(2);
        dt = dt*1000;
        swin = floor(swin/dt);
        a = smooth(a, swin);
    end
  
  
  %if keyword_set(denoise) then begin
  % ans = reform(data(1, *))
  % data(1, *) = wv_denoise(ans)
  %endif
    

    % transfer to pressure
    exceptedPKR251 = {'\G101', '\G107', '\G105', '\G106', '\G109', '\G203', '\G401'};
    index = find(strcmp(signal_name, exceptedPKR251));
    if length(index) > 0 && origin ~= 1
        K = 2.4;
        a = K*10.^(1.667*a-9.333);
    end
    
    exceptedAPR262 = {'\JHG1', '\JHG2', '\JHG3', '\JHG4', '\JHG5', '\JHG6', '\OUG1',...
                      '\ODG1', '\DHG1', '\HDG1', '\KHG1', '\CDG1' };
    index = find(strcmp(signal_name, exceptedAPR262));
    if length(index) > 0 && origin ~= 1
        a = (a-1)/8*2e5;
    end
    



  
    %cut data into timerange
    if max(timerange) > 0
        if max(timerange) == min(timerange)
            disp('error time range !');
            return
        end
        index = find(a_time >= min(timerange) && a_time <= max(timerange));
        a_time = a_time(index);
        a = a(index);
    end


    % plot the data

    if ~isempty(setdiff(plot_data, defaultplot_data))
        plot(a_time, a);
        if length(plot_data) == 2
            ylim(plot_data);
        end
        if length(plot_data) == 4
            xlim(plot_data(1:2));
            ylim(plot_data(3:4));
        end
        if length(plot_data) == 3
            xlim(plot_data(1:2));
        end
    end

  
    data = [a_time, a]; 

    %save data to .xls file
    if ~strcmp(save_data, defaultsave_data)
        save_data = ['/home/ASIPP/caobin/data/', save_data, '.csv'];
        xlswrite(save_data, data);
        disp(['save the data at: ', save_data]);
    end
  
    
    return
  
end