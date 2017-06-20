
%include "setUp.sas";
%include "&_macros/utility.sas";
%include "&_macros/compustat_macros.sas";
%include "&_macros/compustat_crsp_utility_macros.sas";

%let dir = .;

*Imports the excel file data into SAS format;
*%_setUp(acq_master,"arb_data_acq.xlsx");
*%_setUp(targ_master,"arb_data_target.xlsx");

*Imports the Ken French daily risk free rate return data;
%_importrf(rf, "rf_daily.CSV");

*Merges the deal data info with the daily return data for both the target and the acquirors;
%_addRets(acq_rets,this.acq_master, acq_permno, acq_prc, acq_ret, acq_gv, acq_cusip, acq_sic, acq_shr);
%_addRets(targ_rets,this.targ_master, tgt_permno, tgt_prc, tgt_ret, tgt_gv, tgt_cusip, tgt_sic, tgt_shr);

*Combines the target and the acquiror data with the general deal characteristics;
%_mergeData(all_data, acq_rets, targ_rets);

%_calcDealSpreads(deal_spreads, all_data);

*proc print data = deal_spreads(obs = 100);
*run;

data deal_print(keep = acq_permno date acq_shr tgt_permno tgt_shr deal_num);
	set deal_spreads;
run;

proc export data = deal_print outfile = "deal_shares.csv" dbms = csv replace;
run;
