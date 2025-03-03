%% Compare Model Fit
function [likelihood]=compareModelFit_Photo(alpha,beta,choices,rewards,flags)

    %% Check Model Fit    

    [choiceProbabilities, ~,~]=Photo_QF_Softmax_VB(alpha,beta,choices,rewards,flags);

    %% Negative log likelihood
% The log likelihood for each choice is calculated. Then we inverse the
% result so that the minimization function will maximize the likelihood.
    likelihood=0;
    for i = 1:numel(choices)
        switch choices(i)
            case 0 
                %omitted choice. No change to likelihood
            case 1 
                likelihood=likelihood+ log(choiceProbabilities(i,1));
            case 2
                likelihood=likelihood+ log(choiceProbabilities(i,2));
        end
    end
    likelihood=-likelihood;
    
end