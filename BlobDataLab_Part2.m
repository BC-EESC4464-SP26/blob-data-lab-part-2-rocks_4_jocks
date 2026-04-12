%% 0. Read in files with WOA decadal mean monthly climatological temperature
% I have written the code for this part for you, but I encourage you to
% read it to see what I have done - and you will also need to download the
% original data files so that the code will run.
% ***For this part to work, you will need to download and add to your path the
% original data files in the folder at: https://tinyurl.com/NEPacificWOAdata


% path = addpath('C:\Users\nuhin\git\blob-data-lab-part-2-rocks_4_jocks\WOA decadal average data');
% path2 = addpath(genpath('C:\Users\nuhin\git\blob-data-lab-part-1-rocks_4_jocks\OOI_StationPapa_FLMB_CTDdata_BlobDataLab'));

% addpath(genpath('/Users/ilanajacobs/Palevsky_Lab/Classes/EESC6664/blob-data-lab-part-1-rocks_4_jocks/blob-data-lab-part-2-rocks_4_jocks'))
% addpath(genpath('/Users/ilanajacobs/Palevsky_Lab/Classes/EESC6664/blob-data-lab-part-1-rocks_4_jocks/blob-data-lab-part-2-rocks_4_jocks/WOA decadal average data'))

thisDir   = fileparts(mfilename('fullpath'));
part1Root = 'C:\Users\nuhin\git\blob-data-lab-part-1-rocks_4_jocks';
ooiDir    = fullfile(part1Root, 'OOI_StationPapa_FLMB_CTDdata_BlobDataLab');
woaDir    = fullfile(thisDir, 'WOA decadal average data');
addpath(thisDir);
if isfolder(woaDir), addpath(woaDir); end
if isfolder(ooiDir), addpath(ooiDir); end
addpath(genpath(part1Root));

set(0, 'DefaultFigureVisible', 'off');

% For your reference, the files provided at the link above were downloaded from
% https://data.nodc.noaa.gov/thredds/catalog/nodc/archive/data/0114815/public/temperature/netcdf/decav/1.00/catalog.html
% and subset to only include the North Pacific region

if ~exist('allData', 'var')
    allData = buildOOIAllData(ooiDir);
end

for i = 1:12
    if i < 10
        filename = ['woa13_decav_t0' num2str(i) '_01_NEPac.nc'];
    else
        filename = ['woa13_decav_t' num2str(i) '_01_NEPac.nc'];
    end
    if i == 1
        woa.T = ncread(filename,'t_an');
        woa.depth = ncread(filename,'depth');
        woa.lat = ncread(filename,'lat');
        woa.lon = ncread(filename,'lon');
    else
        woa.T(:,:,:,i) = ncread(filename,'t_an');
    end
end

%% 1. Extract the World Ocean Atlas (WOA) climatological mean data at Ocean Station Papa
%Use the "min" function to find the indices within the woa data for the
%latitude and longitude that match the location of the OOI flanking mooring B
%(the code I wrote later will only work if you name these indices "indlon"
%and "indlat")
% --> 
% -->
papa_lon = -144.9;
papa_lat =   50.1;
papa_depth = 30;     

[~, indlon]   = min(abs(woa.lon   - papa_lon));
[~, indlat]   = min(abs(woa.lat   - papa_lat));
[~, inddepth] = min(abs(woa.depth - papa_depth));

% 12-month climatological cycle at Station Papa
woa_papa = squeeze(woa.T(indlon, indlat, inddepth, :));   % 12×1



%% 2a. Create an extended version of the World Ocean Atlas 12-month climatology
% repeated over the entire timeline of which the OOI mooring data were collected
%I have done this step for you: it creates a timeline that you will use
%below to plot the WOA climatology, extending the 12-month seasonal cycle
% to cover the period from the beginning of 2013 through the end of March
% 2020

woa_time = [datenum(2013,1:12,15) datenum(2014,1:12,15)...
    datenum(2015,1:12,15) datenum(2016,1:12,15) datenum(2017,1:12,15)...
    datenum(2018,1:12,15) datenum(2019,1:12,15) datenum(2020,1:3,15)];
