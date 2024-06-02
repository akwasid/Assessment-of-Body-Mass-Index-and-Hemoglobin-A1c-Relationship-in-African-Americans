libname proj "C:\Users\Bobie\Desktop\SPH Fall 2023\BS 805\BS805 Project";


/*Question 1 */
* Merge baseline data for both cohorts;
data baseline_combined;
merge proj.BASELINE_COHORT1 (in=a) proj.BASELINE_COHORT2 (in=b);
by ID;
if a or b;
run;

* Merge clinical data for both cohorts;
data clinical_combined;
merge proj.CLINICAL_COHORT1 (in=a) proj.CLINICAL_COHORT2 (in=b);
by ID;
if a or b;
run;


* Merge the combined clinical data with baseline data ;
data final_dataset;
merge baseline_combined clinical_combined;
by ID;
run;

proc print data=final_dataset;
run;



/*Question 2 */
data finalbmi;
set final_dataset;
length BMI_cat $20;
*Convert height from inches to meters and weight from pounds to kilograms;
height_m = height * 0.0254;
weight_kg = weight * 0.453592;
*a. Calculate BMI ;
BMI = weight_kg/(height_m**2);
*Exclude subjects with BMI < 19 ;
if BMI < 19 then delete;
* b. Categorical BMI variable ;
if BMI =. then BMI_cat=" ";
else if BMI < 25 then BMI_cat="Normal"; 
else if 25 <= BMI < 30 then BMI_cat="Overweight"; 
else if BMI >= 30 then BMI_cat="Obese"; 
* c. Piecewise variables for each BMI interval ;
if BMI < 25 then BMI1= BMI;
else if BMI >=25 then BMI1=25;
if BMI < 25 then BMI2=25;
else if 25<=BMI< 30 then BMI2=BMI;
else if BMI>=30 then BMI2=30;
if BMI <30 then BMI3=30;
else if BMI >= 30 then BMI3=BMI;
*d. Waist-to-hip ratio;
WHR = waist / hip;
*e. Mean systolic blood pressure ;
mean_SBP = (bp_1s + bp_2s) / 2;
*f. Natural logarithm of HbA1c;
ln_glyhb = log(glyhb);
*g. Dummy variable for gender;
MALE = (gender = "male");
* Assigning labels;
label height_m = "Height in meters"
      weight_kg = "Weight in kilograms"
      BMI = "Body Mass Index"
      BMI_cat = "Categorical BMI"
      BMI1 = "BMI Normal"
      BMI2 = "BMI Overweight"
      BMI3 = "BMI Obese"
      WHR = "Waist-to-Hip Ratio"
      mean_SBP = "Mean Systolic Blood Pressure"
      ln_glyhb = "Natural Log of HbA1c"
      MALE = "Male Dummy Variable";
run;

proc print data=finalbmi;
run;


/*Question 3 */
*Descriptive Statistics for Continuous Variables ;
proc means data=finalbmi n mean std min max;
var age height_m weight_kg BMI WHR bp_1s bp_1d mean_SBP glyhb ln_glyhb;
title'Descriptive Statistics for Continuous Variables ';
run;
title;


proc means data=finalbmi n mean std min max;
var age height_m weight_kg BMI WHR bp_1s bp_1d mean_SBP glyhb ln_glyhb;
class BMI_cat;
title'Descriptive Statistics for Continuous Variables by BMI Catergory';
run;
title;


*Frequency Tables for Categorical Variables;
proc freq data=finalbmi;
tables  BMI_cat*gender;
title'Frequency Tables for Categorical Variables';
run;
title;



/*Question 4 */
* Linear Regression for Non-Log Version of HbA1c ;
proc glm data=finalbmi;
class BMI_cat (ref="Normal");
model glyhb = BMI_cat/solution;
title' Linear Regression for Non-Log Version of HbA1c';
run;
title;

* Linear Regression for Log Version of HbA1c ;
proc glm data=finalbmi;
class BMI_cat (ref="Normal");
model ln_glyhb = BMI_cat/solution;
title'Linear Regression for Log Version of HbA1c';
run;
title;



