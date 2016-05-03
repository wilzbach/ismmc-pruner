#include <stdio.h>
#include <stdlib.h>
#include <bam.h>

int main(int argc, char** argv)
{
    if(argc < 2){
        printf("No input nor output files provided");
        return -1;
    }

    bamFile in = bam_open(argv[1], "r");
    bam_header_t* header;
    if (in == NULL){
        printf("opening input file failed\n");
        return -1;
    }

    bam1_t* b = bam_init1();

    header = bam_header_read(in);
    long id = 0;
    while (bam_read1(in, b) >= 0) {
        // defined in sam.h
        printf("%d\t%d\t%d\t%d\n", b->core.tid, b->core.pos, b->core.pos + b->core.l_qseq, id++);
    }

    // closing all resources
    bam_header_destroy(header);
    bam_close(in);
    bam_destroy1(b);
    return 0;
}
