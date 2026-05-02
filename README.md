# GameplayFootball → Godot 4 Port (v1.0)

This project is a modern port of the open-source **GameplayFootball** engine to **Godot 4.4**, utilizing **GDExtension (C++)** for core game logic and physics.

## 🚀 Features (v1)

- **Custom Ball Physics:** Ported original C++ physics including air resistance, gravity, bounce, and ground friction.
- **GDExtension Core:** High-performance match logic, referee, and player systems implemented in C++.
- **Match & Referee System:** Goal detection, out-of-bounds tracking, and score management.
- **Simple Team AI:** 22 players with basic "chase the ball" behavior and tactical positioning infrastructure.
- **Visual Polish:** SDFGI, Volumetric Fog, and high-quality pitch textures.
- **Modular Architecture:** Easy to extend GDScript for visuals and C++ for simulation.

## 🛠 Tech Stack

- **Engine:** Godot 4.4.1 (Stable)
- **Language:** C++17 (GDExtension), GDScript
- **Physics:** Jolt Physics 3D (for collision detection) + Custom GF Physics
- **Build Tool:** SCons

## 📋 Installation

1. **Prerequisites:**
   - Godot 4.4.1
   - SCons (for building GDExtension)
   - C++ Compiler (gcc/clang)

2. **Clone and Build:**
   ```bash
   git clone <repo-url>
   cd football-godot/src/extension
   scons platform=linux target=template_debug -j4
   ```

3. **Open Project:**
   - Launch Godot 4.4 and import the project located in `src/godot/`.
   - The GDExtension library will load automatically from `src/godot/bin/`.

## 🎮 Gameplay & Development

- **Run Scene:** Open `src/godot/scenes/StadiumScene.tscn` and press F6.
- **AI Logic:** Players are controlled by `GFTeam` and `GFPlayer` classes.
- **Customization:** Modify `Main.gd` to tweak game rules or AI behaviors.

## 📂 Project Structure

- `src/extension/`: C++ Source code for GDExtension.
- `src/godot/`: Godot project files (scenes, scripts, assets).
- `assets/`: Converted animations, textures, and models.
- `docs/`: Phase plans and technical documentation.

## 📜 License

This project is based on [GameplayFootball](https://github.com/vi3itor/GameplayFootball). Licensed under Apache License 2.0.

---
*Created by Gemini CLI Orchestrator*
