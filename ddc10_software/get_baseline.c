/* 
 *
 *      bfin-linux-uclibc-gcc -Wall -o get_baseline -mfdpic get_baseline.c
 */

#include <unistd.h>     /*sleep and usleep*/
#include <sys/time.h>   /*gettimeofday*/

#include <stdio.h>
#include <stdlib.h>
// #include <unistd.h>  /* commented out for future use*/
// #include <string.h>
// #include <errno.h>
// #include <signal.h>
// #include <fcntl.h>
// #include <ctype.h>
// #include <termios.h>
// #include <sys/types.h>
// #include <sys/mman.h>


#include "../bitmasks.h"        /*useful bitmasks*/
#include "../fpga_4futils.h"    /*FPGA addresses*/
#include "../fcommon.c"         /*FPGA utility functions*/

int main() {

        short *virt_addr;       /* CTRL reg is 16 bits */
        short value;

        virt_addr = (short *) FPGA_CTRL_REG;    /*typecast*/
        value = * virt_addr;                    /*fetch register*/

        /* SNGL, AUTO, TRIGGER bits off to be able to toggle */
        value &= ~FPGA_SNGL_BIT;                /*clear "single" bit*/
//        value &= ~FPGA_AUTO_BIT;                /*clear "auto" bit*/
//        value &= ~FPGA_TRG_BIT;                 /*clear "trigger" bit*/
//        value &= ~FPGA_INI_BIT;                 /*clear "ini" bit*/
        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/

        /*SNGL bit ON to make 0-->1 transition*/
        value |= FPGA_SNGL_BIT;                 /*set "single" bit*/
        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/

        /*SNGL bit OFF to leave it in the OFF state*/
        value &= ~FPGA_SNGL_BIT;                /*clear "single" bit*/
        Sshort_to_FPGA (FPGA_CTRL_REG, value);  /*send to FPGA*/


	return 0;
}; /* StartFPGA_single */