woa_papa_rep = [repmat(woa_papa,7,1); woa_papa(1:3)];

%% 2b. Plot the WOA temperature time series along with the OOI temperature time series from Part 1
% -->


all_time_clean = [];
all_temp_clean = [];

for i = 1:length(allData)
    t    = allData(i).time;
    temp = allData(i).temperature;
    idx  = allData(i).good_idx;    % only plot the cleaned points from part 1      
    all_time_clean = [all_time_clean; t(idx)];
    all_temp_clean = [all_temp_clean; temp(idx)];
end

all_time_raw = [];
all_temp_raw = [];

for i = 1:length(allData)
    all_time_raw = [all_time_raw; allData(i).time];
    all_temp_raw = [all_temp_raw; allData(i).temperature];
end

ooi_time_raw_dt = datetime(all_time_raw, 'ConvertFrom', 'datenum');

woa_time_dt = datetime(woa_time, 'ConvertFrom', 'datenum');
ooi_time_dt = datetime(all_time_clean, 'ConvertFrom', 'datenum');

figure(1)
clf
plot(ooi_time_raw_dt, all_temp_raw, 'k.', 'MarkerSize', 2, 'DisplayName', 'OOI Raw Data')
hold on
plot(woa_time_dt, woa_papa_rep, 'b-', 'LineWidth', 3, 'DisplayName', 'WOA Climatology')
plot(ooi_time_dt, all_temp_clean, 'r.', 'MarkerSize', 8, 'DisplayName', 'OOI Cleaned Data')
xlabel('Time')
ylabel('Temperature (°C)')
title('WOA Climatology vs. OOI Observations at Ocean Station Papa')
legend('Location', 'best')
grid on
hold off


%% 3a. Interpolate WOA data onto the times where the OOI data were collected at Ocean Station Papa
% Use the "interp1" function to interplate the World Ocean Atlas
% temperature data over the extended timeline (woa_papa_rep) from the
% original extended monthly data (woa_time) onto the times when the OOI
% data were collected (from your Part 1 analysis)
% -->

woa_interp = interp1(woa_time, woa_papa_rep, all_time_clean, 'linear');

%% 3b. Calculate the temperature anomaly as the difference between the OOI mooring
% observations (using the smoothed data during good intervals) and the
% climatological data from the World Ocean Atlas interpolated onto those
% same timepoints
% -->

temp_anomaly = all_temp_clean - woa_interp;
%% 4. Plot the time series of the T anomaly you have now calculated by combining the WOA and OOI data

figure(4)
clf
plot(ooi_time_dt, temp_anomaly, 'r.', 'MarkerSize', 4, 'DisplayName', 'Mooring anomaly (OOI - WOA)')
yline(0, 'k-', 'LineWidth', 1.5)
xlabel('Time')
ylabel('Temperature Anomaly (°C)')
title('Temperature Anomaly at Ocean Station Papa (OOI - WOA Climatology)')
grid on

%% 5. Now bring in the satellite data observed at Ocean Station Papa

%5a. Convert satellite time to MATLAB timestamp (following the same approach
%as in Part 1 step 2, where you will need to check the units on the satellite data
%timestamp and use the datenum function to make the conversion)
% -->

filename = fullfile(thisDir, 'jplMURSST41anommday_72e0_376a_802d.nc');
assert(isfile(filename), 'Missing satellite file: %s', filename);

%_CoordinateAxisType = 'Time'
                       % actual_range        = [1358294400  1752624000]
                       % axis                = 'T'
                       % ioos_category       = 'Time'
                       % long_name           = 'Centered Time'
                       % standard_name       = 'time'
                       % time_origin         = '01-JAN-1970 00:00:00'
                       % units               = 'seconds since 1970-01-01T00:00:00Z'

% ncdisp(filename);


% Read time variable from NetCDF file
time_sat = ncread(filename, 'time');

