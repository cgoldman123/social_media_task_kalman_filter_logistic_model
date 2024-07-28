function [fits, model_output] = fit_extended_model(formatted_file, result_dir)
    if ispc
        root = 'L:/';
    else
        root = '/media/labs/';
    end
    fprintf('Using this formatted_file: %s\n',formatted_file);

    %formatted_file = 'L:\rsmith\wellbeing\tasks\SocialMedia\output\prolific\kf\beh_Dislike_06_03_24_T16-03-52.csv';  %% remember to comment out
    %addpath(['L:/rsmith/all-studies/core/matjags']);
    %addpath(['L:/rsmith/all-studies/models/extended-horizon']);
    %addpath('C:\Users\CGoldman\AppData\Local\Programs\JAGS\JAGS-4.3.1\x64\bin');
    %addpath('C:\Users\CGoldman\AppData\Local\Programs\JAGS');
    addpath([root 'rsmith/lab-members/cgoldman/general/']);
    %addpath('~/Documents/MATLAB/MatJAGS/');


    
    fundir      = pwd;%[maindir 'TMS_code/'];
    datadir     = pwd;%[maindir 'TMS_code/'];
    savedir     = pwd;%[maindir];
    addpath(fundir);
    cd(fundir);
    %defaultPlotParameters

%     sub = load_TMS_v1([datadir '/EIT_HorizonTaskOutput_HierarchicalModelFormat_v2.csv']);
    sub = load_TMS_v1(formatted_file);
