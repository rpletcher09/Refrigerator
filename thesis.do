*The purpose of this code is to clean and analyze my thesis data

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
save TTAmaster, replace

use TTAmaster, clear
collapse reactiontime group, by (pid block movieid)
label values group group