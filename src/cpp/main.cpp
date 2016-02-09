#include <iostream>
#include <seqan/stream.h>
#include <seqan/bam_io.h>

int main()
{
    // Open input stream, BamStream can read SAM and BAM files.
    std::string pathSam = std::string("/home/xsebi/hel/thesis/chain/data/chr1.reads.bam");

    seqan::BamFileIn bamFileIn;
    if (!open(bamFileIn, seqan::toCString(pathSam)))
    {
        std::cerr << "Can't open the file." << std::endl;
        return 1;
    }

    // Open output stream. The value "-" means reading from stdin or writing to stdout.
    seqan::BamFileOut bamFileOut(bamFileIn);
    open(bamFileOut, std::cout, seqan::Sam());

    // Copy header. The header is automatically written out before the first record.
    seqan::BamHeader header;
    readHeader(header, bamFileIn);
    seqan::writeHeader(bamFileOut, header);

    // BamAlignmentRecord stores one record at a time.
    seqan::BamAlignmentRecord record;
    while (!atEnd(bamFileIn))
    {
        readRecord(record, bamFileIn);
        printf("%d %d", record.beginPos, record.tLen);
        //writeRecord(bamFileOut, record);
        break;
    }
    return 0;
}