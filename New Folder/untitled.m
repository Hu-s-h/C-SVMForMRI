% x = [-15:0.01:15];
% y = 1-(1+max(0,x))./(2+abs(x));
% k = 0.*x;
% m = 0:0.01:1;
% plot(x,y,x,k,'--',0.*m,m,'--');
% % xlabel('u','Fontname', 'Times New Roman','FontSize',12);
% % ylabel('loss','Fontname', 'Times New Roman','FontSize',12);
% legend("Chinge'gradient");
% axis([-15 15 0 1]) 
a=[];
a.q=1;
a.w=2;

w = aaa(a);
disp(a.w);
disp(w);

function w = aaa(a)
a.w=1;
w=a.w;
end