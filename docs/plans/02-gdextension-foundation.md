# GDExtension Foundation Implementation Plan

> **For agentic workers:** Use `superpowers:verification-before-completion` before marking done.

**Goal:** GameplayFootball'ın C++ oyun mantığını (Match, Ball, Player, AI) GDExtension olarak Godot 4'e bağlayan köprü katmanını oluşturmak.

**Architecture:** `godot-cpp` kullanarak GameplayFootball C++ kaynak kodunu GDExtension'a wrap ederiz. Godot tarafında GDScript, C++ sınıflarını sanki native Godot node'uymuş gibi kullanır. Sinyal sistemi ile C++ → GDScript event iletimi sağlanır.

**Tech Stack:** C++17, godot-cpp 4.4, SCons, CMake

---

## Başlamadan Önce

```bash
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
cat ~/agents/football-godot/docs/PROJECT.md
ls ~/agents/football-godot/src/extension/godot-cpp/
```

---

## Task 1: godot-cpp Build

**Files:**
- Modify: `src/extension/SConstruct` (yeni dosya)

- [ ] **Step 1: godot-cpp derle**

```bash
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
cd ~/agents/football-godot/src/extension/godot-cpp
scons platform=linux target=template_debug -j4 2>&1 | tail -20
# Beklenen: son satır "scons: done building targets."
ls bin/libgodot-cpp.linux.template_debug.x86_64.a
```

- [ ] **Step 2: Derleme başarısız olursa hata ayıkla**

```bash
# Eksik bağımlılık varsa:
# python3-dev gerekli olabilir
python3-config --includes 2>/dev/null || echo "python3-dev eksik"
# Devam etmek için: scons verbose=yes ile detaylı hata gör
scons platform=linux target=template_debug -j4 verbose=yes 2>&1 | grep -E "error:|warning:" | head -20
```

- [ ] **Step 3: Sonucu doğrula**

```bash
ls -lh ~/agents/football-godot/src/extension/godot-cpp/bin/
# libgodot-cpp.linux.template_debug.x86_64.a görünmeli
```

---

## Task 2: GDExtension Proje Yapısı

**Files:**
- Create: `src/extension/src/register_types.h`
- Create: `src/extension/src/register_types.cpp`
- Create: `src/extension/src/gf_game_state.h`
- Create: `src/extension/src/gf_game_state.cpp`
- Create: `src/extension/football_gf.gdextension`
- Create: `src/extension/SConstruct`

- [ ] **Step 1: Dizin yap**

```bash
mkdir -p ~/agents/football-godot/src/extension/src
mkdir -p ~/agents/football-godot/src/extension/bin
```

- [ ] **Step 2: GFGameState header yaz**

```cpp
// src/extension/src/gf_game_state.h
#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

// GameplayFootball'ın maç durumunu Godot'a aktaran köprü sınıfı.
// Her frame'de C++ match state'i okur, Godot'a sinyal gönderir.
class GFGameState : public Node {
    GDCLASS(GFGameState, Node)

public:
    GFGameState();
    ~GFGameState();

    // Maç kontrolü
    void start_match();
    void stop_match();
    void step(double delta);

    // Durum okuma (GDScript'ten çağrılır)
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
    static constexpr double STEP_TIME = 0.01; // 10ms = 100Hz sim

    // İleride gerçek GF Match pointer buraya gelecek
    // Match* m_match = nullptr;
};

} // namespace godot
```

- [ ] **Step 3: GFGameState implementation yaz**

