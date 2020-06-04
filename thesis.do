*The purpose of this code is to clean and analyze thesis data

***** MERGE AND CLEAN DATA *****

clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text
cap mkdir ~\Desktop\DataManagementRP
cd ~\Desktop\DataManagementRP
log using thesis.txt, replace

insheet using "TTAcontrol.csv", clear
save control, replace
insheet using "TTAlow.csv", clear
save low, replace
insheet using "TTAhigh.csv", clear
save high, replace
use control, clear

append using low
append using high
rename reactiontime rt

label define group 0 "Control" 1 "Low tempo" 2 "High tempo"
label values group group
*Code movieid: 0 = 25 MPH, one second; 1 = 25 MPH, two seconds; 2 = 45 MPH, one second; 3 = 45 MPH, two seconds
label define movieid 0 "25 OSB" 1 "25 TSB" 2 "45 OSB" 3 "45 TSB"
label values movieid movieid
gen mask=0
replace mask=1 if movieid==0|movieid==2
replace mask=2 if movieid==1|movieid==3
gen speed=0
replace speed=1 if movieid==0|movieid==1
replace speed=2 if movieid==2|movieid==3
label define m 1 "One second blackout" 2 "Two second blackout"
label define s 1 "25 MPH" 2 "45 MPH"
label values mask m
label values speed s
save TTAmaster, replace

***** ANALYSES *****

cd ~\Desktop\DataManagementRP
use TTAmaster, clear
edit
drop if rt<-5000
*need to remove PID 1, as >50% of their observations were dropped
drop if pid==1
*Let's take a look at RT
histogram rt
*Create means table
table group speed mask, c(mean rt sd rt)
collapse rt mask speed group, by (pid block movieid)

label values group group
label values mask m
label values speed s
gen music=1
replace music=0 if group==0
save TTAblocklev, replace
outsheet using TTAblocklev.csv, replace

collapse rt mask speed group, by (pid movieid)
label values group group
label values mask m
label values speed s
save TTAidlev, replace

outsheet using TTAidlev.csv, replace

use TTAanalysis, clear
*Hypothesis testing: 
*Is there a significant difference in TTA error between tempo conditions?
anova rt group
*Significant! F(2, 557) = 11.26, p < .001
regress, baselevels
*This might not be the best way to report on this data/post hoc observations. LOOK INTO THIS

*Is there a sig dif between music and no music?

**Not paired samples, as music is between subject variable!
ttest rt, by(music)
*Mean(SD) No Music: -144.35 (1297.59) | Music: 28.81 (904.25)
*Significant! t (558) = -1.85, p = .06

*Is there a sig dif between masking duration?
ttest rt, by(mask)
*Mean(SD) 1 second: -26.67(1039.69) | 2 seconds: -74.03(1166.09)
*Not significant! t(558) = .51, p = .61

*Is there a sig dif between speed?
ttest rt, by(speed)
*Mean(SD) 25 MPH: -214.84(1221.20) | 45 MPH: 114.15(946.69)
*Significant! t(558) = -3.56, p < .001

*Is there a sig interaction between speed and masking duration?
anova rt speed##mask
*Not significant! F (1, 556) = .51, p = .47

*Is there a sig int between speed and tempo?
anova rt speed##group
*Not significant! F(2, 554) = .71, p = .49

*Is there a sig int between masking duration and tempo?
anova rt mask##group
*Not significant! F(2, 554) = .31, p = .73

*Is there a sig int between speed, tempo, and masking duration?
anova rt mask##speed##group
*Not significant! F(2, 548) = .01, p = .99

*Better data management/analysis:
use TTAanalysis, clear
