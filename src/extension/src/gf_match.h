#pragma once
#include <godot_cpp/classes/node.hpp>

namespace godot {

enum GFMatchPhase {
    MatchPhase_PreMatch,
    MatchPhase_FirstHalf,
    MatchPhase_HalfTime,
    MatchPhase_SecondHalf,
    MatchPhase_FullTime
};

class GFMatch : public Node {
    GDCLASS(GFMatch, Node)

public:
    GFMatch();
    ~GFMatch();

    void step(double delta);
    
    // Score
    void add_goal(int team_id);
    int get_score_home() const { return score_home; }
    int get_score_away() const { return score_away; }

    // Time
    float get_match_time() const { return match_time; }
    void set_match_time(float p_time) { match_time = p_time; }

    // Phase
    int get_match_phase() const { return (int)phase; }
    void set_match_phase(int p_phase) { phase = (GFMatchPhase)p_phase; }

protected:
    static void _bind_methods();

private:
    int score_home = 0;
    int score_away = 0;
    float match_time = 0.0f;
    GFMatchPhase phase = MatchPhase_FirstHalf;
};

}
