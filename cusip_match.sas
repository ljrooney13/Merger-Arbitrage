/******************************************************************************
 Cusip match brings in an excel file of SDC merger data and uses the 6 digit SIC
 codes to match to permnos and gvkeys. The output is a file containing permnos 
 and gvkeys for both the acquiror and target companies.
 ******************************************************************************/

%include "&_macros/utility.sas";
%include "&_macros/compustat_macros.sas";
%include "&_macros/compustat_crsp_utility_macros.sas";

%let dir = .;

/******************************************************************************
 Sets the necessary variables and extracts the compustat and crsp merged data
 ******************************************************************************/

%let startdt = '1Jan1950'd;
%let stopdt = '31Dec2016'd;
%let ccmlink = liid linktype lpermco;
%let compdata = fyear fyr;

%ccm_link(crsp_comp_link, start_date = &startdt, stop_date = &stopdt);
%read_comp(compdata, &compdata, startdt = &startdt, stopdt = &stopdt);

data linked (keep = gvkey permno);
	merge compdata crsp_comp_link(drop = &ccmlink rename = (lpermno = permno));
	retain permno gvkey;
	if (permno ne .) then output;
run;

proc sort data = linked out = permsorted;
	by permno;
run;

/******************************************************************************
 Imports the excel file containing the cusips that we are looking to match with
 permnos and gvkeys.
 ******************************************************************************/

proc import out = temp datafile = "rooney_v1.xlsx" dbms = xlsx;
run;

proc sort data = temp out = raw_data;
	by cusip;
run;

/******************************************************************************
 Reads in and manipulates the permnos associated with the cusips. Trims the
 cusips to 6 digits to match with the data in the file.
 ******************************************************************************/

proc sort data = crsp.dsenames out = dse;
	by ncusip;
run;

data sorted1(keep = permno cusip6);

	set dse;
		by ncusip;

	cusip6 = substr(ncusip,1,6);

	if (first.ncusip) then output;
run;

proc sort data = sorted1 out = sorted2;
	by permno;
run;

data sorted3(keep = permno cusip6 gvkey);

	merge sorted2 permsorted;
		by permno;

run;

proc sort data = sorted3 out = sorted;
	by cusip6;
run;

*proc print data = sorted;
*run;

data match;

	merge sorted(rename = (cusip6 = cusip)) raw_data;
		by cusip;

	if (deal_num ne .) then output;
*	if (permno = . ) then output;

run;

proc print data = match;
run;

proc export data = match outfile = "&dir/matched.csv" dbms = csv replace;
run;

