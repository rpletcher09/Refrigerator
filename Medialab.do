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