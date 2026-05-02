#pragma once
#include <godot_cpp/classes/character_body3d.hpp>

namespace godot {

class GFPlayer : public CharacterBody3D {
    GDCLASS(GFPlayer, CharacterBody3D)

public:
    GFPlayer();
    ~GFPlayer();

    void step(double delta);
    
    // Properties
    void set_player_id(int p_id) { player_id = p_id; }
    int get_player_id() const { return player_id; }
    
    void set_team_id(int p_id) { team_id = p_id; }
    int get_team_id() const { return team_id; }

    // Logic
    void set_target_position(Vector3 p_pos) { target_position = p_pos; }
    Vector3 get_target_position() const { return target_position; }

protected:
    static void _bind_methods();

private:
    int player_id = 0;
    int team_id = 0;
    Vector3 target_position;
    float move_speed = 5.0f;
};

}
