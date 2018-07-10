function f=obj3(p1, cntr)
    delta0=cntr.delta0;
    alpha=cntr.alpha;
    p0=cntr.price0;
    Delta=cntr.Delta;
    mc=cntr.mc;
    
    expdelta=exp(delta0+alpha*(p0-p1));
    shr=expdelta/(1+sum(expdelta));
    shr=shr./(1+cntr.tariff);
    f=shr-Delta*(p1./(1+cntr.tariff)-mc);
    f=f*1000000;
    %f=sum(f.^2)*1000;
end