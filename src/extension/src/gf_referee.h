#pragma once
#include <godot_cpp/classes/node.hpp>
#include "gf_ball.h"
#include "gf_match.h"

namespace godot {

class GFReferee : public Node {
    GDCLASS(GFReferee, Node)

public:
    GFReferee();
    ~GFReferee();

    void step(double delta);
    
    void set_ball(GFBall* p_ball) { ball = p_ball; }
    void set_match(GFMatch* p_match) { match = p_match; }

protected:
    static void _bind_methods();

private:
    GFBall* ball = nullptr;
    GFMatch* match = nullptr;
    
    // Pitch dimensions
    const float PITCH_HALF_LENGTH = 105.0f / 2.0f;
    const float PITCH_HALF_WIDTH = 68.0f / 2.0f;
    const float GOAL_HALF_WIDTH = 7.32f / 2.0f;
    const float GOAL_HEIGHT = 2.44f;

    bool was_in_goal = false;
    bool was_out_of_bounds = false;
};

}
