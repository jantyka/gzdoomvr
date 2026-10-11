# GZDoomVR for Linux

Classic Doom in VR, running natively on Linux with SteamVR.

This is a fork of [GZDoomVR by hh79](https://github.com/hh79/gzdoomvr). Upstream is
developed for Windows and provides Windows builds only. This fork adds what is needed to
build and run it on Linux, a controller setup for Valve Index controllers, and fixes for
crashes found along the way.

- **Building:** [LINUX.md](LINUX.md)
- **Playing, controller layout, mods:** [linux/README.md](linux/README.md)

There are no ready-made builds yet, you build it from source. No game data is included;
you need your own `DOOM.WAD` or `DOOM2.WAD`.

## What it was tested with

Arch Linux, GNOME on Wayland, an AMD Radeon RX 7900 XT with Mesa, SteamVR for Linux and a
**Valve Index with Index controllers**. Details and the list of what was and was not
tested are in [LINUX.md](LINUX.md#tested-system).

Not tested in this fork:

- **Meta Quest and other headsets.** Upstream is developed and tested on the Quest with
  Virtual Desktop on Windows. Nothing in this fork was tried with a Quest.
- **Controllers other than the Index.**
- **Windows.** This fork has not been built or run on Windows. Use the
  [upstream releases](https://github.com/hh79/gzdoomvr/releases) there.

## Controls

With the setup from [linux/README.md](linux/README.md), for a right-handed player:

| | Right controller | Left controller |
|---|---|---|
| Thumbstick | turn | move and strafe |
| Thumbstick click | open the menu | use inventory item |
| Trigger | fire, confirm in menus | alternate fire |
| Grip (squeeze) | jump | crouch |
| B | use, confirm in menus | automap |
| A | back in menus | use inventory item |
| Trackpad up / down | next / previous weapon | |

The weapon follows the right hand. Every assignment can be changed, either in the text
file `linux/index_controller.cfg` or in the game under Options -> Customize Controls.
There is an additional file for Brutal Doom (kick, reload, special action, grenades).

This layout differs from upstream's defaults. Those are still built in and apply when you
do not use the files in `linux/`: the grip of the weapon hand then works as a shift key
for a second set of bindings. They are described in the
[upstream README](https://github.com/hh79/gzdoomvr#default-controls). With Index
controllers they need a matching SteamVR binding as well, because SteamVR's own default
reports the A buttons as grip.

## Mods

Mods are loaded as in GZDoom with `-file`. Tested in this fork:

- [Brutal Doom](https://www.moddb.com/mods/brutal-doom) v21, with Doom and Doom 2
- [br_vr](https://github.com/ajantaju/br_vr/releases), 3D weapon models for Brutal Doom
  v21 by ajantaju
- LTP V7.0.1, liquid textures with real time reflections. It requires GZDoom 4.14 and
  therefore the branch `linux-openvr-4.14`.

Started once without problems, but not looked at closely:

- [HDVRweapons.zip](https://github.com/hh79/gz3doom/files/4378108/HDVRweapons.zip), 3D
  weapon models for the original games by ajantaju

Listed by upstream and not tried here:

- [BD64Weapons](https://github.com/dxt121730/BD64Weapons), weapon pack for Brutal Doom 64
  by dxt121730
- [Virtual Tactical Vest](https://github.com/iAmErmac/Virtual-Tactical-Vest), a virtual
  vest with weapon slots by iAmErmac
- [Doom Neural Upscale 2X](https://www.moddb.com/downloads/doom-neural-upscale-2x),
  texture upscale
- [Laser Sight](https://github.com/mmaulwurff/laser-sight/releases) by mmaulwurff, for
  aiming

None of these are part of this repository.

## Branches

| Branch | Based on |
|---|---|
| `linux-openvr-4.14` | upstream `openvr_controller` with GZDoom 4.14.2. Recommended. |
| `linux-openvr` | the upstream release `gvr4.13.2.2` with GZDoom 4.13.2 |
| `openvr_controller` | unchanged upstream |

## Where this comes from

GZDoomVR is a VR fork of [GZDoom](https://github.com/ZDoom/gzdoom), based on
[gz3doom](http://rotatingpenguin.com/gz3doom/), [OpenVR Doom](https://github.com/Fishbiter/gz3doom)
by Fishbiter and [QuestZDoom](https://github.com/DrBeef/QuestZDoom) by DrBeef, and
maintained by hh79. The Linux work in this fork is a comparatively small addition on top
of theirs.

#
Copyright (c) 1998-2024 ZDoom + GZDoom + GZDoomVR + QuestZDoom teams, and contributors

Doom Source (c) 1997 id Software, Raven Software, and contributors

Please see license files for individual contributor licenses

### Licensed under the GPL v3
##### https://www.gnu.org/licenses/quick-guide-gplv3.en.html
---