%     sub = sub(1,:); % REMEMBER TO COMMENT OUT
    disp(sub);
    
    %% ========================================================================
    %% HIERARCHICAL MODEL FIT ON FIRST FREE CHOICE %%
    %% HIERARCHICAL MODEL FIT ON FIRST FREE CHOICE %%
    %% HIERARCHICAL MODEL FIT ON FIRST FREE CHOICE %%
    %% ========================================================================

    %% prep data structure 
    clear a
    L = unique(sub(1).gameLength);
    i = 1;
    NS = length(sub);   % number of subjects
    T = 4;              % number of forced choices
    U = 1;  %used to be 2            % number of uncertainty conditions
    
    NUM_GAMES = 40; %max(vertcat(sub.game), [], 'all');
    
    a  = zeros(NS, NUM_GAMES, T);
    c5 = nan(NS,   NUM_GAMES);
    r  = zeros(NS, NUM_GAMES, T+1); % CMG changed last dimension to T+1 to be able to get prediction error for free choice
    GL = nan(NS,   NUM_GAMES);

    for sn = 1:length(sub)

        % choices on forced trials
        dum = sub(sn).a(:,1:4);
        a(sn,1:size(dum,1),:) = dum;

        % choices on free trial
        % note a slight hacky feel here - a is 1 or 2, c5 is 0 or 1.
        dum = sub(sn).a(:,5) == 2;
        L(sn) = length(dum);
        c5(sn,1:size(dum,1)) = dum;

        % rewards
        dum = sub(sn).r(:,1:5); % CMG changed last dimension to T+1 to be able to get prediction error for free choice
        r(sn,1:size(dum,1),:) = dum;

        % game length
        dum = sub(sn).gameLength;
        GL(sn,1:size(dum,1)) = dum;

        G(sn) = length(dum);

        % uncertainty condition 
        dum = abs(sub(sn).uc - 2) + 1;
        UC(sn, 1:size(dum,1)) = dum;

        % difference in information
        dum = sub(sn).uc - 2;
        dI(sn, 1:size(dum,1)) = -dum;

        % TMS flag
        dum = strcmp(sub(sn).expt_name, 'RFPC');
        TMS(sn,1:size(dum,1)) = dum;
        

    end

    dum = GL(:); dum(dum==0) = [];
    H = length(unique(dum));
    dum = UC(:); dum(dum==0) = [];
    U = length(unique(dum));
    GL(GL==5) = 1;
    GL(GL==9) = 2; %used to be 10

    C1 = GL ;      %(GL-1)*2+UC;      CAL edits
    C2 = TMS + 1;
    nC1 = 2;
    nC2 = 1;

    % meaning of condition 1
    % gl uc c1
    %  1  1  1 - horizon 1, [2 2]
    %  1  2  2 - horizon 6, [1 3]
    %  2  1  3 - horizon 1, [2 2]
    %  2  2  4 - horizon 6, [1 3]

    % meaning of condition 1 (SMT FIXED)
    % gl uc c1
    %  1  1  1 - horizon 1, [2 2]
    %  1  2  2 - horizon 1, [1 3]
    %  2  1  3 - horizon 6, [2 2]
    %  2  2  4 - horizon 6, [1 3]



    datastruct = struct(...
        'C1', C1, 'nC1', nC1, ...
        'NS', NS, 'G',  G,  'T',   T, ...
        'dI', dI, 'a',  a,  'c5',  c5, 'r', r, 'result_dir', result_dir);
    
    %% run hierarchical model fits! 
    % 750s (12.5 minutes) for 1500 samples
    % 
    cd(fundir)
    nchains = 4;
    nburnin = 500;
    nsamples = 1000; 
    thin = 1;
    % MCMC parameters for JAGS


    % Initialize values all latent variables in all chains
    clear S init0
    for i=1:nchains

        S.a0(1:nC2) = 1;
        S.b0(1:nC2) = 1;
        S.a_inf(1:nC2) = 1;
        S.b_inf(1:nC2) = 1;
        S.AA(1:NS,1:nC1,1:nC2) = 0;
        S.BB(1:NS,1:nC1,1:nC2) = 100;

        init0(i) = S;
    end

    % Use JAGS to Sample
    tic

    doparallel = 1;
    % if doparallel
    %     parpool;
    % end
    
    if ispc
        root = 'L:/';
    elseif ismac
        root = '/Volumes/labs/';
    elseif isunix 
        root = '/media/labs/';
    end
    
    currdir = [root 'rsmith/all-studies/models/extended-horizon/'];
    
    fprintf( 'Running JAGS\n' );
    [samples, stats ] = matjags_cmg( ...
        datastruct, ...
        fullfile(currdir, 'model_KFcond_v2_SMT'), ...
        init0, ...
        'doparallel' , doparallel, ...
        'nchains', nchains,...
        'nburnin', nburnin,...
        'nsamples', nsamples, ...
        'thin', thin, ...
        'monitorparams', ...
        {'a0' 'b0' 'alpha_start' 'alpha0' 'alpha_d' ...
        'a_inf' 'b_inf' 'alpha_inf' ...
        'mu0_mean' 'mu0_sigma' 'mu0' ...
        'AA_mean' 'AA_sigma' 'AA' ...
        'SB_mean' 'SB_sigma' 'SB' ...
        'BB_mean' 'BB' ...
        }, ...
        'savejagsoutput' , 1 , ...
        'verbosity' , 1 , ...
        'cleanup' , 1  );
    toc

    %% throw out first N samples
    N = 1;

    stats.mean.SB = squeeze(mean(mean(samples.SB(:,N:end,:,:,:),2),1));
    stats.mean.BB = squeeze(mean(mean(samples.BB(:,N:end,:,:,:),2),1));
    stats.mean.AA = squeeze(mean(mean(samples.AA(:,N:end,:,:,:),2),1));

    stats.mean.mu0 = squeeze(mean(mean(samples.mu0(:,N:end,:,:),2),1));
    stats.mean.alpha_start = squeeze(mean(mean(samples.alpha_start(:,N:end,:,:),2),1));
    stats.mean.alpha_inf = squeeze(mean(mean(samples.alpha_inf(:,N:end,:,:),2),1));
    stats.mean.alpha0 = squeeze(mean(mean(samples.alpha0(:,N:end,:,:),2),1));
    stats.mean.alpha_d = squeeze(mean(mean(samples.alpha_d(:,N:end,:,:),2),1));
    
    %% Organize fits
    fits = struct();
    model_output = struct();
    for si = 1:length({sub.subjectID})
        fits(si).id = {sub(si).subjectID};
        
        fits(si).info_bonus_h1 = stats.mean.AA(si, 1);
        fits(si).info_bonus_h5 = stats.mean.AA(si, 2);

        %fits(si).dec_noise_h1_22 = stats.mean.BB(si, 1);
        fits(si).dec_noise_h1_13 = stats.mean.BB(si, 1);
        %fits(si).dec_noise_h6_22 = stats.mean.BB(si, 3);
        fits(si).dec_noise_h5_13 = stats.mean.BB(si, 2);

        fits(si).alpha_start = stats.mean.alpha_start(si);
        fits(si).alpha_inf = stats.mean.alpha_inf(si);  
        
        fits(si).side_bias_h1 = stats.mean.SB(si, 1);
        fits(si).side_bias_h5 = stats.mean.SB(si, 2);


        fits(si).mu0 = stats.mean.mu0(si); %R0 - prior over reward
        
        params = fits(si);
        free_choices = c5(si,:);
        rewards = squeeze(r(si,:,:))';

        mdp.horizon_sequence = C1(si,:);
        mdp.forced_choices = squeeze(a(1,:,:))';
        mdp.right_info = squeeze(dI(1,:,:));
        mdp.T = T; % num forced choices
        mdp.G = 40; % game length
        
        model_output(si).results = model_KFcond_v2_SMT_CMG(params,free_choices, rewards,mdp);        
    end
    
    fits = struct2table(fits);
end