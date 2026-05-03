#pragma once
#include <godot_cpp/classes/area3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/array.hpp>
#include <vector>

namespace godot {

class GFBall : public Area3D {
    GDCLASS(GFBall, Area3D)

public:
    GFBall();
    ~GFBall();

    void _ready() override;

    void step(double delta);

    // Commands
    void touch(Vector3 force);
    void set_momentum(Vector3 p_momentum);
    void set_ball_position(Vector3 p_pos);

    // Queries
    Vector3 get_momentum() const { return momentum; }
    Vector3 get_predicted_position(int ms) const;
    Array get_all_predictions() const;

    // Called when a physics body enters the ball's Area3D
    void on_body_entered(Node3D *body);

protected:
    static void _bind_methods();

private:
    Vector3 momentum;

    static constexpr float BALL_RADIUS = 0.11f;
    static constexpr float TIME_STEP = 0.01f;
    static constexpr int PREDICTION_STEP_MS = 10;
    static constexpr int PREDICTION_COUNT = 100;

    // How much of the player's velocity transfers to the ball
    static constexpr float TOUCH_VELOCITY_FACTOR = 0.7f;
    // Base kick impulse applied in the ball-away-from-player direction
    static constexpr float TOUCH_BASE_FORCE = 8.0f;

    std::vector<Vector3> predictions;
    double accumulated_time = 0.0;

    // Physics constants from original GF
    float bounce = 0.62f;
    float linearBounce = 0.06f;
    float drag = 0.015f;
    float friction = 0.04f;
    float linearFriction = 1.6f;
    float gravity = -9.81f;
    float grassHeight = 0.025f;

    void integrate(Vector3 &io_pos, Vector3 &io_momentum, float dt) const;
    void calculate_predictions();
};

}
