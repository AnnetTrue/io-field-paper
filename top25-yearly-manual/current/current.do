use "/Users/Anna/Documents/IO field paper/Data/current"

local exog_char "horsepower fuelcons clearance trunk russia" 
local exog "`exog_char'"
local iv_fm "horsepower_fm fuelcons_fm clearance_fm trunk_fm"
local iv_iv " horsepower_iv fuelcons_iv"
local iv " `iv_iv'"

local iv_dm "horsepower_iv fuelcons_iv"
local iv_sp "horsepower_iv fuelcons_iv trunk_iv"

local brand "brand7"
qui ds brand1-brand16
local brandlist=r(varlist)
local brandlist : list brandlist-brand

local exog_dm "horsepower fuelcons russia"
local exog_sp "horsepower fuelcons russia trunk"

ivregress gmm logshare (price=`exog_dm' `iv') `exog_dm'
di _b[price]

gmm	(supply: log(tilde_price + markup_pure2/{a=0.005})- {supply:`exog_sp' _cons} ) ///
	(demand: logshare - {demand:`exog_dm' _cons} + {a=0.005}*price) ///
	, instruments(demand:`exog_dm' `iv_dm') instruments(supply:`exog_sp' `iv_sp') ///
    derivative(supply /supply=-1) derivative(supply /a=markup_pure2/{a}^2) ///
	 derivative(demand /demand=-1) derivative(demand /a=price) ///
	 winitial(identity) onestep
*gmm	(supply: log(tilde_price - markup_pure2/{a=0.005})- {supply:`exog' _cons} ) ///
*	(demand: logshare - {demand:`exog' _cons} + {a=0.005}*price) ///
*	, instruments(`exog' `iv') derivative(/demand=-1) ///
*    derivative(supply /supply=-1) derivative(supply /a=markup_pure2/{a}^2) ///
*	 derivative(demand /demand=-1) derivative(demand /a=price) ///
*	 winitial(identity) onestep




qui ivregress 2sls logshare (`price'=`iv') `exog'
di _b[`price']

gmm	(supply: price - {supply:`exog' _cons} - ss*{a}), derivative(/supply=-1) derivative(/a=-ss) instruments(`exog' `iv')
di 1/_b[/a]
*gmm	(supply: price - {supply:`exog' _cons} - ss/{a=100000}), derivative(/supply=-1) derivative(/a=ss/{a}^2) instruments(`exog' `iv')
*gmm	(supply: price - {supply:`exog' _cons} - ss*exp(-{a=1})), derivative(/supply=-1) derivative(/a=-ss*exp({a})) instruments(`exog' `iv')

ivregress gmm price `exog' (ss=`iv')

*gmm	(supply: price - {supply:`exog' _cons} - markup_pure/{a=100000}), derivative(/supply=-1) derivative(/a=markup_pure/{a}^2) instruments(`exog' `iv')

gmm	(supply: log(price - markup_pure2*{a=-1}) - {supply:`exog' _cons} ), derivative(/supply=-1) derivative(/a=markup_pure) instruments(`exog' `iv')
