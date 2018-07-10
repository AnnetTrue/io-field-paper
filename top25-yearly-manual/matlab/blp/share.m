function f=share(p1)
global lns alpha p
expdelta=exp(lns+alpha*(p-p1));
summ=expdelta'*kron(eye(94), ones(24, 1));
f=expdelta./(ones(2256, 1)+kron(summ', ones(24, 1)));
end