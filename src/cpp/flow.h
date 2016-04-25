#include <lemon/list_graph.h>
#include <lemon/preflow.h>
#include <lemon/lgf_writer.h>
#include <set>

// not needed
#include <lemon/smart_graph.h>
#include <lemon/lgf_reader.h>
#include <lemon/cycle_canceling.h>

#ifndef PRUNER_FLOW_H
#define PRUNER_FLOW_H

typedef lemon::ListDigraph Graph;
typedef std::pair<int,int> sread;
typedef std::vector<sread> reads;

struct ReadNode {
    int pos;
    const Graph::Node& lnode;
    ReadNode(int pos, const Graph::Node& lnode): pos(pos),lnode(lnode){ }
    virtual void _dummy() {} // we need ReadNode to be polymorphic
};

inline bool operator<(const ReadNode& lhs, const ReadNode& rhs)
{
    return lhs.pos < rhs.pos;
}

struct ReadNodeLeft: ReadNode{
    ReadNode* end;
    ReadNodeLeft(int pos, Graph::Node& lnode, ReadNode* node) : ReadNode(pos, lnode) {
        this->end = node;
    }
};

struct ReadNodeRight : ReadNode{
    ReadNode* start;
    ReadNodeRight(int pos, Graph::Node& lnode, ReadNode* node) : ReadNode(pos, lnode) {
        this->start = node;
    }
};

struct MaxFlowResponse{
    //reads reads,
    //reads pruned,
    int minCostFlow;
};


class Flow {

private:
    template<typename Iter, typename Func>
    static void combine_pairwise(Iter first, Iter last, Func func)
    {
        for(; first != last; ++first)
            for(Iter next = std::next(first); next != last; ++next)
                func(*first, *next);
    }


    /*
    // pairwise iterator over all positions
    auto it_first = positions.begin();
    for(auto it = ++positions.begin();it != positions.end(); ++it){
        g.addArc(g.nodeFromId(*(it_first++)), g.nodeFromId(*it));
    }*/


public:
    static void maxFlowOpt(reads& reads, int maxReadsPerPos, int minReadsPerPos){
        Graph g;
        Graph::ArcMap<int> capacity(g);
        Graph::Node node_source = g.addNode();

        std::set<ReadNode> positions;
        for(auto cur_read : reads){
            Graph::Node node1 = g.addNode();
            Graph::Node node2 = g.addNode();
            ReadNodeLeft start = ReadNodeLeft{cur_read.first, node1, NULL};
            ReadNodeRight end = ReadNodeRight{cur_read.second, node2, NULL};
            start.end = &end;
            positions.insert(start);
            positions.insert(end);
        }
        Graph::Node node_sink = g.addNode();

        int backboneCapacity = maxReadsPerPos - minReadsPerPos;
        int sourceSinkCapacity = maxReadsPerPos;
        int readIntervalCapacity = 1;

        // --------------------------- add nodes to graph


        // add arcs to super{source,sink}
        Graph::Arc firstArc = g.addArc(node_source, (*positions.begin()).lnode);
        Graph::Arc lastArc = g.addArc((*positions.rbegin()).lnode, node_sink);
        capacity[firstArc] = capacity[lastArc] = sourceSinkCapacity;

        printf("Pos: %d\n", positions.size());

        // backbone arcs
        auto it_first = positions.begin();
        auto it_second = ++positions.begin();
        while(it_second != positions.end()){
            Graph::Arc a = g.addArc((*it_first++).lnode, (*it_second++).lnode);
            capacity[a] = backboneCapacity;
        }
        // read arcs
        for(auto it=positions.begin(); it != positions.end(); ++it){
            const ReadNode* p = &(*it);
            // we only look at the left part of the read
            if(const ReadNodeLeft* test = dynamic_cast<const ReadNodeLeft*>(p)) {
                printf("read arcs");
                Graph::Arc a = g.addArc(test->lnode, test->end->lnode);
                capacity[a] = readIntervalCapacity;
            }else if (const ReadNodeRight* test = dynamic_cast<const ReadNodeRight*>(p)){
                printf("read right arcs");
            }
        }

        lemon::Preflow<Graph> preflow(g,capacity, node_source, node_sink);
        preflow.run();
        std::cout << "maximum flow by preflow: " << preflow.flowValue() << std::endl;

        //const auto f = preflow.flowMap();
        int nodes = 0;
        for(Graph::NodeIt a(g); a != lemon::INVALID; ++a){
            nodes++;
        }
        std::cout << "Nodes: " << nodes << std::endl;

        for(Graph::ArcIt a(g); a != lemon::INVALID; ++a){
            std::cout << "A: " << capacity[a] << std::endl;
        }


        // print graph details
        digraphWriter(g).                 			 // write g to the standard output
                arcMap("cap", capacity).        	 // write 'cost' for for arcs
                arcMap("flow", preflow.flowMap()).   // write 'flow' for for arcs
                node("source", node_source).            		 // write s to 'source'
                node("target", node_sink).            		 // write t to 'target'
                run();

        /*

        // add intervals
        for read in reads:
            g.add_edge(read[0], read[1], {'capacity': readIntervalCapacity})

        // TODO: implement flow algorithm
        val, mincostFlow = nx.maximum_flow(g, superSource, superSink)

         */
             /*
        pruned = []

        # TODO: this is in O(n) -> we can do it in O(log n)
        for key, values in mincostFlow.items():
        for value, weight in values.items():
        if weight is 0:
        toRemove = (key, value)
        if toRemove in reads:
        pruned.append((key, value))
        reads.remove((key, value))

        return reads, pruned, mincostFlow
            */

    }

};


#endif //PRUNER_FLOW_H