```cpp
// src/extension/src/gf_game_state.cpp
#include "gf_game_state.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>

namespace godot {

GFGameState::GFGameState() {}
GFGameState::~GFGameState() {}

void GFGameState::_bind_methods() {
    ClassDB::bind_method(D_METHOD("start_match"), &GFGameState::start_match);
    ClassDB::bind_method(D_METHOD("stop_match"), &GFGameState::stop_match);
    ClassDB::bind_method(D_METHOD("step", "delta"), &GFGameState::step);
    ClassDB::bind_method(D_METHOD("get_ball_state"), &GFGameState::get_ball_state);
    ClassDB::bind_method(D_METHOD("get_players_state"), &GFGameState::get_players_state);
    ClassDB::bind_method(D_METHOD("get_score_home"), &GFGameState::get_score_home);
    ClassDB::bind_method(D_METHOD("get_score_away"), &GFGameState::get_score_away);
    ClassDB::bind_method(D_METHOD("is_in_play"), &GFGameState::is_in_play);
    ClassDB::bind_method(D_METHOD("get_game_mode"), &GFGameState::get_game_mode);

    // Sinyaller
    ADD_SIGNAL(MethodInfo("goal_scored",
        PropertyInfo(Variant::INT, "team")));
    ADD_SIGNAL(MethodInfo("game_mode_changed",
        PropertyInfo(Variant::INT, "mode")));
    ADD_SIGNAL(MethodInfo("match_ended"));
}

void GFGameState::start_match() {
    m_running = true;
    m_accumulated_time = 0.0;
    UtilityFunctions::print("GFGameState: match started");
}

void GFGameState::stop_match() {
    m_running = false;
    UtilityFunctions::print("GFGameState: match stopped");
}

void GFGameState::step(double delta) {
    if (!m_running) return;
    m_accumulated_time += delta;
    // Sabit adım simülasyonu: 100Hz
    while (m_accumulated_time >= STEP_TIME) {
        // TODO Faz 4'te: m_match->Process(STEP_TIME * 1000);
        m_accumulated_time -= STEP_TIME;
    }
}

Dictionary GFGameState::get_ball_state() const {
    Dictionary d;
    // TODO Faz 4'te: gerçek top pozisyonu
    // Şimdilik merkez pozisyon döndür (test için)
    d["x"] = 0.0;
    d["y"] = 0.0;
    d["z"] = 0.11; // top yarıçapı
    d["vx"] = 0.0;
    d["vy"] = 0.0;
    d["vz"] = 0.0;
    return d;
}

Array GFGameState::get_players_state() const {
    Array arr;
    // TODO Faz 6'da: gerçek oyuncu pozisyonları
    // Test: 22 dummy oyuncu
    for (int i = 0; i < 22; i++) {
        Dictionary p;
        p["id"] = i;
        p["team"] = (i < 11) ? 0 : 1;
        p["x"] = (i % 11) * 5.0 - 25.0;
        p["y"] = (i < 11) ? -10.0 : 10.0;
        p["vx"] = 0.0;
        p["vy"] = 0.0;
        p["role"] = i % 10;
        arr.push_back(p);
    }
    return arr;
}

int GFGameState::get_score_home() const { return 0; }
int GFGameState::get_score_away() const { return 0; }
bool GFGameState::is_in_play() const { return m_running; }
int GFGameState::get_game_mode() const { return 0; }

} // namespace godot
```

- [ ] **Step 4: register_types yaz**

```cpp
// src/extension/src/register_types.h
#pragma once
#include <godot_cpp/core/class_db.hpp>

void initialize_football_module(godot::ModuleInitializationLevel p_level);
void uninitialize_football_module(godot::ModuleInitializationLevel p_level);
```

```cpp
// src/extension/src/register_types.cpp
#include "register_types.h"
#include "gf_game_state.h"
#include <godot_cpp/core/defs.hpp>
#include <gdextension_interface.h>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_football_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    ClassDB::register_class<GFGameState>();
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
```

- [ ] **Step 5: SConstruct yaz**

```python
# src/extension/SConstruct
import os, sys
env = SConscript('godot-cpp/SConstruct')
env.Append(CPPPATH=['src/'])
sources = Glob('src/*.cpp')
library = env.SharedLibrary(
    'bin/libfootball{}{}'.format(
        env['suffix'], env['SHLIBSUFFIX']
    ),
    source=sources,
)
Default(library)
```

- [ ] **Step 6: .gdextension manifest yaz**

