#include "gf_match.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot {

GFMatch::GFMatch() {}
GFMatch::~GFMatch() {}

void GFMatch::_bind_methods() {
    ClassDB::bind_method(D_METHOD("add_goal", "team_id"), &GFMatch::add_goal);
    ClassDB::bind_method(D_METHOD("get_score_home"), &GFMatch::get_score_home);
    ClassDB::bind_method(D_METHOD("get_score_away"), &GFMatch::get_score_away);
    ClassDB::bind_method(D_METHOD("get_match_time"), &GFMatch::get_match_time);
    ClassDB::bind_method(D_METHOD("set_match_time", "time"), &GFMatch::set_match_time);
    ClassDB::bind_method(D_METHOD("get_match_phase"), &GFMatch::get_match_phase);
    ClassDB::bind_method(D_METHOD("set_match_phase", "phase"), &GFMatch::set_match_phase);
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFMatch::step);

    ADD_SIGNAL(MethodInfo("score_changed", PropertyInfo(Variant::INT, "home"), PropertyInfo(Variant::INT, "away")));
    ADD_SIGNAL(MethodInfo("phase_changed", PropertyInfo(Variant::INT, "new_phase")));
}

void GFMatch::step(double delta) {
    if (phase == MatchPhase_FirstHalf || phase == MatchPhase_SecondHalf) {
        match_time += delta;
    }
}

void GFMatch::add_goal(int team_id) {
    if (team_id == 0) score_home++;
    else score_away++;
    emit_signal("score_changed", score_home, score_away);
}

}
