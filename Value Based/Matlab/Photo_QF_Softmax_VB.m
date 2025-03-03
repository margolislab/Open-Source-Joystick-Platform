function [choiceProbabilities,Qvalues,rpe] = Photo_QF_Softmax_VB(alpha,beta,choices,rewards,flags)

%Joel Woolley courtesy

%% Train Weights
Qvalues = zeros(numel(choices),2); 
rpe = zeros(numel(choices),2);
decayOn1 = 0;
decayOn2 = 0;

for n = 1:(numel(choices)-1)
    if flags(n,1) == 1
        Qvalues(n,1) = 4;
        Qvalues(n,1) = 4; 
    end
    %compute reward prediction error (rpe)
    switch choices(n)
        case 0
            rpe(n,1) = (0);
            rpe(n,2) = (0);
        case 1
            rpe(n,1) = (rewards(n,1)) - Qvalues(n,1); %compute rpe (negative rpe for 0uL rewards
            rpe(n,2) = (0);
            decayOn1 = 0;
            decayOn2 = 1; %Joel
        case 2
            rpe(n,1) = (0); %compute rpe (negative rpe for 0uL rewards)
            rpe(n,2) = rewards(n,2) - Qvalues(n,2);
            decayOn1 = 1; %Joel
            decayOn2 = 0; 
    end
    Qvalues(n+1,1) = Qvalues(n,1) + alpha*rpe(n,1) + decayOn1*((Qvalues(n,1)*(1-alpha))-Qvalues(n,1)); %Joel
    Qvalues(n+1,2) = Qvalues(n,2) + alpha*rpe(n,2) + decayOn2*((Qvalues(n,2)*(1-alpha))-Qvalues(n,2)); %Joel

end

choiceProbabilities = zeros(numel(choices),2);

for i=1:numel(choices)
    choiceProbabilities(i,1)= 1/...
        ( 1+exp(1)^-(beta*(Qvalues(i,1)-Qvalues(i,2))) );
    
    choiceProbabilities(i,2)= 1/...
        ( 1+exp(1)^-(beta*(Qvalues(i,2)-Qvalues(i,1))) );
end
