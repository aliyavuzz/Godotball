#include "register_types.h"
#include "gf_game_state.h"
#include "gf_ball.h"
#include "gf_match.h"
#include "gf_referee.h"
#include "gf_player.h"
#include "gf_team.h"
#include <godot_cpp/core/defs.hpp>
#include <gdextension_interface.h>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_football_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    ClassDB::register_class<GFGameState>();
    ClassDB::register_class<GFBall>();
    ClassDB::register_class<GFMatch>();
    ClassDB::register_class<GFReferee>();
    ClassDB::register_class<GFPlayer>();
    ClassDB::register_class<GFTeam>();
}

void uninitialize_football_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
}

extern "C" {
GDExtensionBool GDE_EXPORT football_library_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    const GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization)
{
    godot::GDExtensionBinding::InitObject init_obj(
        p_get_proc_address, p_library, r_initialization);
    init_obj.register_initializer(initialize_football_module);
    init_obj.register_terminator(uninitialize_football_module);
    init_obj.set_minimum_library_initialization_level(
        MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}
