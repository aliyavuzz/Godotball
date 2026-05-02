#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

class GFGameState : public Node {
    GDCLASS(GFGameState, Node)

public:
    GFGameState();
    ~GFGameState();

    void start_match();
    void stop_match();
    void step(double delta);

    Dictionary get_ball_state() const;
    Array get_players_state() const;
    int get_score_home() const;
    int get_score_away() const;
    bool is_in_play() const;
    int get_game_mode() const;

protected:
    static void _bind_methods();

private:
    bool m_running = false;
    double m_accumulated_time = 0.0;
    static constexpr double STEP_TIME = 0.01; // 100Hz sim
};

} // namespace godot
