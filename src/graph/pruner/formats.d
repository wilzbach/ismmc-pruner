module pruner.formats;

alias edge_t = int;

struct Read
{
    //uint chr; not needed atm
    uint start;
    uint end;
    size_t id;
}
