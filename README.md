## Godot Gameplay Lab

A modular prototyping environment for designing and iterating on core gameplay systems in Godot.

This project focuses on building high-quality, reusable gameplay foundations that can later be ported to Unreal Engine.

---

### Goals

- Rapid iteration on gameplay feel (movement, camera, combat)
- Clean, scalable architecture (feature-based, modular systems)
- Separation of concerns (input, movement, camera, visuals)
- Strong “game feel” out of the box (juicy controls, responsive feedback)
- Easy experimentation without long compile times or heavy engine overhead

---

### Current Features

- Third-person character controller
- Modular camera system
  - Mouse + gamepad input separation
  - Weighted / inertia-based camera movement
- Physics-based movement system
  - Sprinting
  - Double jump
  - Air control tuning
- Visual feedback system
  - squash & stretch
  - landing impact response
- Procedural greybox environment
  - grid shader
  - lighting rig for fast readability

---

### Architecture

```text
features/
  camera/
  character/
  movement/
  visual/

systems/
  utilities/

levels/
  prototypes/
  kits/
```
