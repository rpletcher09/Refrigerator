//This code is to MAKE A COMPREHENSIVE DAMN DATASET for our FAMCO data :)

*First, the usual: code from PS1
clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text
cap mkdir ~\Desktop\DataManagementRP
cd ~\Desktop\DataManagementRP
log using Medialab.txt, replace

*Macros
global d destring PID, replace
global c drop if PID==.

*Code
local n "CCC"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

local n "CF2C"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

append using CCC
save master, replace

local n "FIM"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "FSN"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "FTC"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "SF"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "UPLF"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "FS"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

*Holy shit. FS tab added over 1 million observations.

drop if PID==""
save master, replace

*Cleared. Continuing...

local n "FEN"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "CF"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "HSJ"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "FCN"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

local n "Network"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

*Okay. All collabs labeled, all PIDs checked. Let's bring in the matching families.

local n "Match"
import excel using "FamilyDatabase.xlsx", sheet(`n') all first clear
gen str collab="`n'"
save "`n'", replace

use master, clear
append using "`n'"
save master, replace

*Okay. Let's clean again.

drop if PID==""
save master, replace

order collab

keep collab FID PID FM NameofParticipant Baseline
$d
sort PID, stable
save masterLite, replace

*Bring in new data to clean, then merge

*1 A's

local n "1 A1"
import excel using "`n'.xlsx", sheet("1") all first clear
keep Subject Cond Date baseline family family_role participant_id
rename participant_id PID
$d
save "`n'", replace

local n "1 A1"
import excel using "`n'.xlsx", sheet("unknown") all first clear
keep Subject Cond Date baseline family family_role participant_id
rename participant_id PID
$d
save "`n'u", replace

use "1 A1", clear
append using "1 A1u"
sort PID, stable
save "1 A1", replace

local n "1 A2"
import excel using "`n'.xlsx", sheet("1") all first clear
keep Subject Cond Date
rename Subject PID
$d
save "`n'", replace

local n "1 A2"
import excel using "`n'.xlsx", sheet("unknown") all first clear
keep Subject Cond Date
rename Subject PID
$d
save "`n'u", replace

use "1 A2", clear
append using "1 A2u"
sort PID, stable
gen str family_role="2"
save "1 A2", replace

*2 A's

local n "2 A1"
import excel using "`n'.xlsx", sheet("1") all first clear
keep Subject Cond Date baseline family family_role participant_id
rename participant_id PID
$d
save "`n'", replace

local n "2 A1"
import excel using "`n'.xlsx", sheet("unknown") all first clear
keep Subject Cond Date baseline family family_role participant_id
rename participant_id PID
$d
save "`n'u", replace

use "2 A1", clear
append using "2 A1u"
sort PID, stable
save "2 A1", replace

local n "2 A2"
import excel using "`n'.xlsx", sheet("1") all first clear
keep Subject Cond Date
rename Subject PID
gen str family_role="2"
$d
save "`n'", replace

use "1 A2", clear
append using "2 A2"
sort PID, stable
save "A2m", replace

use "1 A1", clear
append using "2 A1"
sort PID, stable
save "A1m", replace

append using "A2m"
save "Am", replace
drop if PID==.
sort PID, stable

*Clean up Am dataset

duplicates list
duplicates drop
destring Subject, replace
replace PID=Subject if PID==99
drop Subject
drop if PID==999
drop if PID==9999
drop if PID==99999
drop if PID==1
rename family FID
rename Cond target
save AmC, replace

merge m:1 PID using masterLE
*replace family_role=FM if _merge==3
drop if _merge!=3

replace FM=subinstr(FM, "Adult", "", .)
replace FM=subinstr(FM, "Adutl", "", .)
replace FM=subinstr(FM, "A", "", .)
replace FM=subinstr(FM, " ", "", .)

gen Astatus=0
replace Astatus=1 if family_role!=FM
gen Tstatus=0
replace Tstatus=1 if target=="2" & collab!="Match"
replace Tstatus=1 if target=="1" & collab=="Match"

generate date=date(Baseline, "MDY")
replace date=date(Baseline, "DMY") if date==.
format date %td
rename date BaselineDate

generate respDate=date(Date, "MDY")

*Pilfered code: cleans excel date codes & turns them into a Stata %td-able format
gen calldate2=Date
gen date_excel = calldate2 if  regexm(calldate2, "^4") == 1 & regexm(calldate2, "[0-9][0-9][0-9][0-9)[0-9]") == 1
destring(date_excel), replace
replace date_excel = date_excel + td(30dec1899)
*End pilfered code

replace respDate=date_excel if respDate==.
format respDate %td
drop calldate2 date_excel

gen Bstatus=0
replace Bstatus=1 if respDate-BaselineDate>90

save cleaning, replace