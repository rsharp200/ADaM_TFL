/******************************************************************************
*  ____                  _
* |  _ \  ___  _ __ ___ (_)_ __   ___
* | | | |/ _ \| '_ ` _ \| | '_ \ / _ \
* | |_| | (_) | | | | | | | | | | (_) |
* |____/ \___/|_| |_| |_|_|_| |_|\___/
* ____________________________________________________________________________
* Sponsor              : Domino
* Compund              : -
* Study                : -
* Analysis             : -
* Program              : domino.sas
* ____________________________________________________________________________
* DESCRIPTION 
*
* This is the standard Domino SAS setup file and contains definitions that
* are used across the reporting effort. 
*
* DO NOT EDIT THIS FILE WITHOUT PRIOR APPROVAL 
*
* Program description:
* 0. Read environment variables
* 1. Set global pathname macro variables
* 2. Define standard libraries
*                                                                   
* Input files:
* - none
* 
* Input Environment Variables:
* - DOMINO_PROJECT_NAME
* - DOMINO_WORKING_DIR
* - DCUTDTC
*
* Outputs:                                                   
* - global variables defined
* - SAS Libnames defined
* - sasautos path set for shared macros
*
* Macros: 
* - none
*
* Assumptions: 
* - Must be run on the Domino platform (assumes Domino environment vars)
* ____________________________________________________________________________
* PROGRAM HISTORY                                                         
*  2022-06-06  |   Stuart.Malcolm  | Program created
* ----------------------------------------------------------------------------
*  YYYYMMDD  |  username        | ..description of change..         
*****************************************************************************/

%macro __setup();

* globals read in from env vars; 
%global __WORKING_DIR  ; * path to root of working directory ;
%global __PROJECT_NAME ; * project name <PROTOCOL>_<TYPE> ;
%global __DCUTDTC      ; * cutoff date in ISO8901 format ;

* globals derived from env vars;
%global __PROTOCOL;      * Protocol identifier e.g H2QMCLZZT; 
%global __PROJECT_TYPE ; * project type: SDTM | ADAM | TFL ;

* grab the environment varaibles that we need to create pathnames;
%let __WORKING_DIR  = %sysget(DOMINO_WORKING_DIR);
%let __PROJECT_NAME = %sysget(DOMINO_PROJECT_NAME);
%let __DCUTDTC      = %sysget(DCUTDTC);

* runtime check that e.g. DCUTDTC is not missing;
%if &__DCUTDTC. eq %str() %then %put %str(ER)ROR: Envoronment Variable DCUTDTC not set;

* extract the protocol and project type from the project name;
%if %sysfunc(find(&__PROJECT_NAME.,_)) ge 1 %then %do;
  %let __PROTOCOL     = %scan(&__PROJECT_NAME.,1,'_');
  %let __PROJECT_TYPE = %scan(&__PROJECT_NAME.,2,'_');
  %end;
%else %do;
  %put %str(ER)ROR: Project Name (DOMINO_PROJECT_NAME) ill-formed. Expecting <PROTOCOL>_<TYPE> ;
%end;

* define library locations - these are dependent on the project type;
* ------------------------------------------------------------------;

* SDTM ;
* ------------------------------------------------------------------;
%if %upcase(&__PROJECT_TYPE.) eq SDTM %then %do;
  * Local read/write access to SDTM and QC folders ;
  libname SDTM   "/mnt/data/SDTM";
  libname SDTMQC "/mnt/data/SDTMQC";
%end;

* ADAM ;
* ------------------------------------------------------------------;
%if %upcase(&__PROJECT_TYPE.) eq ADAM %then %do;
  * imported read-only SDTM data, using the data cutoff date.. ;
  * ..to identify the correct snapshot to use ;
  libname SDTM "/mnt/imported/data/snapshots/SDTM/SDTM_&__DCUTDTC." access=readonly;
  * local read/write acces to ADaM and QC folders;
  libname ADAM   "/mnt/data/ADAM";
  libname ADAMQC "/mnt/data/ADAMQC";
%end;

* TFL ;
* ------------------------------------------------------------------;
%if %upcase(&__PROJECT_TYPE.) eq TFL %then %do;
  * imported read-only access to ADaM folder;
  libname ADAM "/mnt/imported/data/ADAM" access=readonly;
  * local read/write for TFL datasets ;
  libname TFL   "/mnt/data/TFL";
  libname TFLQC "/mnt/data/TFLQC";
%end;

* ------------------------------------------------------------------;
* Set SASAUTOS to search for shared macros ;
* ------------------------------------------------------------------;
FileName SASmacro "/mnt/code/share/macros" ;
options append=(sasautos=(SASmacro) ) ;

%mend __setup;
* invoke the setup macro - so user program only needs to include this file;
%__setup;

* write to log for traceability ;
* this is done outside the setup macro to ensure global vars are defined;
%put TRACE: (domino.sas) [__WORKING_DIR = &__WORKING_DIR.] ;
%put TRACE: (domino.sas) [__PROJECT_NAME = &__PROJECT_NAME.];
%put TRACE: (domino.sas) [__DCUTDTC = &__DCUTDTC.];
%put TRACE: (domino.sas) [__PROTOCOL = &__PROTOCOL.];
%put TRACE: (domino.sas) [__PROJECT_TYPE = &__PROJECT_TYPE.];

* List all the libraries that are currently defined;
libname _all_ list;

*EOF;