% Convert satellite time to MATLAB timestamp
% Units: seconds since 1970-01-01T00:00:00Z
timeFixed = datenum(datetime(double(time_sat), 'ConvertFrom', 'posixtime'));

timeCheck = datestr(timeFixed(1:5));
disp(timeCheck);

%5b. In order to extract the satellite SSTanom data from the grid cell
%nearest to OSP, calculate the indices of the longitude and latitude in the
%satellite data grid nearest to the latitude and longitude of Ocean Station
%Papa (as you did for the WOA data in Step 1 above)
% -->
% -->

lat_sat = double(ncread(filename, 'latitude'));
lon_sat = double(ncread(filename, 'longitude'));


% Find indices nearest to OSP
[~, lat_idx] = min(abs(lat_sat - papa_lat));
[~, lon_idx] = min(abs(lon_sat - papa_lon));



%% 6. Plot the satellite SSTanom data extracted from Ocean Station Papa and
%the mooring-based temperature anomaly calculated by combining the OOI and
%WOA data together as separate lines on the same time-series plot (adding
%to your plot from step 4) so that you can compare the two records

sstAnom_OSP = squeeze(ncread(filename, 'sstAnom', [lon_idx, lat_idx, 1], [1, 1, Inf]));
sstAnom_OSP = double(sstAnom_OSP(:));
sstAnom_OSP(sstAnom_OSP <= -900) = NaN;

% Convert timeFixed to datetime to match ooi_time_dt
sat_time_dt = datetime(timeFixed, 'ConvertFrom', 'datenum');

sat_on_mooring = interp1(timeFixed, sstAnom_OSP, all_time_clean, 'linear', NaN);

% Plot both records
figure(4)
hold on
plot(sat_time_dt, sstAnom_OSP, 'b-', 'LineWidth', 2, 'DisplayName', 'Satellite SST anomaly (OSP cell)')
plot(ooi_time_dt, sat_on_mooring, '.', 'Color', [0.15 0.65 0.35], 'MarkerSize', 5, ...
    'DisplayName', 'Satellite anomaly interp. to mooring times')
hold off
ylabel('Temperature Anomaly (°C)')
title('Temperature Anomaly at Ocean Station Papa: Mooring vs. Satellite')
legend('Location', 'best')
grid on

%% Extension (Visualizing data): SST anomaly maps at several times + markers on the time series
% In Part 1, you made one figure showing a regional map of the satellite SST data.
% Make a series of SSTanom maps from different times within the OOI mooring time series record
% to show how the Ocean Station Papa record fits into a broader regional context,
% and show the times you selected on the time series plot.

moor_tmin = min(all_time_clean);
moor_tmax = max(all_time_clean);
inMooring = timeFixed >= moor_tmin & timeFixed <= moor_tmax;
idxPool   = find(inMooring)';
if numel(idxPool) < 2
    idxPool = (1:numel(timeFixed))';
end
% Four representative times: spread across the mooring overlap window
target_dn = [ datenum(2014,6,15), datenum(2015,8,15), datenum(2017,1,15), datenum(2019,6,15) ];
target_dn = target_dn(target_dn >= moor_tmin & target_dn <= moor_tmax);
if isempty(target_dn)
    pick = round(linspace(1, numel(idxPool), 4));
    mapIdx = idxPool(pick);
else
    mapIdx = zeros(1, numel(target_dn));
    for k = 1:numel(target_dn)
        [~, mapIdx(k)] = min(abs(timeFixed - target_dn(k)));
    end
    mapIdx = unique(mapIdx, 'stable');
end
if numel(mapIdx) > 4
    mapIdx = mapIdx(1:4);
end

[Lon, Lat] = meshgrid(lon_sat(:), lat_sat(:));
nt_sat     = numel(timeFixed);
maxAbsMap  = 3;
clevs      = linspace(-maxAbsMap, maxAbsMap, 25);

