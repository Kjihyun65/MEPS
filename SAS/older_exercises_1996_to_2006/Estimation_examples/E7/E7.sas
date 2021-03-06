/**********************************************************************\

PROGRAM:     C:\MEPS\PROG\E7.SAS

DESCRIPTION: THIS EXAMPLE SHOWS HOW TO COMPUTE SELECTED ESTIMATES
						 FROM MEPS STATISTICAL BRIEF #188, "SCREENING 
						 COLONOSCOPY AMONG U.S. NONINSTITUTIONALIZED ADULT
						 POPULATION AGE 50 AND OLDER, 2005".
						 
						 NOTE THAT THE STATISTICAL BRIEF (PUBLISHED NOVEMBER
						 2007) USED THE MEPS 2005 POPULATION CHARACTERISTICS
						 FILE (HC-90) SO THE ESTIMATES GENERATED IN THIS 
						 PROGRAM, USING THE 2005 CONSOLIDATED DATA FILE (HC-97)
						 DIFFER SLIGHTLY.

                     ALSO NOTE THAT WHILE THE SUBPOPULATION OF INTEREST IS
                     ADULTS AGE 50 AND OLDER, THE ENTIRE 2005 MEPS POPULATION
                     MUST BE USED IN ANALYSES IN ORDER TO GENERATE ACCURATE
                     STANDARD ERRORS.  AN AGE CATEGORY VARIABLE IS USED IN 
                     THE PROC SURVEYFREQ TABLE STATEMENT TO REQUEST ESTIMATES
                     AND STANDARD ERRORS FOR THE AGE GROUPS DESIRED.


INPUT FILES: C:\MEPS\DATA\H97.SAS7BDAT (2005 FULL-YEAR DATA FILE)                      

\**********************************************************************/

FOOTNOTE 'PROGRAM: C:\MEPS\PROG\E7.SAS';

LIBNAME CDATA 'C:\MEPS\DATA';

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- SEPTEMBER 2008';                                           
TITLE2 'COLONOSCOPY SCREENING AMONG ADULTS 50 AND OLDER, 2005';

PROC FORMAT  ;

  VALUE NUMFMT 0< - HIGH='POSITIVE WEIGHT';
    
  
  VALUE AGEF
     0-49='0-49'
     50-64='50-64'
     65-HIGH='65+'
   ;

  VALUE AGECAT
    1 = '1 AGE CATEGORY 0-49'
    2 = '2 AGE CATEGORY 50-64'
    3 = '3 AGE CATEGORY 65+'
   ;

  VALUE AGE50P
    1 = '1 AGE CATEGORY 0-49'
    2 = '2 AGE CATEGORY 50+'
   ;

   VALUE YESNO
         LOW-<0='<0'
         0='0'
         1='1, YES'
         2='2, NO'
    ;  
  
   VALUE EDUCF
   -7 = '-7 REFUSED'
   -8 = '-8 DK'
   -9 = '-9 NOT ASCERTAINED'
   -1 = '-1 INAPPLICABLE'
    1 = '1 LESS THAN HIGH SCHOOL'
    2 = '2 HIGH SCHOOL GRAD'
    3 = '3 AT LEAST SOME COLLEGE'
    4 = '4 UNKNOWN (-7/-8/-9)'
    5 = '5 YOUNGER THAN 16'
    ;

    VALUE RACEF
   -7 = '-7 REFUSED'
   -8 = '-8 DK'
   -9 = '-9 NOT ASCERTAINED'
   -1 = '-1 INAPPLICABLE'
    1 = '1 HISPANIC'
    2 = '2 WHITE NON-HISPANIC'
    3 = '3 BLACK NON-HISPANIC'
    4 = '4 ASIAN NON-HISPANIC'
    5 = '5 OTHER NON-HISPANIC'
   ;
    
RUN;

/* 2005 FY CONSOLIDATED DATA FILE */

