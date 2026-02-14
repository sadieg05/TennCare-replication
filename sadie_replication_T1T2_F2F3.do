*******************************************************
* sadie_replication_T1_T2_F2_F3.do
* Reproduces: Table I, Table II (Panels A & B), Figures 2 & 3
* Modification: Table II uses CLUSTERED SEs (not bootstrap)
* Control-group switch: "south" (authors) vs "border" (extension)
*******************************************************

clear all
set more off
pause off
version 12

*******************************************************
* 0) Directory + control-group switch
*******************************************************
cd "/Users/sadieahern/Downloads/replication package-PHI"
cap mkdir output

local CONTROL "border"     // "south" or "border"
local TAG "`CONTROL'"

cap log close
log using "output/sadie_replication_`TAG'.log", replace text

*******************************************************
* Helper: sample flags + core policy vars (authors-style)
*******************************************************
capture program drop build_sample_flags
program define build_sample_flags
    args control

    * Authors' SOUTH list (includes TN)
    gen byte south = ///
      (statefip == 54 | statefip == 24 | statefip == 10 | statefip == 11 | ///
       statefip == 21 | statefip == 47 | ///
       statefip == 37 | statefip == 51 | statefip == 45 | statefip == 13 | ///
       statefip ==  5 | statefip == 22 | statefip == 48 | statefip == 40 | ///
       statefip ==  1 | statefip == 28 | statefip == 12 )

    gen byte tn   = (statefip == 47)
    gen byte post = (year >= 2006)
    gen byte tn_X_post = tn*post

    * Border states of TN: AL(1), AR(5), GA(13), KY(21), MS(28), MO(29), NC(37), VA(51)
    gen byte border = inlist(statefip, 1,5,13,21,28,29,37,51)

    gen byte insample = 0
    if "`control'" == "south" {
        replace insample = (south==1)
    }
    else if "`control'" == "border" {
        replace insample = (tn==1 | border==1)
    }
    else {
        di as error "Unknown CONTROL option: `control'"
        error 198
    }
end

*******************************************************
* Helper: authors' collapse routine (from fragment-run-our-bbs-procedure.do)
* - DD collapses to year x statefip x tn
* - DDD collapses to year x statefip x nokid x tn
* - insurance any_* collapsed with hinswt and shifted year = year - 1
*******************************************************
capture program drop our_collapse
program define our_collapse
    args model

    tempfile rest
    save `rest', replace

    if "`model'" == "dd" {
        collapse (mean) working unemp ilf hrs_lw_* hrswork wage* ///
            [aw=wtsupp], by(year statefip tn) fast
        tempfile workDD
        save `workDD', replace

        use `rest', clear
        collapse (mean) any_* [aw=hinswt], by(year statefip tn) fast
        replace year = year - 1

        sort year statefip tn
        merge 1:1 year statefip tn using `workDD'
        drop _merge
    }
    else if "`model'" == "ddd" {
        collapse (mean) working unemp ilf hrs_lw_* hrswork wage* ///
            [aw=wtsupp], by(year statefip nokid tn) fast
        tempfile workDDD
        save `workDDD', replace

        use `rest', clear
        collapse (mean) any_* [aw=hinswt], by(year statefip nokid tn) fast
        replace year = year - 1

        sort year statefip nokid tn
        merge 1:1 year statefip nokid tn using `workDDD'
        drop _merge
    }
    else {
        di as error "our_collapse only supports dd or ddd here."
        error 198
    }

    keep if inrange(year,2000,2007)
    gen byte post = (year >= 2006)
end

*******************************************************
* 1) TABLE I (authors-style summary stats)
*******************************************************
use "dta/cps_MICRO_FINAL.dta", clear
keep if year >= 1998
keep if age  >= 21

build_sample_flags "`CONTROL'"

* Authors create agebin (so we do too)
gen byte agebin = 0*(age>=21 & age<40) + 1*(age>=40 & age<65)

