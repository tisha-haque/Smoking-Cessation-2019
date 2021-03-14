* Tisha Haque
tnh2115
Master's Thesis Code;

*1. IMPORT SPREADSHEET (I HAD TO USE A CSV FORMAT);
proc import out=thesis_data datafile="/home/u45142172/sasuser.v94/Internship 2020/SAS-working file 2.xlsx"
DBMS=xlsx REPLACE;
run;

*2.Clean out variables: Create a categorical variable for Age
age 21-44 is used as the reference group
older group has the higher dx;

data thesis_data2;
set thesis_data;

if (21 <= age <= 44) then age_flag =0;
else if (age >= 45) then age_flag =1;

run;

*3. Create a categorical variable for Gender
Male is used as reference group using information in CDC;

data thesis_data3;
set thesis_data2;

if gender= "M" then gender_flag=0;
else if gender= "F" then gender_flag=1;

run;

*4. Create a categorical variable for QARR Region
Long island is used as the reference group since it has the most amount of dx;

data thesis_data4;
set thesis_data3;

if (QARR_Region="Long Island") then QARR_flag= 0;
else if (QARR_Region="Central") then QARR_flag= 1;
else if (QARR_Region="Northeast") then QARR_flag= 2;
else if (QARR_Region= "Hudson Valley") then QARR_flag= 3;
else if (QARR_Region= "Western") then QARR_flag= 4;
else if (QARR_Region= "New York City") then QARR_flag= 5;

run;

*5. Create a categorical variable for Health Insurance
exposure variable lower tier as reference;

data thesis_data5;
set thesis_data4;

if (Health_insurance= "Fidelis Care Bronze") 
or (Health_insurance= "Fidelis Care Bronze Limited Cost Sharing") 
or (Health_insurance="Fidelis Care Catastrophic Coverage") 

then HI_flag=0;

else if 
(Health_insurance= "Fidelis Care Silver") 
or (Health_insurance= "Fidelis Care Silver 150") 
or (Health_insurance= "Fidelis Care Silver 200") 
or (Health_insurance= "Fidelis Care Silver 250") 
or (Health_insurance= "Fidelis Care Silver Limited Cost Sharing") 
or (Health_insurance= "Fidelis Care Silver Zero Cost Sharing") 
or (Health_insurance= "Fidelis Care Zero Cost Sharing") 
or (Health_insurance= "Fidelis Care Gold") 
or (Health_insurance= "Fidelis Care Gold Limited Cost Sharing") 
or (Health_insurance= "Fidelis Care Platinum") 
or (Health_insurance= "Fidelis Care Platinum Limited Cost Sharing") 

then HI_flag=1;

run;


*6. Create a categorical variable for the Medication/Counseling (Binary outcome)
reference treatment, want to know risk of no treatment even with dx ;

data thesis_data6;
set thesis_data5;

if sum(medication, counseling)> 0
then outcome_flag=0;

else 
 outcome_flag =1;

run;

* 7) Format the variables;

proc format;
Value age_flag 0= 'age 22-44' 1= 'age >=45';
value gender_flag 0= 'Male' 1= 'Female';
Value QARR_flag 0= "Long Island" 1= "Central" 2= "Northeast" 3= "Hudson Valley" 4= "Western" 5= "New York City";
Value HI_flag 0= 'Lower Tier HI' 1= 'Higher Tier HI';
Value outcome_flag 0= 'Treatment' 1= 'No Treatment';
run;

*8. Two-way frequency for HI_flag* outcome_flag/ 
* want to know the risk of no treatment given, lower bracket insurance ;

proc freq data = thesis_data6;
tables HI_flag*outcome_flag / relrisk;
format outcome_flag outcome_flag. HI_flag HI_flag. ; 
run;

* The percentage of subjects who got no treatment (outcome_flag=1) 
given that they had the lower bracket insurance: 60.89%.

The percentage of subjects who got no treatment (outcome_flag=1) 
given that they had the higher bracket insurance: 57.06 %.

* 8) Unadjusted Model;

proc logistic data = thesis_data6;
	class HI_flag (ref='0')  / param=ref;
	model outcome_flag (event='1') = HI_flag ;
run;

* The OR: 0.854	and 95% CI: (0.759, 0.960)

This means that the risk of no treatment among those who are in the lower tier bracket insurance is
0.854 times the risk of no treatment among those who are in the higher tier bracket insurance. 
We are 95% confident that the true odds ratio is between 0.759, 0.960.;  

* 9) Evaluating the potential confounders of HI_flag-outcome_flag
		A) Variable associated with outcome (outcome_flag)?;


proc freq data = thesis_data6;
table  (age_flag gender_flag QARR_flag HI_flag)*outcome_flag/chisq;
format age_flag age_flag. gender_flag gender_flag. QARR_flag QARR_flag. 
		HI_flag HI_flag. outcome_flag outcome_flag.;
run;


proc logistic data = thesis_data6;
	class age_flag (ref='0')/ param=ref;
	model outcome_flag (event='1') = age_flag;
run;

* Age_flag p-value is significant;

proc logistic data = thesis_data6;
	class gender_flag (ref='0')/ param=ref;
	model outcome_flag (event='1') = gender_flag;
run;

* gender_flag p-value is NOT significant;

proc logistic data = thesis_data6;
	class QARR_flag (ref='0')/ param=ref;
	model outcome_flag (event='1') = QARR_flag;
run;

* QARR_flag p-value is significant;



*B) Variable associated with exposure (HI_Flag)?;

proc freq data = thesis_data6;
table  (age_flag gender_flag QARR_flag HI_flag)*dx_flag/chisq;
format age_flag age_flag. gender_flag gender_flag. QARR_flag QARR_flag. 
		HI_flag HI_flag. dx_flag dx_flag.;
run;

proc logistic data = thesis_data6;
	class age_flag (ref='0')/ param=ref;
	model HI_flag (event='1') = age_flag;
run;

* Age_flag p-value is significant;

proc logistic data = thesis_data6;
	class gender_flag (ref='0')/ param=ref;
	model HI_flag (event='1') = gender_flag;
run;

* gender_flag p-value is NOT significant;

proc logistic data = thesis_data6;
	class QARR_flag (ref='0')/ param=ref;
	model HI_flag (event='1') = QARR_flag;
run;

* QARR_flag p-value is significant;

*C) Is the variable on the pathway between exposure and outcome?
Age_flag, Gender_flag, and QARR_flag  are not based on subject matter knowledge ;

* 10) Run a binary logistic regression adjusting for confounders (drop gender_flag becuase it is not
a confounder and adjust for age_flag and QARR_flag becuase they were significant for both exposure
and outcome);

proc logistic data = thesis_data6;
	class HI_flag (ref='0') Age_flag (ref='0') QARR_flag (ref='0') / param=ref;
	model outcome_flag (event='1') = HI_flag Age_flag QARR_flag ;
run;

*OR (1.015) 95% CI	(0.892	1.155)
After adjusting for age_flag and QARR_flag, those with lower tier bracket insurance have 1.015 times the odd of
no treatment compared to those with higher tier bracket insurance. We are 95% confident that the true odds ratio
is between (0.892, 1.155).;



