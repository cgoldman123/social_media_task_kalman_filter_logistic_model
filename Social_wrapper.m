%% Clear workspace
clear all

%% Construct the appropriate path depending on the system this is run on
% If running on the analysis cluster, some parameters will be supplied by 
% the job submission script -- read those accordingly.

dbstop if error

if ispc
    root = 'L:/';
    run=1;
    experiment = 'local'; % indicate local or prolific
    room = 'Like';
    model = 'kf';
    results_dir = sprintf([root 'rsmith/lab-members/cgoldman/Wellbeing/social_media/output/%s/%s/'], experiment, model);

elseif ismac
    root = '/Volumes/labs/';
    run=1;
elseif isunix 
    root = '/media/labs/';
    results_dir = getenv('RESULTS');   % run = 1,2,3
    room = getenv('ROOM'); %Like and/or Dislike
    model = getenv('MODEL'); %Like and/or Dislike
    experiment = getenv('EXPERIMENT');
end



%% Set parameters or run loop over all-----
% study = 'prolific'; %prolific or local
% model = 'new'; %old or new

get_fits(root, experiment, model, room, results_dir);





% for mm = {'new', 'old'}
%     if strcmp(mm, 'new')
%         model_outputs = struct();
%         for r = {'Like', 'Dislike'}
%             model_output = get_fits(root, experiment ,mm{1},r{1}); 
%             model_outputs.(r{1}) = model_output;
%         end
%         all_pred_errors = get_prediction_errors(model_outputs);
%         timestamp = datestr(datetime('now'), 'mm_dd_yy_THH-MM-SS');
%         outpath = sprintf([root 'rsmith/wellbeing/tasks/SocialMedia/output/%s/kf/pred_errors_%s.csv'],experiment, timestamp);
%         writetable(all_pred_errors, outpath);
%     else
%         for r = {'Like', 'Dislike'}
%             get_fits(root, experiment ,mm{1},r{1}); 
%         end
%     end
% end

