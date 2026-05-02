#include "gf_ball.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <cmath>
#include <algorithm>

namespace godot {

GFBall::GFBall() {
    momentum = Vector3(0, 0, 0);
    predictions.resize(PREDICTION_COUNT);
}

GFBall::~GFBall() {}

void GFBall::_bind_methods() {
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFBall::step);
    ClassDB::bind_method(D_METHOD("touch", "force"), &GFBall::touch);
    ClassDB::bind_method(D_METHOD("set_momentum", "momentum"), &GFBall::set_momentum);
    ClassDB::bind_method(D_METHOD("set_ball_position", "position"), &GFBall::set_ball_position);
    ClassDB::bind_method(D_METHOD("get_momentum"), &GFBall::get_momentum);
    ClassDB::bind_method(D_METHOD("get_predicted_position", "ms"), &GFBall::get_predicted_position);
    ClassDB::bind_method(D_METHOD("get_all_predictions"), &GFBall::get_all_predictions);
}

void GFBall::step(double delta) {
    // GF uses 10ms steps for logic
    // We'll follow the original logic: Predict(10) becomes new position
    calculate_predictions();
    
    // In original GF, Process() calls CalculatePrediction and then:
    // positionBuffer = Predict(10);
    // So we move 10ms ahead in simulation time per logic step
    set_position(predictions[1]); 
    
    // We need to update momentum based on the first step of prediction
    // This is a bit simplified compared to the full Process() but captures the essence
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
    set_position(p_pos);
    momentum = Vector3(0, 0, 0);
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

void GFBall::calculate_predictions() {
    Vector3 current_pos = get_position();
    Vector3 current_momentum = momentum;
    
    float timeStep = 0.01f; // 10ms
    
    predictions[0] = current_pos;
    
    for (int i = 1; i < PREDICTION_COUNT; ++i) {
        // Gravity (Y-up in Godot)
        current_momentum.y += gravity * timeStep;
        
        // Air resistance
        float velo = current_momentum.length();
        if (velo > 0.001f) {
            float draggedVelo = velo - drag * velo * velo * timeStep;
            current_momentum = current_momentum.normalized() * draggedVelo;
        }
        
        // Bounce
        float ballBottom = current_pos.y - BALL_RADIUS;
        if (current_pos.y < BALL_RADIUS) {
            if (current_momentum.y < 0.0f) {
                current_momentum.y = -current_momentum.y * bounce;
                current_momentum.y = std::max(current_momentum.y - linearBounce, 0.0f);
            }
            current_pos.y = BALL_RADIUS;
        }
        
        // Ground friction
        if (current_pos.y < BALL_RADIUS + grassHeight) {
            float grassInfluence = std::clamp(1.0f - (ballBottom / grassHeight), 0.0f, 1.0f);
            grassInfluence = std::pow(grassInfluence, 0.7f);
            
            Vector3 horizontal_mom = Vector3(current_momentum.x, 0, current_momentum.z);
            float h_velo = horizontal_mom.length();
            
            if (h_velo > 0.001f) {
                float adaptedFriction = friction * grassInfluence;
                float newVelo = h_velo - adaptedFriction * h_velo * h_velo * timeStep;
                newVelo = std::max(newVelo - (linearFriction * grassInfluence * timeStep), 0.0f);
                
                current_momentum.x = (horizontal_mom.x / h_velo) * newVelo;
                current_momentum.z = (horizontal_mom.z / h_velo) * newVelo;
            }
        }
        
        // Next pos
        current_pos += current_momentum * timeStep;
        predictions[i] = current_pos;
        
        if (i == 1) {
            // Update the real momentum for the next 'step'
            // In a real port, we'd handle this more carefully
            momentum = current_momentum;
        }
    }
}

}
