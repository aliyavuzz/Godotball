#include "gf_game_state.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>

namespace godot {

GFGameState::GFGameState() {}
GFGameState::~GFGameState() {}

void GFGameState::_bind_methods() {
    ClassDB::bind_method(D_METHOD("start_match"), &GFGameState::start_match);
    ClassDB::bind_method(D_METHOD("stop_match"), &GFGameState::stop_match);
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFGameState::step);
    ClassDB::bind_method(D_METHOD("get_ball_state"), &GFGameState::get_ball_state);
    ClassDB::bind_method(D_METHOD("get_players_state"), &GFGameState::get_players_state);
    ClassDB::bind_method(D_METHOD("get_score_home"), &GFGameState::get_score_home);
    ClassDB::bind_method(D_METHOD("get_score_away"), &GFGameState::get_score_away);
    ClassDB::bind_method(D_METHOD("is_in_play"), &GFGameState::is_in_play);
    ClassDB::bind_method(D_METHOD("get_game_mode"), &GFGameState::get_game_mode);

    ADD_SIGNAL(MethodInfo("goal_scored",
        PropertyInfo(Variant::INT, "team")));
    ADD_SIGNAL(MethodInfo("game_mode_changed",
        PropertyInfo(Variant::INT, "mode")));
    ADD_SIGNAL(MethodInfo("match_ended"));
}

void GFGameState::start_match() {
    m_running = true;
    m_accumulated_time = 0.0;
    UtilityFunctions::print("GFGameState: match started");
}

void GFGameState::stop_match() {
    m_running = false;
    UtilityFunctions::print("GFGameState: match stopped");
}

void GFGameState::step(double delta) {
    if (!m_running) return;
    m_accumulated_time += delta;
    while (m_accumulated_time >= STEP_TIME) {
        // TODO Phase 4: m_match->Process(STEP_TIME * 1000);
        m_accumulated_time -= STEP_TIME;
    }
}

Dictionary GFGameState::get_ball_state() const {
    Dictionary d;
    d["x"] = 0.0;
    d["y"] = 0.0;
    d["z"] = 0.11;
    d["vx"] = 0.0;
    d["vy"] = 0.0;
    d["vz"] = 0.0;
    return d;
}

Array GFGameState::get_players_state() const {
    Array arr;
    for (int i = 0; i < 22; i++) {
        Dictionary p;
        p["id"] = i;
        p["team"] = (i < 11) ? 0 : 1;
        p["x"] = (i % 11) * 5.0 - 25.0;
        p["y"] = (i < 11) ? -10.0 : 10.0;
        p["vx"] = 0.0;
        p["vy"] = 0.0;
        p["role"] = i % 10;
        arr.push_back(p);
    }
    return arr;
}

int GFGameState::get_score_home() const { return 0; }
int GFGameState::get_score_away() const { return 0; }
bool GFGameState::is_in_play() const { return m_running; }
int GFGameState::get_game_mode() const { return 0; }

} // namespace godot
