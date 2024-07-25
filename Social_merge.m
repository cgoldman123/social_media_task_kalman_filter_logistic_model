function [all_data, subj_mapping, flag_ids] = Social_merge(ids, files, room_type, study)        
    all_data = cell(1, numel(ids)); 
    flag_ids = {};
    good_index = [];
    
    subj_mapping = cell(numel(ids), 2); 
    
    for i = 1:numel(ids)
        id   = ids{i};
        file = files(contains(files, id));    
        success=0;    
        for j = 1:numel(file)
            if ~success
                if j>1
                    flag_ids = [flag_ids id];
                end
                if strcmp(study,'local')
                    % determine if cb=1 or cb=2
                    filename = file{j};
                    if contains(filename, '_R1-')
                        schedule = readtable('../schedules/sm_distributed_schedule1.csv');
                        cb = 1;
                    else
                        schedule = readtable('../schedules/sm_distributed_schedule1_CB.csv');
                        cb = 2;
                    end
                    all_data{i} = Social_local_parse(filename, schedule, room_type, study);  
                elseif strcmp(study,'prolific')
                    % determine if cb=1 or cb=2
                    filename = file{j};
                    if contains(filename, '_CB_')
                        cb = 2;
                        schedule = readtable('../schedules/sm_distributed_schedule1_CB.csv');
                    else
                        schedule = readtable('../schedules/sm_distributed_schedule1.csv');
                        cb = 1;
                    end
                    all_data{i} = Social_local_parse(filename, schedule, room_type, study);  
                end
            else
                continue
            end
    
            if((size(all_data{i}, 1) == 40) && (sum(all_data{i}.gameLength) == 280))
                good_index = [good_index i];
                success=1;
            end
            
            all_data{i}.subjectID = repmat(i, size(all_data{i}, 1), 1);
            
            subj_mapping{i, 1} = {id};
            subj_mapping{i, 2} = i;
            subj_mapping{i, 3} = cb;
        end
    end
    
    all_data = all_data(good_index);
    subj_mapping = subj_mapping(good_index, :);
    
    all_data = vertcat(all_data{:});    
end