#include "gf_referee.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

GFReferee::GFReferee() {}
GFReferee::~GFReferee() {}

void GFReferee::_bind_methods() {
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFReferee::step);
    ClassDB::bind_method(D_METHOD("set_ball", "ball"), &GFReferee::set_ball);
    ClassDB::bind_method(D_METHOD("set_match", "match"), &GFReferee::set_match);

    ADD_SIGNAL(MethodInfo("goal_scored", PropertyInfo(Variant::INT, "team_id")));
    ADD_SIGNAL(MethodInfo("ball_out", PropertyInfo(Variant::VECTOR3, "position")));
}

void GFReferee::step(double delta) {
    if (!ball || !match) return;

    Vector3 pos = ball->get_position();
    
    // Check for goal
    bool in_goal_home = (pos.x < -PITCH_HALF_LENGTH && std::abs(pos.z) < GOAL_HALF_WIDTH && pos.y < GOAL_HEIGHT);
    bool in_goal_away = (pos.x > PITCH_HALF_LENGTH && std::abs(pos.z) < GOAL_HALF_WIDTH && pos.y < GOAL_HEIGHT);
    
    if (in_goal_home && !was_in_goal) {
        UtilityFunctions::print("Referee: GOAL AWAY!");
        match->add_goal(1);
        emit_signal("goal_scored", 1);
        was_in_goal = true;
    } else if (in_goal_away && !was_in_goal) {
        UtilityFunctions::print("Referee: GOAL HOME!");
        match->add_goal(0);
        emit_signal("goal_scored", 0);
        was_in_goal = true;
    }
    
    if (!in_goal_home && !in_goal_away) {
        was_in_goal = false;
    }

    // Check for out of bounds (simplified)
    bool out_of_bounds = (std::abs(pos.x) > PITCH_HALF_LENGTH || std::abs(pos.z) > PITCH_HALF_WIDTH);
    if (out_of_bounds && !was_out_of_bounds && !in_goal_home && !in_goal_away) {
        UtilityFunctions::print("Referee: Ball out of bounds");
        emit_signal("ball_out", pos);
        was_out_of_bounds = true;
    } else if (!out_of_bounds) {
        was_out_of_bounds = false;
    }
}

}