preserve
    keep if insample==1
    keep if age>=21 & age<65

    * race groups
    gen byte white = (race==100)
    gen byte black = inlist(race,200,801,805,806,807)
    gen byte other = 1 - white - black

    * any college
    gen byte any_college = (smc1==1 | smc2==1 | col==1)

    * kid indicator (authors use nokid elsewhere; keep kid as-is for table)
    * if kid is 0/1 already, this is fine:
    gen byte kid_bin = (kid==1)

    * store table I like your assignment-friendly outputs
    tempname H1
    postfile `H1' str40 varname double mean_tn mean_ctrl using "output/table1_summary_stats_`TAG'.dta", replace

    foreach v in any_public any_private {
        quietly sum `v' [aw=hinswt] if tn==1 & inrange(year,2001,2008)
        local m1 = r(mean)
        quietly sum `v' [aw=hinswt] if tn==0 & inrange(year,2001,2008)
        local m0 = r(mean)
        post `H1' ("`v'") (`m1') (`m0')
    }

    foreach v in working hrs_lw_lt20 hrs_lw_2035 hrs_lw_ge35 {
        quietly sum `v' [aw=wtsupp] if tn==1 & inrange(year,2000,2007)
        local m1 = r(mean)
        quietly sum `v' [aw=wtsupp] if tn==0 & inrange(year,2000,2007)
        local m0 = r(mean)
        post `H1' ("`v'") (`m1') (`m0')
    }

    foreach v in kid_bin agebin female {
        quietly sum `v' [aw=wtsupp] if tn==1 & inrange(year,2000,2007)
        local m1 = r(mean)
        quietly sum `v' [aw=wtsupp] if tn==0 & inrange(year,2000,2007)
        local m0 = r(mean)
        post `H1' ("`v'") (`m1') (`m0')
    }

    foreach v in hsd hsg any_college {
        quietly sum `v' [aw=wtsupp] if tn==1 & inrange(year,2000,2007)
        local m1 = r(mean)
        quietly sum `v' [aw=wtsupp] if tn==0 & inrange(year,2000,2007)
        local m0 = r(mean)
        post `H1' ("`v'") (`m1') (`m0')
    }

    foreach v in white black other {
        quietly sum `v' [aw=wtsupp] if tn==1 & inrange(year,2000,2007)
        local m1 = r(mean)
        quietly sum `v' [aw=wtsupp] if tn==0 & inrange(year,2000,2007)
        local m0 = r(mean)
        post `H1' ("`v'") (`m1') (`m0')
    }

    postclose `H1'
restore

use "output/table1_summary_stats_`TAG'.dta", clear
format mean_tn mean_ctrl %9.4f
save, replace
export delimited using "output/table1_summary_stats_`TAG'.csv", replace

*******************************************************
* 2) TABLE II (Panels A & B) —  CLUSTERED SEs
*******************************************************
use "dta/cps_MICRO_FINAL.dta", clear
keep if year >= 1998
keep if age  >= 21

build_sample_flags "`CONTROL'"

* Authors DDD setup vars
gen byte nokid = (1 - kid)

* Apply authors sample restriction
keep if insample==1
keep if age>=21 & age<65

tempname H2
postfile `H2' str1 panel str25 outcome double b se p r2 mean_dv using ///
    "output/table2_TableII_PanelsAB_`TAG'.dta", replace

local outcomes "any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 any_empl_wk"

* ----- Panel A: DD -----
preserve
    our_collapse dd
    gen byte tn_X_post = tn*post

    quietly xi i.year i.statefip
    foreach y of local outcomes {
        quietly reg `y' tn_X_post _I*, vce(cluster statefip)
        local b  = _b[tn_X_post]
        local se = _se[tn_X_post]
        local p  = 2*abs(ttail(e(df_r), abs(`b'/`se')))
        local r2 = e(r2)

        quietly sum `y' if e(sample)
        local mdv = r(mean)

        post `H2' ("A") ("`y'") (`b') (`se') (`p') (`r2') (`mdv')
    }
restore

* ----- Panel B: DDD -----
preserve
    our_collapse ddd
    gen byte tn_X_post_X_nokid = tn*post*nokid

    quietly xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip
    foreach y of local outcomes {
        quietly reg `y' tn_X_post_X_nokid _I*, vce(cluster statefip)
        local b  = _b[tn_X_post_X_nokid]
        local se = _se[tn_X_post_X_nokid]
        local p  = 2*abs(ttail(e(df_r), abs(`b'/`se')))
        local r2 = e(r2)

        quietly sum `y' if e(sample)
        local mdv = r(mean)

        post `H2' ("B") ("`y'") (`b') (`se') (`p') (`r2') (`mdv')
    }
restore

postclose `H2'

use "output/table2_TableII_PanelsAB_`TAG'.dta", clear
format b se p r2 mean_dv %9.4f
save, replace
export delimited using "output/table2_TableII_PanelsAB_`TAG'.csv", replace
list, clean

*******************************************************
* 3) FIGURES 2 & 3 
*******************************************************

preserve
    cd "do"
    cap noisily do "create-cps-figures.do"
    cd ".."
restore

*******************************************************
* FIGURE 2: Insurance (DiD + Triple Diff)
*******************************************************
cap graph use "gph/any_public.gph"
cap graph export "output/Figure2A_any_public_DiD_`TAG'.png", replace

cap graph use "gph/any_public_kid.gph"
cap graph export "output/Figure2B_any_public_DDD_`TAG'.png", replace

*******************************************************
* FIGURE 3: Labor (DiD + Triple Diff)
*******************************************************
cap graph use "gph/working.gph"
cap graph export "output/Figure3A_working_DiD_`TAG'.png", replace

cap graph use "gph/working_kid.gph"
cap graph export "output/Figure3B_working_DDD_`TAG'.png", replace


log close
display "DONE. Outputs in output/ (tag = `TAG')"
