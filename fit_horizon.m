function final_fit = fit_horizon(data, ses, room_type)
    d = data;
    
    N = sum(cellfun(@(x)~isempty(x),{d.key})); % exclude trials that not get played
    N = N;  % temporary: still here because of the missing final row in CSV
                % that causes one game to be 9 long instead of 10
    game.n_game = N;
    d = d(1:N);
    %
    Mcell = arrayfun(@(x)extendnan(x.mean',2),d,'UniformOutput',false);
    game.underlyingMean = vertcat(Mcell{:});

    RTcell = arrayfun(@(x)extendnan(x.RT,9),d,'UniformOutput',false);
    game.RT = vertcat(RTcell{:});

    % key -1(left), 1(right)
    Keycell = arrayfun(@(x)extendnan(x.key,9)*2 - 3, d,'UniformOutput',false);
    game.key = vertcat(Keycell{:});

    for ri = 1:2
        Rewardcell = arrayfun(@(x)extendnan(x.rewards(ri,:),9),d,'UniformOutput',false);
        game.rewards{ri} = vertcat(Rewardcell{:});
    end

    game.cond_horizon = sum(~isnan(game.key),2); % horizon condition
    % The above computes (not optimally -- it could just use the 
    % gameLength member) the length of the game
    horizon = unique(game.cond_horizon);
    % Collects the two types of games

    % info 1(3L1R) 0(2L2R) -1(1L3R) -> categorizes the forced choices
    game.cond_uncertain = 0 - sum(game.key(:,1:4),2)/2; % uncertain condition

    R{1} = game.rewards{1}.*(game.key == -1);
    R{2} = game.rewards{2}.*(game.key == 1);
    M{1} = sum(R{1}(:,1:4),2)./sum(game.key(:,1:4) == -1,2);
    M{2} = sum(R{2}(:,1:4),2)./sum(game.key(:,1:4) == 1,2);
    if strcmp(room_type, "Like")
        game.dM = M{2}-M{1};
    elseif strcmp(room_type, "Dislike")
        game.dM = M{1}-M{2};
    end
    
%     disp(horizon);
    
    % for each horizon condition (game types)
    for hi = 1:length(horizon)
        % indeces where the horizon condition (horizon(hi)) is true
        ind_h = game.cond_horizon == horizon(hi);
        
        modelfree.p_hi(hi) = sum((game.cond_uncertain == game.key(:,5)) & ind_h)/sum(game.cond_uncertain & ind_h);
        modelfree.p_lm(hi) = sum((-sign(game.dM) == game.key(:,5)) ...
            & game.dM ~= 0 & ind_h)...
            /sum(game.dM ~= 0 & ind_h);
    end
    % MLE
    % clc;
    fit = fit_MLE(game.cond_horizon, game.cond_uncertain, game.dM, game.key(:,5));
    MLE.Infobonus13 = fit.x(3,:);
    MLE.Decisionnoise13 = fit.x(2,:);
    MLE.bias13 = fit.x(1,:);
    %MLE.Decisionnoise22 = fit.x(5,:);
    %MLE.bias22 = fit.x(4,:);
    
    sub.game(1) = game;
    sub.p_hi = modelfree.p_hi;
    sub.p_lm = modelfree.p_lm;
    sub.fitA = MLE.Infobonus13;
    sub.fitSigma13 = MLE.Decisionnoise13;
    %sub.fitSigma22 = MLE.Decisionnoise22;
    sub.fitbias13 = MLE.bias13;
    %sub.fitbias22 = MLE.bias22;
    
    fin = struct(                                                                   ...
        'subject', d(1).subject,                                                    ...
        'session', ses,                                                        ...
        'p_high_information_h1', sub.p_hi(1),                                       ...
        'p_high_information_h5', sub.p_hi(2),                                       ...
        'p_low_mean_h1', sub.p_lm(1),                                               ...
        'p_low_mean_h5', sub.p_lm(2),                                               ...
        'fit_info_bonus_alpha_h1', sub.fitA(1),                                     ...
        'fit_info_bonus_alpha_h5', sub.fitA(2),                                     ...
        'fit_decision_noise_sigma_13_h1', sub.fitSigma13(1),                        ...
        'fit_decision_noise_sigma_13_h5', sub.fitSigma13(2),                        ...
        'fit_spatial_bias_B_13_h1', sub.fitbias13(1),                               ...
        'fit_spatial_bias_B_13_h5', sub.fitbias13(2),                               ...
        'p_high_information_h5_h1_diff', sub.p_hi(2)-sub.p_hi(1),                   ...
        'p_low_mean_h5_h1_diff', sub.p_lm(2)-sub.p_lm(1),                           ...
        'fit_info_bonus_alpha__h5_h1_diff', sub.fitA(2)-sub.fitA(1),                ...
        'fit_decision_noise_13_h5_h1_diff', sub.fitSigma13(2)-sub.fitSigma13(1),    ...
        'fit_spatial_bias_B_13_h5_h1_diff', sub.fitbias13(2)-sub.fitbias13(1));
        
        %'fit_decision_noise_sigma_22_h1', sub.fitSigma22(1),                        ...
        %'fit_decision_noise_sigma_22_h6', sub.fitSigma22(2),                        ...
        %'fit_spatial_bias_B_22_h1', sub.fitbias22(1),                               ...
        %'fit_spatial_bias_B_22_h6', sub.fitbias22(2),                               ...
        %'fit_decision_noise_22_h6_h1_diff', sub.fitSigma22(2)-sub.fitSigma22(1),    ...
        %'fit_spatial_bias_B_22_h6_h1_diff', sub.fitbias22(2)-sub.fitbias22(1)       ...
% 
%     
%     Diffs6minus1 = [sub.p_hi(2)-sub.p_hi(1) sub.p_lm(2)-sub.p_lm(1) sub.fitA(2)-sub.fitA(1) sub.fitSigma13(2)-sub.fitSigma13(1) sub.fitSigma22(2)-sub.fitSigma22(1) sub.fitbias13(2)-sub.fitbias13(1) sub.fitbias22(2)-sub.fitbias22(1)];  
%     FinalResults = [sub.p_hi(1) sub.p_hi(2) sub.p_lm(1) sub.p_lm(2) sub.fitA(1) sub.fitA(2) sub.fitSigma13(1) sub.fitSigma13(2) sub.fitSigma22(1) sub.fitSigma22(2) sub.fitbias13(1) sub.fitbias13(2) sub.fitbias22(1) sub.fitbias22(2) Diffs6minus1];
%     FinalResults = num2cell(FinalResults);
    
   % final_fit = struct2table(fin);
      final_fit = fin;
end