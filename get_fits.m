function varargout = get_fits(root,study,model,room_type, results_dir)

    disp(root);disp(study);disp(model);disp(room_type);disp(results_dir);
    %% Import matjags library and model-specific fitting function
    addpath([root 'rsmith/all-studies/core/matjags']);
    addpath([root 'rsmith/all-studies/models/extended-horizon']);
    %% Get files
    files={};subs={};
    bad_ids = {'65f85564dbfd935f4f68d062', '5f8b3c348183d30f91832a2b', '5d7fb79ff44487001807463e', 'CGTEST', 'ar111', 'CLTEST', 'temp','TT000', 'NL333', 'KP123', 'TT123', 'CL123', 'NL999', 'RS789', 'AR111'};
    if strcmp(study, 'local')
        sink = [root 'rsmith/wellbeing/data/raw/'];
        datadir = dir(sink);
        for f=1:size(datadir,1)
            if ~contains(datadir(f).name,'.')
                fold = dir([sink datadir(f).name]);
                for g=1:size(fold,1)
                    if ~isempty(regexp(fold(g).name,'SM_R[0-9]-_BEH', 'once')) && ~contains(fold(g).name, bad_ids) && ~contains(fold(g).name, '~$')
                        subs = [subs extractBetween([sink '/' datadir(f).name '/' fold(g).name], [sink '/' datadir(f).name '/'], '-T1-__SM')];
                        files = [files [sink datadir(f).name '/' fold(g).name]];
                    end
                end
            end
        end
    elseif strcmp(study, 'prolific')
        for cb = {'_CB', ''}
            sink = fullfile(root, ['NPC/DataSink/StimTool_Online/WB_Social_Media' cb{:}]);
            datadir = dir(sink);
            sDir = datadir(arrayfun(@(n) contains(n.name, 'social_media'), datadir));
            for file = sDir'
                sub = extractBetween(file.name, 'social_media_', '_T');
                if ~isempty(sub) && ~ismember(sub, bad_ids)
                    fullFilePath = fullfile(file.folder, file.name);
                    files{end+1} = fullFilePath; % Ensure 'files' is initialized as an empty cell array before the loop.
                    subs{end+1} = sub;
                end
            end
        end
    end
    %% Uncomment these lines but for some reason they are not working for me!!!
%     [~,order] = sort(arrayfun(@(n) datetime(extractBetween(files{n},['_T1' cb '_'],'.'), 'InputFormat', 'yyyy-MM-dd_HH''h''mm'), 1:numel(files)));
%     files=files(order); 
    %% Read in schedule for data organizing
    %schedule = readtable(['../schedules/sm_distributed_schedule1' cb '.csv']);
    
    if strcmp(model, 'logistic')
        used={};
        for i = 1:length(subs)
           subject = subs{i};
           has_practice_effects=0;
           ses=2;
           results_dir = [root 'rsmith/wellbeing/tasks/SocialMedia/output/' study '/logistic/'];
           file = files(contains(files,subject));
           for j = 1:length(file)
               if ~ismember(subject, used)
                   if j>1
                      has_practice_effects = 1;
                   end
                try
                    data = fit_social_genmeans(file, subject, ses, room_type, [], study);
                catch ME
                    disp('An error occurred:');
                    disp(ME.message);
                    disp('Error occurred in:');
                    disp(ME.stack(1));  % This displays where in the code the error occurred
                    continue
                end
                   used = [used subject];
                   data.has_practice_effects = has_practice_effects;
                   writetable(data, [results_dir 'old_model-' subject{:} '-' room_type '-fit.csv']);
               end
           end
        end
    else
        %% Clean up files and concatenate for fitting
        timestamp = datestr(datetime('now'), 'mm_dd_yy_THH-MM-SS');
        [big_table, subj_mapping, flag] = Social_merge(subs, files, room_type, study);
        outpath_beh = sprintf([results_dir 'beh_%s_%s_%s.csv'], study, room_type, timestamp);
        writetable(big_table, outpath_beh);

        %% Perform model fit
        % Reads in the above 'outpath_beh' file to fit
        [fits, model_output] = fit_extended_model(outpath_beh, results_dir);
        for i = 1:numel(model_output)
            subject = subj_mapping{i, 1};  
            model_output(i).results.subject = subject{:};
            model_output(i).results.room_type = room_type;
            model_output(i).results.cb = subj_mapping{i, 3};  
        end
        varargout{1} = model_output;
        save(sprintf([results_dir 'model_output_%s_%s.mat'], room_type, timestamp),'model_output');
        fits.id = vertcat(subj_mapping{:, 1});
        fits.has_practice_effects = (ismember(string(fits.id), flag));
        outpath_fits = sprintf([results_dir 'fits_%s_%s.csv'], room_type, timestamp);
        writetable(fits, outpath_fits);
    end
end