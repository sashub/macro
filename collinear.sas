/*
PROGRAMMER: Paul von Hippel
DATE: June 14, 2004
PURPOSE: Analysts may inadvertently include collinear variables in a regression.
 Collinearity means that one variable is a constant plus a weighted sum of other variables.
 To help researchers figure out which variables are collinear, the %collinear macro reports
 how much of the variance in each variable can be explained by the others (R2). If R2=1,
 then the variable in question is collinear with other variables.

 The macro is invoked as follows:

 %collinear (dataset=mydataset, vars=x1 x2 etc);

 where mydataset is the dataset you are working with
 and x1 x2 etc is a list of variables including some that may be collinear.
TIP: To get a list of the variables in your data set, type PROC CONTENTS SHORT;
KNOWN PROBLEM: %collinear uses listwise deletion -- that is, it only uses cases where
 _all_ this listed variables are observed. The macro will not work if R2 cannot
 be estimated using listwise deletion. One such situation occurs when a variable
 has no variation in the listwise-deleted data set. When a correlation cannot be
 estimated using listwise deletion, the macro will complain of missing values in
 the correlation matrix R.
*/

%macro collinear (dataset=, vars=);
proc corr data=&dataset noprob nomiss;
 var &vars;
 ods output PearsonCorr=R;
run;
proc iml;
 use R;
 read all into R;
 R = R[, 1:nrow(R)];
 read all var {Variable} into Variable;
 J = J(nrow(R),1);
 R2 = J - J / vecdiag(ginv(R));
 title "Collinearity check";
 print Variable R2;
 print "Note. R2 is the proportion of variance explained";
 print "when each variable is regressed on all the others";
quit;
%mend collinear (dataset=, vars=);
