/* 	Compile with:
 *      bfin-linux-uclibc-gcc -Wall -o get_status -mfdpic get_status.c
 *
 *	Forces the FPGA to read the parameters stored in the BRAM. 
 *	Does not store the parameters in the BRAM.
 */

#include <unistd.h>     /*sleep and usleep*/
#include <sys/time.h>   /*gettimeofday*/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "../bitmasks.h"        /*useful bitmasks*/
#include "../fpga_4futils.h"    /*FPGA addresses*/
#include "../fcommon.c"         /*FPGA utility functions*/


int main() {

        short *virt_addr;       /* CTRL reg is 16 bits */
        short value;

        virt_addr = (short *) FPGA_CTRL_REG;    /*typecast*/
        value = * virt_addr;                    /*fetch register*/

        /* SNGL, AUTO, TRIGGER bits off to be able to toggle */
        value &= ~FPGA_INI_BIT;                 /*clear "ini" bit*/
        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/

        /*SNGL bit ON to make 0-->1 transition*/
        value |= FPGA_INI_BIT;                 /*set "single" bit*/
        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/

        /*SNGL bit OFF to leave it in the OFF state*/
        value &= ~FPGA_INI_BIT;                /*clear "single" bit*/
        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/

	sleep(1); /*wait for FPGA*/
	
        int  nsmpls, i;
        unsigned long  wave_start;
        unsigned long  *base_ptr, *lptr; /* +4 pointer math*/
        unsigned long  lword;   	 /* long  for 32-bit  */
	signed short par[32];

	int ADCc_at_threshold, baseline;
	int sign;
	int int_window, veto_delay;
	int sig_threshold, int_threshold, width_cut, risetime_cut;
	int int_status, width_status, risetime_status;
	int us_conversion, std_hev_on, wide_hev_on;
        double param1, param2, param3, param4;
	int StaticVetoDuration, DynamicVetoLimit;
	int Prescaling;


        wave_start = 0x20000000;
        base_ptr   = (unsigned long *) wave_start; /* ptr to 32-bit words*/

	/*kept the number of nsmpls as it was*/ 
        nsmpls=32;

            /* inner loop acquires ADC samples; 2 samples per mem access*/
            for (i = 0; i < nsmpls/2; i++) {
                /* every 32-bit read returns two 16-bit samples*/
                /* i is indexing two-sample words, 32-bits each */
                /* 32 bit needs unpacking into two 16-bit shorts */
                lptr = (unsigned long *) (base_ptr + i);
                lword = *( lptr);
                par[i*2] = (short) (lword & 0x0000FFFF);
                lword =      (lword & 0xFFFF0000);
                par[i*2+1] = (short) (lword >> 16);
            } /* for i  end of inner loop */
 
	sign = par[0];
	int_window = par[1];
	veto_delay = par[2];
	sig_threshold = par[3];

	int_threshold = (par[4] << 16);
	int_threshold = int_threshold | (par[5] & 0x0000FFFF);

	width_cut = par [6];
	risetime_cut = par[7];
	
	/*Control Parameters */
	wide_hev_on = par[8] & 0x00000020;
        wide_hev_on = wide_hev_on >> 5;
        std_hev_on = par[8] & 0x00000010;
        std_hev_on = std_hev_on >> 4;
        us_conversion = par[8] & 0x00000008;
	us_conversion = us_conversion >> 3;

	int_status = par[8] & 0x00000004;
	int_status = int_status >> 2;
	width_status = par[8] & 0x00000002;
	width_status = width_status >> 1;
	risetime_status = par[8] & 0x00000001;
	
	/*Polynomial rho coefficients*/
	param1 = par[9];
	param1 = param1 + par[10]/(double)pow(2,16);
	param1 = param1 + par[11]/(double)pow(2,32);
	param1 = param1 + par[12]/(double)pow(2,48);

        param2 = par[13];
        param2 = param2 + par[14]/(double)pow(2,16);
        param2 = param2 + par[15]/(double)pow(2,32);
        param2 = param2 + par[16]/(double)pow(2,48);

        param3 = par[17];
        param3 = param3 + par[18]/(double)pow(2,16);
        param3 = param3 + par[19]/(double)pow(2,32);
        param3 = param3 + par[20]/(double)pow(2,48);

        param4 = par[21];
        param4 = param4 + par[22]/(double)pow(2,16);
        param4 = param4 + par[23]/(double)pow(2,32);
        param4 = param4 + par[24]/(double)pow(2,48);
	
	/* Set Veto Lengths*/
	StaticVetoDuration = par[25];
	DynamicVetoLimit = par[26];
	/*Other useful params*/
	Prescaling = par[27];
	baseline = par[28];
	/*ADCc_at_threshold = par[29];*/
	

	printf("\n=================HEV STATUS==================\n");
    printf("=============================================\n");
    printf("Signal Sign: \t\t%d\t  (0=negative, 1=positive)\n",sign);
    printf("Integration Window: \t%d\t  [10 ns]\n",int_window);
    printf("Veto Delay: \t\t%d\t  [10 ns]\n",veto_delay);
    printf("Signal Threshold: \t%d\t  [ADCc]\n",sig_threshold);
	printf("Integral Threshold: \t%d\t  [ADCc]\n",int_threshold);
    printf("Width Cut: \t\t%d\t  [10 ns]\n",width_cut);
	printf("Rise Time Cut : \t%d\t  [10 ns]\n",risetime_cut);
    printf("Integral Component: \t%d\t  (1=on, 0=off)\n",int_status);
    printf("Width Component: \t%d\t  (1=on, 0=off)\n", width_status);
    printf("Rise Time Component: \t%d\t  (1=on, 0=off)\n", risetime_status);
	printf("ns to us conversion: \t%d\t  (1=on, 0=off)\n",us_conversion);
    printf("Standard HEVeto: \t%d\t  (1=on, 0=off)\n", std_hev_on);
    printf("Wide S2 HEVeto: \t%d\t  (1=on, 0=off)\n", wide_hev_on);
	printf("polyn. par1: \t\t%.15lf\t\t \n", param1);
    printf("polyn. par2: \t\t%.15lf\t\t \n", param2);
    printf("polyn. par3: \t\t%.15lf\t\t \n", param3);
    printf("polyn. par4: \t\t%.15lf\t\t \n", param4);
    printf("Static Veto Duration: \t%d\t  [10 ns]\n",StaticVetoDuration);
    printf("Dynamic Veto Duration: \t%d\t  [10 ns]\n",DynamicVetoLimit);
    printf("prescaling: \t\t%d\t  (every Nth event passes the veto)\n",Prescaling);
	printf("baseline: \t\t%d\t  [ADCc]\n", baseline);
	/*printf("ADC at threshold: \t%d\t  [ADCc]\n", ADCc_at_threshold);*/
	printf("==============================================\n\n");

	return 0;
};