```ini
# src/extension/football_gf.gdextension
[configuration]
entry_symbol = "football_library_init"
compatibility_minimum = "4.4"

[libraries]
linux.debug.x86_64 = "res://bin/libfootball.linux.template_debug.x86_64.so"
linux.release.x86_64 = "res://bin/libfootball.linux.template_release.x86_64.so"
```

- [ ] **Step 7: Derle**

```bash
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
cd ~/agents/football-godot/src/extension
scons platform=linux target=template_debug -j4 2>&1 | tail -10
ls bin/libfootball*.so
# Beklenen: libfootball.linux.template_debug.x86_64.so
```

- [ ] **Step 8: Commit**

```bash
cd ~/agents/football-godot
git add src/extension/
git commit -m "feat: GDExtension foundation - GFGameState bridge class"
```

---

## Task 3: Godot Projesi Oluştur ve Extension Test Et

**Files:**
- Create: `src/godot/project.godot`
- Create: `src/godot/addons/football_gf/football_gf.gdextension` (symlink)
- Create: `src/godot/test/test_extension.gd`

- [ ] **Step 1: Godot projesi başlat**

```bash
mkdir -p ~/agents/football-godot/src/godot
# Godot project.godot oluştur
cat > ~/agents/football-godot/src/godot/project.godot << 'EOF'
; Engine configuration file.
[application]
config/name="Football GF Port"
config/features=PackedStringArray("4.4", "Forward Plus")
config/icon="res://icon.svg"

[physics]
3d/physics_engine="JoltPhysics3D"

[rendering]
renderer/rendering_method="forward_plus"
EOF

# Extension binary'yi godot proje dizinine kopyala/linkle
mkdir -p ~/agents/football-godot/src/godot/bin
cp ~/agents/football-godot/src/extension/bin/libfootball*.so \
   ~/agents/football-godot/src/godot/bin/
cp ~/agents/football-godot/src/extension/football_gf.gdextension \
   ~/agents/football-godot/src/godot/

echo "Godot projesi hazır"
```

- [ ] **Step 2: Headless test scripti yaz**

```gdscript
# src/godot/test/test_extension.gd
extends SceneTree

func _init():
    print("=== GDExtension Test ===")

    # GFGameState oluştur
    var gs = GFGameState.new()
    assert(gs != null, "GFGameState oluşturulamadı")
    print("PASS: GFGameState instantiated")

    # Maç başlat
    gs.start_match()
    assert(gs.is_in_play(), "Maç başlamadı")
    print("PASS: start_match()")

    # Ball state al
    var ball = gs.get_ball_state()
    assert(ball.has("x"), "ball state x yok")
    assert(ball.has("y"), "ball state y yok")
    print("PASS: get_ball_state() = ", ball)

    # Player state al
    var players = gs.get_players_state()
    assert(players.size() == 22, "22 oyuncu bekleniyor, " + str(players.size()) + " geldi")
    print("PASS: get_players_state() = 22 oyuncu")

    # Step çalıştır
    gs.step(0.016)
    print("PASS: step(0.016)")

    # Durdur
    gs.stop_match()
    assert(!gs.is_in_play(), "Maç durdurulamadı")
    print("PASS: stop_match()")

    print("=== ALL TESTS PASSED ===")
    quit()
```

- [ ] **Step 3: Headless modda test çalıştır**

```bash
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
cd ~/agents/football-godot/src/godot
~/bin/godot4 --headless --script test/test_extension.gd 2>&1
# Beklenen: "=== ALL TESTS PASSED ==="
```

- [ ] **Step 4: Durum güncelle ve commit**

```bash
cat > ~/agents/shared/status/football-02-gdextension.md << 'EOF'
# GDExtension Foundation Status
**Status:** done
**Progress:** 100%
**Tamamlanan:**
- godot-cpp derlendi
- GFGameState bridge class (start/stop/step/get_state)
- football_gf.gdextension manifest
- Godot projesi oluşturuldu (Jolt Physics, Forward+)
- Headless test: 5/5 PASSED
**Sonraki faz:** 03-godot-scene
EOF

cd ~/agents/football-godot
git add src/godot/ src/extension/
git commit -m "feat: Godot project init + GDExtension headless test passing"
```