DATA PUF97;
     SET CDATA.H97 (KEEP= DUPERSID VARSTR VARPSU AGE05X AGE53X AGE42X AGE31X
		                      RACEX HISPANX EDUCYR BOWEL53 WHNBWL53 PERWT05F);  
     IF BOWEL53=1 
   		THEN BOWELYES=1; ELSE BOWELYES=0;
   	
   ** AGE;
   IF AGE05X GE 0 THEN AGE=AGE05X;
   ELSE IF AGE53X GE 0 THEN AGE=AGE53X;
   ELSE IF AGE42X GE 0 THEN AGE=AGE42X;
   ELSE IF AGE31X GE 0 THEN AGE=AGE31X;
   ELSE AGE=-1; 

   ** AGE CATEGORY - 3 LEVELS;
        IF  0 LE AGE LE 49 THEN AGECAT=1;
   ELSE IF 50 LE AGE LE 64 THEN AGECAT=2;
   ELSE IF AGE GE 65       THEN AGECAT=3; 
   ELSE AGECAT = -1;
   
   ** AGE CATEGORY - 2 LEVELS;
        IF  0 LE AGE LE 49 THEN AGE50PLUS=1;
   ELSE IF AGE GE 50 THEN AGE50PLUS=2;
   ELSE AGE50PLUS = -1;

   ** RACETH;
   IF HISPANX=1 THEN RACETH=1;                  /* HISPANIC */
   ELSE IF HISPANX=2 THEN DO;
      IF RACEX=1 THEN RACETH=2;                 /* WHITE, NON-HISPANIC */
      ELSE IF RACEX=2 THEN RACETH=3;            /* BLACK, NON-HISPANIC */
      ELSE IF RACEX=3 THEN RACETH=4;            /* AMER. IND/AK. NATIVE, NON-HISPANIC */
      ELSE IF RACEX=4 THEN RACETH=5;            /* ASIAN, NON-HISPANIC */
      ELSE IF RACEX=5 THEN RACETH=6;            /* HAWAIIAN/PACIFIC ISL., NON-HISPANIC */
      ELSE IF RACEX=6 THEN RACETH=7;            /* MULTIPLE RACES, NON-HISPANIC */
   END;  
    
   ** NEWRACE ;
   IF RACETH=1 THEN NEWRACE=1;                 /* HISPANIC */
   ELSE IF RACETH=2 THEN NEWRACE=2;            /* WHITE, NON-HISPANIC */
   ELSE IF RACETH=3 THEN NEWRACE=3;            /* BLACK, NON-HISPANIC */
   ELSE IF RACETH=5 THEN NEWRACE=4;            /* ASIAN, NON-HISPANIC */
   ELSE IF RACETH IN (4,6,7) THEN NEWRACE=5;   /* AMER IND/ AK NATIVE / HAWAIIAN / PAC. ISL./ MULT RACES: NON-HISPANIC */
   
   ** EDUCATION;

   ** HIGHEDUC;
   IF AGE LT 16 THEN HIGHEDUC=5;           /* YOUNGER THAN 16 */
   ELSE IF EDUCYR LT 0 THEN HIGHEDUC=4;    /* UNKNOWN OR REFUSED */
   ELSE IF EDUCYR LT 12 THEN HIGHEDUC=1;   /* LESS THAN 12 YEARS */
   ELSE IF EDUCYR = 12 THEN HIGHEDUC=2;    /* HIGH SCHOOL GRAD */
   ELSE IF EDUCYR GT 12 THEN HIGHEDUC=3;   /* AT LEAST SOME COLLEGE */
   ELSE HIGHEDUC=-1;
  RUN;



TITLE3 'MEPS STAT BRIEF #188, FIGURE 1 (TOTAL)';

PROC SURVEYFREQ DATA= PUF97;
 WEIGHT PERWT05F;
 CLUSTER VARPSU;
 STRATA VARSTR;
 TABLE AGECAT*BOWEL53 / ROW;
 TABLE AGE50PLUS*BOWEL53 / ROW;
 FORMAT BOWEL53 YESNO. AGECAT AGECAT. AGE50PLUS AGE50P.; 
RUN;

TITLE3 'MEPS STAT BRIEF #188, FIGURE 2 (RACE/ETHNICITY)';

PROC SURVEYFREQ DATA=PUF97;
 WEIGHT PERWT05F;
 CLUSTER VARPSU;
 STRATA VARSTR;
 TABLE AGE50PLUS*NEWRACE*BOWEL53 / ROW;
 FORMAT AGE50PLUS AGE50P. BOWEL53 YESNO. NEWRACE RACEF. ;
RUN;

TITLE3 'MEPS STAT BRIEF #188, FIGURE 3 (EDUCATION)';

PROC SURVEYFREQ DATA=PUF97;
 WEIGHT PERWT05F;
 CLUSTER VARPSU;
 STRATA VARSTR;
 TABLE AGE50PLUS*HIGHEDUC*BOWEL53 / ROW;
 FORMAT AGE50PLUS AGE50P. BOWEL53 YESNO. HIGHEDUC EDUCF. ;
RUN;
