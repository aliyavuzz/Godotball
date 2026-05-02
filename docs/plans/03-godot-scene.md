# Godot Sahne Yapısı — Plan (Faz 3)

**Goal:** Stad + 22 oyuncu node + top içeren temel 3D Godot sahnesini oluşturmak.
**Bağımlılık:** Faz 01 (assets), Faz 02 (GDExtension) tamamlanmış olmalı.

## Kapsam
- StadiumScene.tscn: Saha, gol direkleri, ışıklar, kamera
- PlayerNode.tscn: Karakter + AnimationTree placeholder
- BallNode.tscn: RigidBody3D + mesh
- Main.gd: GFGameState'i bağla, her _physics_process'te step() çağır
- SDFGI aktif, Jolt Physics aktif
- Headless screenshot test

## Dosyalar
- src/godot/scenes/StadiumScene.tscn
- src/godot/scenes/PlayerNode.tscn
- src/godot/scenes/BallNode.tscn
- src/godot/scripts/Main.gd
- src/godot/scripts/PlayerNode.gd
- src/godot/scripts/BallNode.gd

**Detaylı adımlar Faz 2 tamamlandıktan sonra yazılacak.**
