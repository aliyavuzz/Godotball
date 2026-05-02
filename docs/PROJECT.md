# GameplayFootball → Godot 4 Port — Master Proje Dokümanı

**Son güncelleme:** 2 Mayıs 2026  
**Kaynak repo:** https://github.com/vi3itor/GameplayFootball  
**Hedef:** Godot 4.4.1 + GDExtension  

---

## Dizin Yapısı

```
~/agents/
├── football-gf/          ← Kaynak: GameplayFootball C++ (salt okunur)
├── football-godot/       ← Hedef: Godot port projesi
│   ├── docs/
│   │   ├── PROJECT.md    ← Bu dosya
│   │   └── plans/        ← Faz planları
│   ├── src/
│   │   ├── extension/    ← GDExtension C++ kodu
│   │   │   └── godot-cpp/  ← godot-cpp bağımlılığı
│   │   └── godot/        ← Godot proje dosyaları
│   ├── assets/           ← Dönüştürülmüş varlıklar
│   │   ├── models/       ← GLTF oyuncu/stad modelleri
│   │   ├── animations/   ← Godot .tres animasyonları
│   │   ├── textures/     ← PNG/JPG (doğrudan kopyalandı)
│   │   └── sounds/       ← WAV (doğrudan kopyalandı)
│   ├── tools/            ← Dönüşüm scriptleri
│   └── scripts/          ← Otomasyon
└── shared/specs/football-godot/  ← Agent koordinasyon
```

---

## Kaynak Asset Formatları

| Format | Tür | Durum |
|---|---|---|
| `.anim` | ASCII CSV — kemik adı + quaternion keyframe | Direkt parse edilebilir |
| `.object` | XML — skeleton hiyerarşisi, .ase referansları | Direkt parse edilebilir |
| `.ase` | 3DS Max ASCII Scene Export — mesh geometrisi | Blender native import |
| `.png/.jpg` | Dokular | Doğrudan kullanılabilir |
| `.wav` | Sesler | Doğrudan kullanılabilir |
| `.sqlite` | Oyuncu/takım veritabanı | Doğrudan kullanılabilir |

### .anim Formatı (örnek)
```
bone_name,frame,qx,qy,qz,qw,frame,qx,qy,qz,qw,...
<steps>N</steps>
<type>movement</type>
```

### .object Formatı
XML tabanlı skeleton hiyerarşisi. Her node: `name`, `position`, `rotation`, `geometry{filename,name}`.

---

## Araçlar ve Ortam

| Araç | Konum | Versiyon |
|---|---|---|
| Godot 4 | `~/bin/godot4` | 4.4.1 stable |
| godot-cpp | `~/agents/football-godot/src/extension/godot-cpp` | 4.4 branch |
| gcc | sistem | 13.3.0 |
| scons | `~/.local/bin/scons` | pip ile kuruldu |
| cmake | `~/.local/bin/cmake` | 4.3.2 |
| git | sistem | 2.43.0 |

**PATH ekle (her agent session başında):**
```bash
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
```

---

## Mimari Özet

```
GDExtension (C++) — mevcut GF kodu wrap edilir
├── Ball         ← Fizik + tahmin sistemi
├── Match        ← Maç durum makinesi
├── Referee      ← Kural denetimi
├── Player       ← Oyuncu + AI controller
├── TeamAI       ← Takım taktik kontrolcüsü
└── GameState    ← Godot'a signal köprüsü

Godot 4 (GDScript)
├── Main.gd          ← Sahne orkestratörü
├── PlayerNode.gd    ← Karakter animasyon + IK
├── BallNode.gd      ← Top görsel + Jolt fizik
├── StadiumScene     ← Stad sahne
└── UI/              ← Menü + HUD
```

**Renderer:** Forward+  
**Fizik:** Jolt Physics (Project Settings > Physics > 3D)  
**Animasyon:** AnimationTree + AnimationNodeStateMachine + BlendSpace2D  
**IK:** TwoBoneIK3D (Godot 4.6+ foot IK)  
**Kalabalık:** MultiMesh instancing  

---

## Faz Listesi ve Durum

| Faz | Plan Dosyası | Durum | Agent |
|---|---|---|---|
| 00 — Ortam Kurulum | plans/00-environment.md | ✅ Tamamlandı | orchestrator |
| 01 — Asset Pipeline | plans/01-asset-pipeline.md | 🔄 Sıradaki | - |
| 02 — GDExtension Altyapı | plans/02-gdextension-foundation.md | ⏳ Bekliyor | - |
| 03 — Godot Sahne Yapısı | plans/03-godot-scene.md | ⏳ Bekliyor | - |
| 04 — Top Fiziği | plans/04-ball-physics.md | ⏳ Bekliyor | - |
| 05 — Maç + Hakem | plans/05-match-referee.md | ⏳ Bekliyor | - |
| 06 — Oyuncu + AI | plans/06-player-ai.md | ⏳ Bekliyor | - |
| 07 — Animasyon Sistemi | plans/07-animation.md | ⏳ Bekliyor | - |
| 08 — Görsel Kalite | plans/08-visual-polish.md | ⏳ Bekliyor | - |

---

## Agent Notları

- Her agent başında `~/agents/football-godot/docs/PROJECT.md` oku
- Tamamlanan işleri bu dokümandaki tabloya işle
- Detaylı durum: `~/agents/shared/status/football-<faz>.md`
- Bloke olursan: `~/agents/shared/inbox/orchestrator/football-block.md`'a yaz
