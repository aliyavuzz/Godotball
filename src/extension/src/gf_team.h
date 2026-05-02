#pragma once
#include <godot_cpp/classes/node.hpp>
#include <vector>
#include "gf_player.h"

namespace godot {

class GFTeam : public Node {
    GDCLASS(GFTeam, Node)

public:
    GFTeam();
    ~GFTeam();

    void step(double delta);
    
    void add_player(GFPlayer* p_player);
    void set_team_id(int p_id) { team_id = p_id; }

protected:
    static void _bind_methods();

private:
    int team_id = 0;
    std::vector<GFPlayer*> players;
};

}
