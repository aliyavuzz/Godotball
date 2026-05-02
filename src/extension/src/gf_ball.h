#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/array.hpp>
#include <vector>

namespace godot {

class GFBall : public Node3D {
    GDCLASS(GFBall, Node3D)

public:
    GFBall();
    ~GFBall();

    void step(double delta);
    
    // Commands
    void touch(Vector3 force);
    void set_momentum(Vector3 p_momentum);
    void set_ball_position(Vector3 p_pos);

    // Queries
    Vector3 get_momentum() const { return momentum; }
    Vector3 get_predicted_position(int ms) const;
    Array get_all_predictions() const;

protected:
    static void _bind_methods();

private:
    Vector3 momentum; // m/s
    // Godot uses Y-up, GF uses Z-up. 
    // We will use Godot coordinates internally to avoid confusion in the scene.
    
    static constexpr float BALL_RADIUS = 0.11f;
    static constexpr int PREDICTION_STEP_MS = 10;
    static constexpr int PREDICTION_COUNT = 100; // 1 second prediction
    
    std::vector<Vector3> predictions;
    
    // Physics constants from original GF
    float bounce = 0.62f;
    float linearBounce = 0.06f;
    float drag = 0.015f;
    float friction = 0.04f;
    float linearFriction = 1.6f;
    float gravity = -9.81f;
    float grassHeight = 0.025f;

    void calculate_predictions();
};

}
