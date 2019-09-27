/* PS1 Code: Data formats and conversion */
/* The purpose of this code is to load, convert, and cursorily examine a dataset from online */
/* Task 1: Load data from online */

//good preamble

*First, the usual

//good yes first the usual

clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text

/* Task 5 completed here */
cap mkdir ~\DataManagementRP
cd ~\DataManagementRP

log using PS1.txt, replace

*Next, where is the data?
/* Upload the data to git and then make Stata download it from there, yeehaw */

*Donde esta el datos?

/* Task 2: Use your dataset */
/* Task 3: Write code to read these data into Stata and save it in 3 different formats */
*Aqui!
insheet using https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/crash_data_collision_crash_2007_2017.csv, clear

*Un-delimit the file, save in 3 formats
outsheet using crashPHL.csv, replace comma nolabel //yes
outsheet using crashPHL.xls, replace comma nolabel //no for excel syntax is different!
outsheet using crashPHL, replace comma nolabel //this is just csv as in first, need to save as sth different plus give it right extension like .tab

/* Task 4: Have a look at your data via basic descriptives */

import delimit using crashPHL, clear
count //goood
*That's a lot of data
d

*That's a lot of variables that we probably don't care about
keep crn time_of_day collision_type fatal_count injury_count person_count latitude longitude automobile_count motorcycle_count bus_count small_truck_count heavy_truck_count suv_count van_count bicycle_count tot_inj_count mcycle_death_count mcycle_maj_inj_count bicycle_death_count bicycle_maj_inj_count ped_count ped_death_count ped_maj_inj_count comm_veh_count dec_long dec_lat

*Yikes, there was probably a better way to do that. //good
outsheet using crashPHLtrim.csv, replace comma nolabel

*Still looking at the data...
ta injury_count
*Looks like this variable is heavily positively skewed. //good to comment observations, yes 92% are 0-2
ta fatal_count
*This variable is also heavily positively skewed!

/* Task 5: cd to working dir, avoid using paths */
*Completed above!

/* Task 6: preamble and comments! */
*Completed throughout!

//overall nice except saving, just did correctly first one in csv--please look back at dofile from the class

/*
per poster: pls ask dan for more datasources, he's very much data oriented; and lets talk more about this research
mike hays from my dept did similar research; and i have an mpa student in another class who just got these data
https://force.nj.com/
*/
