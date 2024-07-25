function fit = fit_MLE(CondHorizon, CondInfo, DfMean, Key)
priorFlag = true;
L = unique(CondHorizon);
gameL = length(CondHorizon);
CondInfo(CondInfo == 0) = nan;
for i = 1:length(L)
    % [1 3] condition
    ind = CondHorizon == L(i) & (~isnan(CondInfo));
    c5      = Key(ind);
    dm = DfMean(ind);
    uc = CondInfo(ind); % +1 if choice 2 is uncertain
    % x = [bias  sigma bonus]
    X0  = [0     10     0    ];
    LB  = [-100  0     -100 ];
    UB  = [100   100   100  ];
    obFunc = @(x) lik_13(x, dm, c5, uc, priorFlag);
    
    options = optimoptions('fmincon', 'Display', 'off');
    
    [x, tar] = fmincon(obFunc, X0, [], [], [], [], LB, UB, [], options);
%     LL(i) = -tar;
    xfit = x;
    k13 = length(X0);
    
    % [2 2] condition
    ind = CondHorizon == L(i) & (isnan(CondInfo));
    c5      = Key(ind);
    dm =  DfMean(ind);
%     uc = 2*(CondInfo(ind)-1.5); % +1 if choice 2 is uncertain
    % x = [bias  sigma]
    X0  = [0     1    ];
    LB  = [-100  0    ];
    UB  = [100   100  ];
    obFunc = @(x) lik_22(x, dm, c5, priorFlag);
    [x, tar] = fmincon(obFunc, X0, [], [], [], [], LB, UB, [], options);  
%     LL(i) = LL(i)-tar;
    xfit = [xfit x];
    k22 = length(X0);
    
    k(i) = k13+k22;
    n(i) = sum(CondHorizon==L(i));
    
    fit.model_name = 'original';
    fit.var_names = {'bias13' 'noise13' 'bonus' 'bias22' 'noise22'};
    fit.x(:,i) = xfit;
end
% n = length(game);
% BIC = -2*sum(LL) + sum(k) * log(sum(n));
% LPT = exp(-BIC/sum(n)/2);
% fit.bic = BIC;
% fit.lpt = LPT;
% fit.LL = sum(LL);
% fit.k = sum(k);
% fit.n = sum(n);
% AIC = -2*sum(LL) + sum(k) * 2;
% LPTa = exp(-AIC/n/2);
% fit.aic = AIC;
% fit.lpta = LPTa;
      

function LL = lik_13(X, dm, c5, uc, priorFlag)
% p = 1 / (1 + exp(dQ / sigma / sqrt(2)));
% dQ = dm + bias;
% unpack X
bias = X(1);
sigma = X(2);
bonus = X(3);
% if isnan(sigma) | (isnan(bias)) | (isnan(bonus))
%     LL = Inf;
%     return
% end
dQ = dm  + uc * bonus + bias;
P = 1 ./ ( 1 + exp( -1/sigma/sqrt(2) * dQ ));
lP1 = log(P(c5==1));
lP0 = log(1-P(c5==-1));
lP1 = lP1(~isnan(lP1));%what if there are fewer terms so it's becoming large?
lP0 = lP0(~isnan(lP0));
if priorFlag
    L_AB = gaussianPrior(bonus, 0, 20);
    L_noise = exponentialPrior(sigma, 1/20);
    LL = -(sum(lP1)+sum(lP0) + L_AB + L_noise);
else
    LL = -(sum(lP1)+sum(lP0));
end

function LL = lik_22(X, dm, c5, priorFlag)
% p = 1 / (1 + exp(dQ / sigma / sqrt(2)));
% dQ = dm + bias + uc * bonus;
% unpack X
bias = X(1);
sigma = X(2);
% if isnan(sigma) | (isnan(bias))
%     LL = Inf;
%     return
% end
dQ = dm + bias;
P = 1 ./ ( 1 + exp( -1/sigma/sqrt(2) * dQ ));
lP1 = log(P(c5==1));
lP0 = log(1-P(c5==-1));
lP1 = lP1(~isnan(lP1));
lP0 = lP0(~isnan(lP0));
if priorFlag
    L_noise = exponentialPrior(sigma, 1/20);
    LL = -(sum(lP1)+sum(lP0) + L_noise);
else
    LL = -(sum(lP1)+sum(lP0));
end