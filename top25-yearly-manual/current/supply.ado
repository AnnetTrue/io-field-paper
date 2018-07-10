program supply
	version 15
	syntax varlist if, at(name) [derivatives(varlist)]
	quietly {
	
		forval i=1/25 {
			tempvar share`i' delta`i'
		}
		tempvar id mc markup lnmc margins blah
		
		sort year firm brand model
		//gen unique id for each model in a year
		by year: gen `id'=[_n]

		// generate "matrix" of shares
		forval j=1/25 {
			gen `share`j''=.	
			by year: replace `share`j''=share[`j']
		}

		// generate Delta "matrix"
		forval j=1/25 {
			gen `delta`j''=0
			by year: replace `delta`j''=(firm==firm[`j'])
			qui replace `delta`j''=-`at'[1,1]*share*(1-share) if `id'==`j'
			qui replace `delta`j''=`at'[1,1]*share`j'*share if `delta`j''==1&`id'!=`j'
			*by year: gen el`j'=-delta`j'*price[id==`j']/share
		}

		// calculates markups in Mata
		forval j=2013/2017 {
			putmata Delta=(`delta1'-`delta25') if year==`j', replace
			putmata s=tilde_share if year==`j', replace
			mata res`j'=luinv(Delta)*s
			if `j'==2013 mata res=res`j'
			if `j'>2013 mata res=res\res`j'
		}

		getmata `markup'=res, replace
		gen `mc'=tilde_price-`markup'
		gen `margins'=`markup'/price
		gen `lnmc'=log(`mc')
		
		
		local exog_char "engine horsepower fuelcons clearance trunk russia" 
		gen `blah'=engine*`at'[1,2]+horsepower*`at'[1,3]+fuelcons*`at'[1,4]+clearance*`at'[1,5]+trunk*`at'[1,6]
		replace `varlist'=lnmc-`blah'-`at'[1,7]
		
		if "`derivatives'" == "" {
			exit                    // no, so we are done
		}
		
		replace `derivatives'=
	}
end
   
