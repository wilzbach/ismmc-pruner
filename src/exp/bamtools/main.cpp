#include <api/BamMultiReader.h>
#include <api/BamWriter.h>

int main(int argc, char * argv[]) {

    if(argc < 3){
        std::cerr << "No input nor output files provided" << std::endl;
        return 1;
    }

    const std::string inFile(argv[1]);
    const std::string outFile(argv[2]);

    BamTools::BamReader reader;
    if (!reader.Open(inFile)) {
        std::cerr << "Could not open input BAM file." << std::endl;
        return 1;
    }

    // retrieve 'metadata' from BAM files, these are required by BamWriter
    const BamTools::SamHeader header = reader.GetHeader();
    const BamTools::RefVector references = reader.GetReferenceData();

    BamTools::BamWriter writer;
    if (!writer.Open(outFile, header, references)) {
        std::cerr << "Could not open output BAM file" << std::endl;
        return 1;
    }
    // iterate through all alignments, only keeping ones with high map quality
    BamTools::BamAlignment al;
    int i = 0;
    while (reader.GetNextAlignmentCore(al)) {
        if (al.MapQuality >= 50) {
            i++;
            //writer.SaveAlignment(al);
            // TODO map quality?
            //printf("%d-%d-%d\n", al.Position, al.Length, al.MatePosition);
            //std::cout << al.QueryBases << "-" << al.AlignedBases;
        }
    }
    // close the reader & writer
    reader.Close();
    writer.Close();
    return 0;
}