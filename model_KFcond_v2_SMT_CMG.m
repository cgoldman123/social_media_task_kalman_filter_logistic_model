function model_output = model_KFcond_v2_SMT_CMG(params, free_choices, rewards, mdp)
%     # This model has:
%     #   Kalman filter inference
%     #   Info bonus
% 
%     #   spatial bias is in this one and it can vary by 
% 
%     # no choice kernel
%     # inference is constant across horizon and uncertainty but can vary by 
%     # "condition".  Condition can be anything e.g. TMS or losses etc ...
%     
%     # two types of condition:
%     #   * inference fixed - e.g. horizon, uncertainty - C1, nC1
%     #   * inference varies - e.g. TMS, losses - C2, nC2
% 
%     # hyperpriors =========================================================
% 
%     # inference does not vary by condition 1, but can by condition 2
%     # note, always use j to refer to condition 2
    dbstop if error;
    G = mdp.G; % num of games
    T = mdp.T; % num of forced choices

    alpha_start = params.alpha_start;
    alpha_inf = params.alpha_inf;
    mu0 = params.mu0; % initial value. can fix to 50
    info_bonuses = [params.info_bonus_h1 params.info_bonus_h5];       
    decision_noises = [params.dec_noise_h1_13 params.dec_noise_h5_13];
    biases = [params.side_bias_h1 params.side_bias_h5];

    alpha0  = alpha_start / (1 - alpha_start) - alpha_inf^2 / (1 - alpha_inf);
    alpha_d = alpha_inf^2 / (1 - alpha_inf); 

    
    
    action_probs = nan(1,G);
    
    pred_errors = nan(T+1,G);
    pred_errors_alpha = nan(T+1,G);
    exp_vals = nan(T+1,G);
    alpha = nan(T+1,G);
    
    for g=1:G  % loop over games
        % values
        mu1 = [mu0 nan nan nan nan];
        mu2 = [mu0 nan nan nan nan];

        % learning rates 
        alpha1 = [alpha0 nan nan nan nan]; 
        alpha2 = [alpha0 nan nan nan nan]; 

        % information bonus, decision noise, and side bias for this game depend on 
        % the horizon. Decision noise additionally depends on
        % information condition
        A = info_bonuses(mdp.horizon_sequence(g));
        sigma_g = decision_noises(mdp.horizon_sequence(g));
        bias = biases(mdp.horizon_sequence(g));

        for t=1:T  % loop over forced-choice trials

            % if the first bandit was chosen
            if (mdp.forced_choices(t,g) == 1) 
                % update LR
                alpha1(t+1) = 1/( 1/(alpha1(t) + alpha_d) + 1 );
                alpha2(t+1) = 1/( 1/(alpha2(t) + alpha_d) );
                exp_vals(t,g) = mu1(t);
                pred_errors(t,g) = (rewards(t,g) - exp_vals(t,g));
                alpha(t,g) = alpha1(t+1);
                pred_errors_alpha(t,g) = alpha1(t+1) * pred_errors(t,g); % confirm that alpha here should be t+1
                mu1(t+1) = mu1(t) + pred_errors_alpha(t,g);
                mu2(t+1) = mu2(t); 
            else
                % update LR
                alpha1(t+1) = 1/( 1/(alpha1(t) + alpha_d) ); 
                alpha2(t+1) = 1/( 1/(alpha2(t) + alpha_d) + 1 );
                exp_vals(t,g) = mu2(t);
                mu1(t+1) = mu1(t);
                pred_errors(t,g) = (rewards(t,g) - exp_vals(t,g));
                alpha(t,g) = alpha2(t+1);
                pred_errors_alpha(t,g) = alpha2(t+1) * pred_errors(t,g);
                mu1(t+1) = mu1(t);
                mu2(t+1) = mu2(t) + pred_errors_alpha(t,g);
            end
        end
        % get last expected value and prediction error
        % for the option that was chosen
        if (free_choices(g) == 1) 
            alpha1(T+2) = 1/( 1/(alpha1(T+1) + alpha_d) + 1 );
            exp_vals(T+1,g) = mu1(T+1);
            pred_errors(T+1,g) = (rewards(T+1,g) - exp_vals(T+1,g));
            alpha(T+1,g) = alpha1(T+2);
            pred_errors_alpha(T+1,g) = alpha1(T+2) * pred_errors(T+1,g); % confirm that alpha here should be t+1
        else
            alpha2(T+2) = 1/( 1/(alpha2(T+1) + alpha_d) + 1 );
            exp_vals(T+1,g) = mu2(T+1);
            pred_errors(T+1,g) = (rewards(T+1,g) - exp_vals(T+1,g));
            alpha(T+1,g) = alpha2(T+2);
            pred_errors_alpha(T+1,g) = alpha2(T+2) * pred_errors(T+1,g);
        end

        % compute difference in values
        dQ = mu2(T+1) - mu1(T+1) + A * mdp.right_info(g) + bias;

        % probability of choosing the left (right?) bandit
        p = 1 / (1 + exp(-dQ/(sigma_g)));

        action_probs(g) = free_choices(g)*p + (1-free_choices(g))*(1-p);


        
    end
    
    model_output.action_probs = action_probs;
    model_output.exp_vals = exp_vals;
    model_output.pred_errors = pred_errors;
    model_output.pred_errors_alpha = pred_errors_alpha;
    model_output.alpha = alpha;
    

 