figure(5)
clf
nMaps = numel(mapIdx);
nrows = ceil(nMaps / 2);
ncols = min(2, max(1, nMaps));
for k = 1:nMaps
    it = mapIdx(k);
    F  = double(squeeze(ncread(filename, 'sstAnom', [1, 1, it], [Inf, Inf, 1]))');
    F(F <= -900) = NaN;
    subplot(nrows, ncols, k)
    contourf(Lon, Lat, F, clevs, 'LineColor', 'none')
    hold on
    plot(papa_lon, papa_lat, 'kp', 'MarkerFaceColor', [1 0.92 0.2], 'MarkerSize', 9, 'LineWidth', 1)
    hold off
    colormap(gca, redBlueDiverging(256))
    clim([-maxAbsMap maxAbsMap])
    colorbar
    xlabel('Longitude (°E)')
    ylabel('Latitude (°N)')
    title(sprintf('SST anomaly — %s', datestr(timeFixed(it), 'mmm yyyy')))
    axis tight
    grid on
end
sgtitle('Regional MUR SST anomaly (monthly; nearest grid to assignment subset)')

figure(4)
hold on
for k = 1:numel(mapIdx)
    xline(datetime(timeFixed(mapIdx(k)), 'ConvertFrom', 'datenum'), '--', ...
        'Color', [0.35 0.35 0.35], 'LineWidth', 1.1, 'HandleVisibility', 'off', ...
        'Label', datestr(timeFixed(mapIdx(k)), 'mmm yyyy'), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8);
end
hold off

%% Export figures for lab report (optional)
figDir = fullfile(thisDir, 'figures');
if ~isfolder(figDir), mkdir(figDir); end
try
    print(figure(1), fullfile(figDir, 'fig01_woa_ooi.png'), '-dpng', '-r300');
    print(figure(4), fullfile(figDir, 'fig04_anomaly_compare.png'), '-dpng', '-r300');
    print(figure(5), fullfile(figDir, 'fig05_sst_anom_maps.png'), '-dpng', '-r300');
catch ME
    warning('Figure export skipped: %s', ME.message);
end

%% --- Local functions --------------------------------------------------------

function allData = buildOOIAllData(ooiDir)
    std_cutoff = 0.25;
    filenames = {
        'deployment0001_GP03FLMB.nc', ...
        'deployment0003_GP03FLMB.nc', ...
        'deployment0004_GP03FLMB.nc', ...
        'deployment0005_GP03FLMB.nc', ...
        'deployment0006_GP03FLMB.nc'
        };
    deploymentNums = [1, 3, 4, 5, 6];
    allData = struct([]);
    for i = 1:numel(filenames)
        fp = fullfile(ooiDir, filenames{i});
        assert(isfile(fp), 'Missing OOI file: %s', fp);
        time        = ncread(fp, 'time');
        temperature = ncread(fp, 'ctdmo_seawater_temperature');
        time0       = datenum('1900-01-01');
        timeFixed   = time0 + time / (60 * 60 * 24);
        movingMean  = movmean(temperature, (24 * 60) / 15);
        movingStd   = movstd(temperature, (24 * 60) / 15);
        good_idx    = find(movingStd <= std_cutoff);
        allData(i).deploymentNum = deploymentNums(i);
        allData(i).filename      = filenames{i};
        allData(i).time          = timeFixed;
        allData(i).temperature   = temperature;
        allData(i).movingMean    = movingMean;
        allData(i).movingStd     = movingStd;
        allData(i).good_idx      = good_idx;
    end
end

function cmap = redBlueDiverging(n)
    anchors = [
        0.02 0.20 0.52
        0.30 0.55 0.80
        0.90 0.90 0.90
        0.85 0.35 0.25
        0.55 0.00 0.14
        ];
    xi  = linspace(0, 1, n);
    x0  = linspace(0, 1, size(anchors, 1));
    cmap = [interp1(x0, anchors(:, 1), xi)', ...
            interp1(x0, anchors(:, 2), xi)', ...
            interp1(x0, anchors(:, 3), xi)'];
end
