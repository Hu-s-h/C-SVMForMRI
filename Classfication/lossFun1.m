function [f,df] = lossFun1(X,y,ClassOpt)
    f=@(w) cost(w,X,y,ClassOpt);
    df=@(w) grad(w,X,y,ClassOpt);
end

function df=grad(w,X,y,ClassOpt)
    if strcmp(ClassOpt.classifier,'hinge')
        T=max(1-y.*(X*w),0);
        df=-X'*(T.*y)/size(X,1);
    elseif strcmp(ClassOpt.classifier,'chinge')
        yp=y.*(X*w);
        P=1-(1+max(0,yp))./(2+abs(yp));
        df=-(X)'*(y.*P)/size(X,1);
    elseif strcmp(ClassOpt.classifier,'least')
        df=-X'*(y-X*w)/size(X,1);
    elseif strcmp(ClassOpt.classifier,'logreg')
        y1=(y==1);
        hypothesis=1./(1+exp(-(X*w)));  %logistic function
        df =-X'*(y1-hypothesis)/size(X,1);
    else
        error('only support hinge,chinge,least,logreg.')
    end
    df(1:end-1)=df(1:end-1)+ClassOpt.C*w(1:end-1);
end

function f=cost(w,X,y,ClassOpt)
    if strcmp(ClassOpt.classifier,'hinge')
        T=max(1-y.*(X*w),0);
        f=sum(sum(T.^2))/size(X,1)/2;
    elseif strcmp(ClassOpt.classifier,'chinge')
        yp=y.*(X*w);
        f=sum(sum(max(0,-yp)-log(2+abs(yp))+log(2)))/size(X,1);
    elseif strcmp(ClassOpt.classifier,'least')
        f=norm(y-X*w)^2/size(X,1)/2;
    elseif strcmp(ClassOpt.classifier,'logreg')
        y1=(y==1);
        hypothesis=1./(1+exp(-(X*w)));  %logistic function
        f=-sum(log(hypothesis+0.001).*y1+(1-y1).*log(1-hypothesis+0.001))/size(X,1);%0.001 is added to prevent hypothesis=0
    else
        error('only support hinge,chinge,least,logreg.')
    end
    f=f+ClassOpt.C*norm(w(1:end-1))^2/2;
end
