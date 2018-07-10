function f=obj3(p1, counter)
global mc Delta_merge1 Delta_merge2 j merger lns alpha p k
if merger==1
    Delta_aux=Delta_merge1;
else Delta_aux=Delta_merge2;
end
    kk1=zeros(94, 1);
    kk1(k, 1)=1;
    pp1=kron(kk1, p1);
    expdelta=exp(lns+alpha*(p-pp1));
    summ=expdelta'*kron(eye(94), ones(24, 1));
    shr=expdelta./(ones(2256, 1)+kron(summ', ones(24, 1)));
    f=shr(j:(j+23),1)-Delta_aux(j:(j+23),j:(j+23))*(p1-mc(j:(j+23),1));
    f=sum(f.^2);
end