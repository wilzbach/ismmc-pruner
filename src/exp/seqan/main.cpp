#include <iostream>
#include <seqan/stream.h>
#include <seqan/bam_io.h>

using namespace seqan;

int main(int argc, char * argv[]) {

    if(argc < 3){
        std::cerr << "No input nor output files provided" << std::endl;
        return 1;
    }
    // Open input stream, BamStream can read SAM and BAM files.
    const std::string inFile(argv[1]);
    const std::string outFile(argv[2]);

    BamFileIn bamFileIn;
    if (!open(bamFileIn, toCString(inFile)))
    {
        std::cerr << "Can't open the file." << std::endl;
        return 1;
    }

    // Open output stream. The value "-" means reading from stdin or writing to stdout.
    BamFileOut bamFileOut(bamFileIn);
    open(bamFileOut, std::cout, Sam());

    // Copy header. The header is automatically written out before the first record.
    BamHeader header;
    readHeader(header, bamFileIn);
    writeHeader(bamFileOut, header);

    // BamAlignmentRecord stores one record at a time.
    BamAlignmentRecord record;
    int i = 0;
    while (!atEnd(bamFileIn))
    {
        readRecord(record, bamFileIn);
        //writeRecord(bamFileOut, record);
        ++i;
    }
    printf("%d", i);
    return 0;
}