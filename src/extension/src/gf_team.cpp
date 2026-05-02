#include "gf_team.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot {

GFTeam::GFTeam() {}
GFTeam::~GFTeam() {}

void GFTeam::_bind_methods() {
    ClassDB::bind_method(D_METHOD("add_player", "player"), &GFTeam::add_player);
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFTeam::step);
}

void GFTeam::add_player(GFPlayer* p_player) {
    players.push_back(p_player);
}

void GFTeam::step(double delta) {
    for (auto player : players) {
        player->step(delta);
    }
}

}