/*Question 5 */
*Dummy and ordinal varriables creation;
data finalset;
set finalbmi;
if BMI_cat="Normal" then do;
*Normal is reference;
Class1=0;
Class2=0;
end;
else if BMI_cat="Overweight" then do;
Class1=1;
Class2=0;
end;
else if BMI_cat="Obese" then do;
Class1=0;
Class2=1;
end;
if BMI_cat="" then BMI_ord= .;
else if BMI_cat="Normal" then BMI_ord=1;
else if BMI_cat="Overweight" then BMI_ord=2;
else if BMI-cat="Obese" then BMI_ord=3;
run;


proc print data=finalset;
run;

proc contents data=finalset;
run;

*Linear regression model with dummy variable;
proc glm data=finalset;
model ln_glyhb=Class1 Class2/solution;
title'Linear regression model with dummy variable';
run;
title;

*Linear regression model with ordinal variable;
proc glm data=finalset;
class BMI_ord (ref="1");
model ln_glyhb=BMI_ord/solution;
title'Linear regression model with ordinal variable';
run;
title;

*Linear regression model with continuous BMI using a single linear term;
proc glm data=finalset;
model ln_glyhb=BMI;
title'Linear regression model with continuous BMI using a single linear term';
run;
title;


*Linear regression model with a piecewise linear model;
proc glm data=finalset;
model ln_glyhb=BMI1 BMI2 BMI3/solution;
title'Linear regression model with a piecewise linear model';
run;
title;


/*Question 6*/
*Age as an effect modifier;
proc glm data=finalset;
class BMI_cat (ref="Normal");
model ln_glyhb = BMI_cat age BMI_cat*age/solution;
title'Age as an effect modifier';
run;
title;

*Sex as an effect modifier;
proc glm data=finalset;
class BMI_cat (ref="Normal");
model ln_glyhb = BMI_cat Male BMI_cat*Male/solution;
title'Sex as an effect modifier';
run;
title;


/*Question 7*/
*A. Best predictor of waist, hip, waist to hip ratio;

*waist;
proc reg data=finalset;
model ln_glyhb= waist;
title'Linear regression of log-transformed HbA1C and waist';
run;
title;

*waist to hip ratio;
proc reg data=finalset;
model ln_glyhb = WHR;
title'Lineaer regression of log-transformed HbA1c and waist to hip ratio';	
run;
title;

*hip;
proc reg data=finalset;
model ln_glyhb=hip;
title'Linear regression of log-transformed HbA1C and hip';
run;
title;


*multi-collinearity analysis & outliers and influence points;
proc reg data=finalset;
model ln_glyhb=waist WHR hip/ tol vif collinoint r;
id;
title'Multicollinearity analysis of waist, hip, and waist to hip ratio';
output out=two pred=p_ln_glyhb student=str_ln_glyhb residual=resid_ln_glyhb cookd=cooksd;
run;
title;

*7b Fit linear regression model for HbA1c that includes independent variables;

proc glm data=finalset;
class BMI_cat(ref='Normal');
model ln_glyhb = BMI_cat/solution;
title'Crude model of log transformed HbA1C and BMI categories';
run;
title;

*Adjusted model;
proc glmselect data=finalset;
class BMI_cat(ref='Normal') MALE(ref='0');
model ln_glyhb = BMI_cat age chol waist MALE mean_SBP/ selection = none stb;
title'Adjusted model of log transformed HbA1C and BMI categories with other predictors';
run;
title;


/*Question8*/
proc glmselect data=finalset;
class BMI_cat(ref='Normal') MALE(ref='0');
model ln_glyhb=BMI_cat age chol waist MALE mean_SBP / selection=lasso (stop=none choose=aic);
title'Lasso based linear regression for the multivariate linear regression model';
run;
title;

proc glmselect data=finalset;
class BMI_cat(ref='Normal') MALE(ref='0');
model ln_glyhb=BMI_cat age chol waist MALE mean_SBP / selection=backward (choose=aic stop=sl) sle=0.05 sls=0.05 select=aic;
title'Backward selection linear regression for the multivariate linear regression model';
run;
title;
