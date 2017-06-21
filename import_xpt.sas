libname xptfile xport '~/rawork/jarrad/merger1/forsas.xpt' access=readonly;
libname sasfile '~/rawork/jarrad/merger1';

*proc copy inlib = xptfile outlib = sasfile;
*run;

*proc print data = this.forsas (obs = 100);
*run;
