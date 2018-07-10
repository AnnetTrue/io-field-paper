

*************************** COUNTERFACTUAL ***************************
sort year brand model
by year: gen id=[_n]
forval j=1/25 {
	gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

forval j=1/25 {
	gen delta`j'=0
	* change brand to company producing brand
	by year: replace delta`j'=(brand==brand[`j'])
	qui replace delta`j'=-`alpha'*share*(1-share) if id==`j'
	qui replace delta`j'=`alpha'*share`j'*share if delta`j'==1&id!=`j'
	*by year: gen el`j'=-delta`j'*price[id==`j']/share
}


forval j=2013/2017 {
	putmata Delta=(delta1-delta25) if year==`j', replace
	putmata s=share if year==`j', replace
	mata res`j'=luinv(Delta)*s
	if `j'==2013 mata res=res`j'
	if `j'>2013 mata res=res\res`j'
}

getmata markup=res, replace
gen mc=price-markup
gen margins=markup/price

** 4)
sort year brand model
by year: gen id=[_n]
forval j=1/25 {
	gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

forval j=1/25 {
	gen delta`j'=0
	* change brand to company producing brand
	by year: replace delta`j'=(brand==brand[`j'])
	qui replace delta`j'=-`alpha'*share*(1-share)/price if id==`j'
	qui replace delta`j'=`alpha'*share`j'*share/price if delta`j'==1&id!=`j'
	*by year: gen el`j'=-delta`j'*price[id==`j']/share
}


forval j=2013/2017 {
	putmata Delta=(delta1-delta25) if year==`j', replace
	putmata s=share if year==`j', replace
	mata res`j'=luinv(Delta)*s
	if `j'==2013 mata res=res`j'
	if `j'>2013 mata res=res\res`j'
}

getmata markup=res, replace
gen mc=price-markup
gen margins=markup/price
