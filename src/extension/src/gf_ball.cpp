#include "gf_ball.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <cmath>
#include <algorithm>

namespace godot {

GFBall::GFBall() {
    momentum = Vector3(0, 0, 0);
    predictions.resize(PREDICTION_COUNT);
}

GFBall::~GFBall() {}

void GFBall::_ready() {
    // Build collision shape at runtime so the scene file stays minimal
    CollisionShape3D *shape_node = memnew(CollisionShape3D);
    Ref<SphereShape3D> sphere;
    sphere.instantiate();
    sphere->set_radius(BALL_RADIUS);
    shape_node->set_shape(sphere);
    add_child(shape_node);

    set_monitoring(true);
    set_monitorable(true);
    connect("body_entered", Callable(this, "on_body_entered"));
}

void GFBall::_bind_methods() {
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFBall::step);
    ClassDB::bind_method(D_METHOD("touch", "force"), &GFBall::touch);
    ClassDB::bind_method(D_METHOD("set_momentum", "momentum"), &GFBall::set_momentum);
    ClassDB::bind_method(D_METHOD("set_ball_position", "position"), &GFBall::set_ball_position);
    ClassDB::bind_method(D_METHOD("get_momentum"), &GFBall::get_momentum);
    ClassDB::bind_method(D_METHOD("get_predicted_position", "ms"), &GFBall::get_predicted_position);
    ClassDB::bind_method(D_METHOD("get_all_predictions"), &GFBall::get_all_predictions);
    ClassDB::bind_method(D_METHOD("on_body_entered", "body"), &GFBall::on_body_entered);
}

void GFBall::on_body_entered(Node3D *body) {
    Vector3 dir_to_ball = (get_global_position() - body->get_global_position()).normalized();

    // Pull the player's current velocity if available (GFPlayer exposes get_velocity())
    Vector3 player_vel = Vector3(0, 0, 0);
    if (body->has_method("get_velocity")) {
        Variant v = body->call("get_velocity");
        if (v.get_type() == Variant::VECTOR3) {
            player_vel = (Vector3)v;
        }
    }

    Vector3 force = (player_vel * TOUCH_VELOCITY_FACTOR) + (dir_to_ball * TOUCH_BASE_FORCE);
    touch(force);
}

void GFBall::step(double delta) {
    // Run the simulation at a fixed 10 ms tick (100 Hz) regardless of frame rate.
    // The original GameplayFootball engine uses the same fixed timestep.
    accumulated_time += delta;

    // Cap the accumulator to avoid the "spiral of death" if the game stalls.
    if (accumulated_time > 0.25) {
        accumulated_time = 0.25;
    }

    Vector3 pos = get_global_position();

    while (accumulated_time >= TIME_STEP) {
        integrate(pos, momentum, TIME_STEP);
        accumulated_time -= TIME_STEP;
    }

    set_global_position(pos);

    // Refresh prediction buffer so external queries (AI, camera) see fresh data.
    calculate_predictions();
}

void GFBall::touch(Vector3 force) {
    momentum += force;
    calculate_predictions();
}

void GFBall::set_momentum(Vector3 p_momentum) {
    momentum = p_momentum;
    calculate_predictions();
}

void GFBall::set_ball_position(Vector3 p_pos) {
    set_global_position(p_pos);
    momentum = Vector3(0, 0, 0);
    accumulated_time = 0.0;
    calculate_predictions();
}

Vector3 GFBall::get_predicted_position(int ms) const {
    int index = ms / PREDICTION_STEP_MS;
    if (index < 0) index = 0;
    if (index >= PREDICTION_COUNT) index = PREDICTION_COUNT - 1;
    return predictions[index];
}

Array GFBall::get_all_predictions() const {
    Array arr;
    for (const auto& p : predictions) {
        arr.push_back(p);
    }
    return arr;
}

// Single fixed-step physics integration.
// Mirrors Ball::CalculatePrediction step from the original GF engine
// (gravity → drag → bounce → ground friction → translation), but operates on
// GLOBAL coordinates so a parent node transform cannot break the ground check.
void GFBall::integrate(Vector3 &io_pos, Vector3 &io_momentum, float dt) const {
    // Gravity (Y-up in Godot)
    io_momentum.y += gravity * dt;

    // Air resistance (quadratic drag)
    float velo = io_momentum.length();
    if (velo > 0.001f) {
        float draggedVelo = velo - drag * velo * velo * dt;
        if (draggedVelo < 0.0f) draggedVelo = 0.0f;
        io_momentum = io_momentum.normalized() * draggedVelo;
    }

    // Bounce off ground (Y == BALL_RADIUS is the rest height of a ball on the pitch)
    float ballBottom = io_pos.y - BALL_RADIUS;
    if (io_pos.y < BALL_RADIUS) {
        if (io_momentum.y < 0.0f) {
            io_momentum.y = -io_momentum.y * bounce;
            io_momentum.y = std::max(io_momentum.y - linearBounce, 0.0f);
        }
        io_pos.y = BALL_RADIUS;
    }

    // Ground friction inside the grass blade band
    if (io_pos.y < BALL_RADIUS + grassHeight) {
        float grassInfluence = std::clamp(1.0f - (ballBottom / grassHeight), 0.0f, 1.0f);
        grassInfluence = std::pow(grassInfluence, 0.7f);

        Vector3 horizontal_mom = Vector3(io_momentum.x, 0, io_momentum.z);
        float h_velo = horizontal_mom.length();

        if (h_velo > 0.001f) {
            float adaptedFriction = friction * grassInfluence;
            float newVelo = h_velo - adaptedFriction * h_velo * h_velo * dt;
            newVelo = std::max(newVelo - (linearFriction * grassInfluence * dt), 0.0f);

            io_momentum.x = (horizontal_mom.x / h_velo) * newVelo;
            io_momentum.z = (horizontal_mom.z / h_velo) * newVelo;
        }
    }

    // Translate
    io_pos += io_momentum * dt;
}

void GFBall::calculate_predictions() {
    // Read-only forward simulation; we never mutate `momentum` here so prediction
    // queries are side-effect free.
    Vector3 sim_pos = get_global_position();
    Vector3 sim_mom = momentum;

    predictions[0] = sim_pos;
    for (int i = 1; i < PREDICTION_COUNT; ++i) {
        integrate(sim_pos, sim_mom, TIME_STEP);
        predictions[i] = sim_pos;
    }
}

}
