#include <stdio.h>
#include <stdlib.h>
#include <bam/bam.h>

int main(int argc, char** argv)
{
    if(argc < 3){
        printf("No input nor output files provided");
        return -1;
    }

    bam1_t* b = bam_init1();
    bamFile in = bam_open(argv[1], "r");
    bam_header_t* header;
    if (in == NULL){
        printf("opening input file failed");
        return -1;
    }
    if (b == NULL){
        printf("init bam buffer failed");
        return -1;
    }

    bamFile out = bam_open(argv[2], "w");
    if (out == NULL){
        printf("opening input file failed");
        return -1;
    }

    header = bam_header_read(in);
    if(bam_header_write(out, header) < 0){
        printf("writing header failed");
    }
    while (bam_read1(in, b) >= 0) {
        bam_write1(out, b);
        // mpos?
        //printf("%d", b->core.pos, b->core->l_qseq);
    }

    // closing all resources
    bam_header_destroy(header);
    bam_close(in);
    bam_close(out);
    bam_destroy1(b);
    return 0;
}
