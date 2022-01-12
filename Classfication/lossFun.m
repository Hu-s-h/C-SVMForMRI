function [f,df] = lossFun(X,y,ClassOpt)
    f=@(w) cost(w,X,y,ClassOpt);
    df=@(w) grad(w,X,y,ClassOpt);
end

function p=decision_function(w,X)
    p=X*w;
end

function m=margin(w,X,y)
    m=y.*decision_function(w,X);
end

function f=cost(w,X,y,ClassOpt)
    m=margin(w,X,y);
    if ClassOpt.isbias==1
        w1=w(1:end-1);
    else
        w1=w;
    end
%     1-(1+max(0,x))/(2+abs(x))
    if strcmp(ClassOpt.classifier,'hinge')
        f=norm(w1)^2/2+ClassOpt.C*sum(max(1-m,0));
    elseif strcmp(ClassOpt.classifier,'chinge')
        f=norm(w1)^2/2+ClassOpt.C*sum(max(-m,0)-log(2+abs(m)));
    elseif strcmp(ClassOpt.classifier,'least')
        f=norm(w1)^2/2+ClassOpt.C*norm(y-X*w)^2/2;
    elseif strcmp(ClassOpt.classifier,'logreg')
        hypothesis=1./(1+exp(-(X*w)));  %logistic function
        f=norm(w1)^2/2-sum(log(hypothesis+0.001).*y+(1-y).*log(1-hypothesis+0.001));%0.001 is added to prevent hypothesis=0
    else
        error('only support hinge,chinge,least,logreg.')
    end
end

function df=grad(w,X,y,ClassOpt)
    m=margin(w,X,y);
    if strcmp(ClassOpt.classifier,'hinge')
        df=w-ClassOpt.C*X(m<1,:)'*y(m<1);
        if ClassOpt.isbias==1
            df(end)=-ClassOpt.C*sum(y(m<1));
        end
    elseif strcmp(ClassOpt.classifier,'chinge')
        P=1-(1+max(0,m))./(2+abs(m));
        df=w-ClassOpt.C*X'*(y.*P);
        if ClassOpt.isbias==1
            df(end)=-ClassOpt.C*sum(y.*P);
        end
    elseif strcmp(ClassOpt.classifier,'least')
        df=w-ClassOpt.C*X'*(y-X*w);
    elseif strcmp(ClassOpt.classifier,'logreg')
        hypothesis=1./(1+exp(-(X*w)));  %logistic function
        df =w-ClassOpt.C*X'*(y-hypothesis);
    else
        error('only support hinge,chinge,least,logreg.')
    end
end



