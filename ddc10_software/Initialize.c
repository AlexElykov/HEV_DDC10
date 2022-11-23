 /* *  bfin-linux-uclibc-gcc -Wall -o Initialize -mfdpic Initialize.c
   *   Reads the file 'parameter.txt' and saves the parameter to BRAM.
   *   After the storage the FPGA is automatically forced to read the BRAM.
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>

#include "../bitmasks.h"        /*useful bitmasks*/
#include "../fpga_4futils.h"    /*FPGA addresses*/
#include "../fcommon.c"         /*FPGA utility functions*/

int main(int argc, char **argv) {


	if(argc != 20){
		printf("wrong usage\n");
		exit(1);
	}
	int success=0;
        int  i;
	int  nsmpls;
        unsigned long  wave_start;
        unsigned long  *base_ptr, *lptr; /* +4 pointer math*/
        unsigned long  lword;   	/* long  for 32-bit  */
	signed int word32;

        /* wave_start address and pointer to FPGA waveforms */
        wave_start = 0x20000000;
        base_ptr   = (unsigned long *) wave_start; /* ptr to 32-bit words*/

        short int par_16[30];
	int par_32[20];

	for(i=1;i<20;i++){
		par_32[i-1]=atof(argv[i]);
	}



        par_16[0]= (short) (par_32[0] & 0x0000FFFF); /* signal sign */
        par_16[1]= (short) (par_32[1] & 0x0000FFFF); /* int_window */
        par_16[2]= (short) (par_32[2] & 0x0000FFFF); /* veto_delay */
        par_16[3]= (short) (par_32[3] & 0x0000FFFF); /* signal threshold */

	/* int_threshold */
        par_16[5]= (short) (par_32[4] & 0x0000FFFF);
        par_32[4]= (par_32[4] & 0xFFFF0000);
	par_16[4]= (short) (par_32[4] >> 16);

        par_16[6]= (short) (par_32[5] & 0x0000FFFF); /* width cut */
	par_16[7]= (short) (par_32[6] & 0x0000FFFF); /* rise time cut */

        par_16[8]= (short) (par_32[7] & 0x0000FFFF); /* Component Status */

	/* polynom parameter 1 */
        par_16[10]= (short) (par_32[8] & 0x0000FFFF);
        par_16[9]= (short) ((par_32[8]>>16) & 0x0000FFFF);
        par_16[12]= (short) (par_32[9] & 0x0000FFFF);
        par_16[11]= (short) ((par_32[9]>>16) & 0x0000FFFF);
	/* polynom parameter 2 */
        par_16[14]= (short) (par_32[10] & 0x0000FFFF);
        par_16[13]= (short) ((par_32[10]>>16) & 0x0000FFFF);
        par_16[16]= (short) (par_32[11] & 0x0000FFFF);
        par_16[15]= (short) ((par_32[11]>>16) & 0x0000FFFF);
        /* polynom parameter 3 */
        par_16[18]= (short) (par_32[12] & 0x0000FFFF);
        par_16[17]= (short) ((par_32[12]>>16) & 0x0000FFFF);
        par_16[20]= (short) (par_32[13] & 0x0000FFFF);
        par_16[19]= (short) ((par_32[13]>>16) & 0x0000FFFF);
        /* polynom parameter 4 */
        par_16[22]= (short) (par_32[14] & 0x0000FFFF);
        par_16[21]= (short) ((par_32[14]>>16) & 0x0000FFFF);
        par_16[24]= (short) (par_32[15] & 0x0000FFFF);
        par_16[23]= (short) ((par_32[15]>>16) & 0x0000FFFF);

	par_16[25]= (short) (par_32[16] & 0x0000FFFF); /* Static veto duration */
        par_16[26]= (short) (par_32[17] & 0x0000FFFF); /* Dynamic veto limit */
        par_16[27]= (short) (par_32[18] & 0x0000FFFF); /* PreScaling */
        par_16[28]= 0;


	while(success == 0){
        	nsmpls=28;

		/* loop send parameter to BRAM; 2 samples per mem access*/
		for (i = 0; i < nsmpls/2; i++) {
       			lptr = (unsigned long *) (base_ptr + i);
			word32 = 0;	     
			word32 = (par_16[i*2+1] << 16);
			word32 = word32 | (par_16[i*2] & 0x0000FFFF);
			Slong_to_FPGA (lptr,word32);
			//printf("word32=%08x\n",word32);

        	} /* for i  end of inner loop */


		usleep(1000);

	/*====== force FPGA to initialize =====*/
	        short *virt_addr;       /* CTRL reg is 16 bits */
	        short value;
	
	        virt_addr = (short *) FPGA_CTRL_REG;    /*typecast*/
	        value = * virt_addr;                    /*fetch register*/

	        /* bit off to be able to toggle */
	        value &= ~FPGA_TRG_BIT;                /*clear "single" bit*/
	        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/

	        /*SNGL bit ON to make 0-->1 transition*/
	        value |= FPGA_TRG_BIT;                 /*set "single" bit*/
	        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/

	      	/*SNGL bit OFF to leave it in the OFF state*/
	        value &= ~FPGA_TRG_BIT;                /*clear "single" bit*/
	        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/	


		usleep(1000);

	/*====== check if initialization was successful =====*/
		short int check_par[24];

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

		usleep(1000);

	        nsmpls=26;

	        for (i = 0; i < nsmpls/2; i++) {
                	lptr = (unsigned long *) (base_ptr + i);
                	lword = *( lptr);
                	check_par[i*2] = (short) (lword & 0x0000FFFF);
                	lword =      (lword & 0xFFFF0000);
                	check_par[i*2+1] = (short) (lword >> 16);
		} /* for i  end of inner loop */
		
		success=1;
		for(i=0; i<25; i++){
			printf("par_16[%d] = %hd\n",i,par_16[i]);
			printf("check_par[%d] = %hd\n",i,check_par[i]);
			if(check_par[i] != par_16[i]) success=0;
                }

		printf("success = %d\n",success);
	} /* end while success==0 */ 	
	printf("initialization done\n");

 return 0;
 }

