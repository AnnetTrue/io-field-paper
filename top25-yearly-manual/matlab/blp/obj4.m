function f=obj4(p1)
global mc x2 Delta_merge1 Delta_merge2 k j merger pred_meanval alpha0 p theta2w
kk1=zeros(94, 1);
kk1(k, 1)=1;
pp1=kron(kk1, p1);
delta=pred_meanval-alpha0*(p-pp1);
x2new=[x2(:,1),pp1, x2(:,3:4)];
mu=mufunc(x2new, theta2w);
shr=mktsh(exp(delta), exp(mu));

if merger==1
    Delta_aux=Delta_merge1;
else Delta_aux=Delta_merge2;
end
    f=shr(j:(j+23),1)-Delta_aux(j:(j+23),j:(j+23))*(p1-mc(j:(j+23),1));
    f=sum(f.^2);
end