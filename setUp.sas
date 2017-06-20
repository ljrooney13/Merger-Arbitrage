
%macro _setUp(_outfile, xl_name);

	proc import out = temp&_outfile datafile = &xl_name dbms = xlsx;
	run;

	proc sort data = temp&_outfile out = raw_file_&_outfile;
		by permno;
	run;

	data cleaned_master_&_outfile(keep = deal_num date permno gvkey cusip sic announce end);
		
		retain deal_num date permno gvkey cusip sic;
	
		set raw_file_&_outfile;
			by permno;
	
		retain date t_date_10;
		date = intnx("DAY", date_251,-1);
		
		t_date_10 = date_10;
		format t_date_10 date9.;
		
		do until (date = t_date_10);

			date = intnx("DAY",date,1);
			format date date9.;
			if (permno ne .) then output;
		end;

	run;
	
	proc sort data = cleaned_master_&_outfile out = this.&_outfile;
		by permno date;
	run;

%mend _setUp;

%macro _importrf(_outfile, rf_data);

	proc import out = rf_temp datafile = &rf_data dbms = csv;
	run;

	data rf_unsorted(keep = date rf);
		retain date rf;
		
		set rf_temp;
		
		rf = rf / 100;
	
		date = mdy(month, day, year);
		format date date9.;
	run;

	proc sort data = rf_unsorted out = &_outfile;
		by date;
	run;

%mend _importrf;

%macro _addRets(_outfile, _infile, _permno, _prc, _ret, _gv, _cusip, _sic, _shrout);

	data ret_temp_&_outfile;

		merge crsp.dsf(keep = permno date ret prc shrout) &_infile;
			by permno date;

		prc = abs(prc);

		if (deal_num ne .) then do;
			if (ret ne .) then output;
		end;
	run;

	proc sort data = ret_temp_&_outfile out = ret_sorted_&_outfile;
		by date;
	run;

	data full_rets_&_outfile;

		merge ret_sorted_&_outfile(rename = (permno = &_permno prc = &_prc ret = &_ret gvkey = &_gv cusip = &_cusip sic = &_sic shrout = &_shrout)) rf;
			by date;

		if (&_permno ne .) then output;
	run;	

	proc sort data = full_rets_&_outfile out = &_outfile;
		by deal_num date;
	run;

%mend _addRets;

%macro _mergeData(_outfile, _infile1, _infile2);

	data combined;
		merge &_infile1 &_infile2;
			by deal_num date;
	run;

	proc import out = temp2 datafile = "deal_data.xlsx" dbms = xlsx;
	run;

	proc sort data = temp2 out = deal_data;
		by deal_num;
	run;

	data this.&_outfile;
		merge combined deal_data;
			by deal_num;
	run;

%mend _mergeData;

%macro _calcDealSpreads(_outfile ,_infile); 

	data deal_spreads_filtered;
		set this.&_infile;
			by deal_num;

		if (perc_cash ^= . or perc_stock ^= .) then output;

	run;

	data deal_spreads;

		set deal_spreads_filtered;
			by deal_num;

		if perc_stock = 100 then do;
			stock_deal = 1;
			cash_deal = 0;
		end;
		if perc_cash = 100 then do;
			cash_deal = 1;
			stock_deal = 0;
		end;

		if cash_deal = 1 then deal_spread = tgt_ret - rf;
		if stock_deal = 1 then deal_spread = tgt_ret - acq_ret * exch_ratio;
	run;

%mend _calcDealSpreads;









