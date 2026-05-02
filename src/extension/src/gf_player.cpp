#include "gf_player.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot {

GFPlayer::GFPlayer() {
    target_position = Vector3(0, 0, 0);
}

GFPlayer::~GFPlayer() {}

void GFPlayer::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_player_id", "id"), &GFPlayer::set_player_id);
    ClassDB::bind_method(D_METHOD("get_player_id"), &GFPlayer::get_player_id);
    ClassDB::bind_method(D_METHOD("set_team_id", "id"), &GFPlayer::set_team_id);
    ClassDB::bind_method(D_METHOD("get_team_id"), &GFPlayer::get_team_id);
    ClassDB::bind_method(D_METHOD("set_target_position", "pos"), &GFPlayer::set_target_position);
    ClassDB::bind_method(D_METHOD("get_target_position"), &GFPlayer::get_target_position);
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFPlayer::step);
    ClassDB::bind_method(D_METHOD("get_velocity"), &GFPlayer::get_velocity);
}

void GFPlayer::step(double delta) {
    Vector3 pos = get_position();
    Vector3 diff = target_position - pos;
    diff.y = 0; // Keep on ground
    
    if (diff.length() > 0.1f) {
        Vector3 velocity = diff.normalized() * move_speed;
        set_velocity(velocity);
        move_and_slide();
        
        // Face movement direction
        if (velocity.length() > 0.1f) {
            look_at(pos + velocity, Vector3(0, 1, 0));
        }
    } else {
        set_velocity(Vector3(0, 0, 0));
    }
}

}
