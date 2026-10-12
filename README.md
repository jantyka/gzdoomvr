# GZDoomVR for Linux

Play classic Doom in VR on Linux: a native Linux build of GZDoomVR for SteamVR (OpenVR),
with a ready-made setup for Valve Index controllers. It runs without Proton or Wine.

This is a fork of [GZDoomVR by hh79](https://github.com/hh79/gzdoomvr). Upstream is
developed for Windows and provides Windows builds only. This fork adds what is needed to
build and run it on Linux, a controller setup for Valve Index controllers, and fixes for
crashes found along the way.

- Doom and Doom 2 in the headset, with the weapon in your hand and thumbstick movement
- Brutal Doom v21 with 3D weapon models, see [Mods](#mods)
- a SteamVR binding and key layout for Index controllers that you can edit, see
  [Controls](#controls)

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
- **Windows.** The Windows build of this fork compiles in CI, but it has never been run.
  Use the [upstream releases](https://github.com/hh79/gzdoomvr/releases) there.

## Controls

With the setup from [linux/README.md](linux/README.md), for a right-handed player. The
weapon follows the right hand.

**Right controller**

| Input | In the game | With Brutal Doom | In menus |
|---|---|---|---|
| Trigger | fire | fire | confirm |
| Thumbstick left / right | turn | turn | navigate |
| Thumbstick forward / back | | kick / reload | navigate |
| Thumbstick click | | throw grenade | |
| Trackpad, upper / lower half (press) | next / previous weapon | next / previous weapon | |
| B | use | use | confirm |
| A | | | back |
| Grip (squeeze, from half force) | jump | jump | |

**Left controller**

| Input | In the game | With Brutal Doom | In menus |
|---|---|---|---|
| Thumbstick | move and strafe | move and strafe | navigate |
| Thumbstick click | switch always-run on and off | switch always-run on and off | |
| Trigger | alternate fire | dual wield / special action | |
| Trackpad (press) | | offend | |
| A | open the menu | open the menu | |
| B | automap | automap | |
| Grip (squeeze, from half force) | crouch while held | crouch while held | |

Empty cells are not assigned. Using an inventory item has no button in this layout, and
with Brutal Doom neither has alternate fire.

Every assignment can be changed:

- `linux/index_controller.cfg` holds the regular layout,
  `linux/index_controller_brutaldoom.cfg` the Brutal Doom additions. Both are commented
  text files with one line per key.
- `linux/steamvr_bindings/index_legacy.json` decides how SteamVR reports the physical
  buttons, for example that the grips click at half force.
- Or use Options -> Customize Controls in the game.

[linux/README.md](linux/README.md) explains the files and the key names.

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
- LTP V7.0.1, liquid textures with real time reflections. It requires GZDoom 4.14.

Started once without problems, but not looked at closely:

- [HDVRweapons.zip](https://github.com/hh79/gz3doom/files/4378108/HDVRweapons.zip), 3D
  weapon models for the original games by ajantaju

- [Brutal Doom 64](https://www.moddb.com/mods/brutal-doom-64) v2 with its maps
  (`bd64mapsV2.pk3`) and [BD64Weapons](https://github.com/dxt121730/BD64Weapons), the 3D
  weapon pack by dxt121730. Played on the intro map only. BD64Weapons logs non-fatal
  script errors in five of its model definitions.

- [Voxel Doom II](https://www.moddb.com/mods/voxel-doom-ii) v2.4 by Cheello, a voxel
  model pack. Played for a minute on MAP01 of Doom 2, without other mods; the individual
  models were not checked. Version 2.4 is the addon
  ["Voxel Doom II with Parallax Textures"](https://www.moddb.com/mods/voxel-doom-ii/addons/voxel-doom-ii-with-parallax-textures),
  file `VoxelDoom_v2.4.pk3`. The "Doom 2: Ray Traced" download under "Files" on the same
  page is not this mod: it is a separate Windows program with its own renderer, and its
  data files fail to load in GZDoomVR with script errors.

Listed by upstream and not tried here:

- [Virtual Tactical Vest](https://github.com/iAmErmac/Virtual-Tactical-Vest), a virtual
  vest with weapon slots by iAmErmac
- [Doom Neural Upscale 2X](https://www.moddb.com/downloads/doom-neural-upscale-2x),
  texture upscale
- [Laser Sight](https://github.com/mmaulwurff/laser-sight/releases) by mmaulwurff, for
  aiming

None of these are part of this repository. `linux/get-tested-mods.sh` fetches the weapon
packs and tells you where to get the others.

## Branches

| Branch or tag | Based on |
|---|---|
| branch `linux-openvr-4.14` | upstream `openvr_controller` with GZDoom 4.14.2. The Linux port. |
| tag `linux-openvr-4.13-final` | the upstream release `gvr4.13.2.2` with GZDoom 4.13.2. Frozen, no longer developed. |
| branch `openvr_controller` | unchanged upstream |

## Where this comes from

GZDoomVR is a VR fork of [GZDoom](https://github.com/ZDoom/gzdoom), based on
[gz3doom](https://github.com/cmbruns/gz3doom) by Christopher Bruns
([project page](http://rotatingpenguin.com/gz3doom/)), [OpenVR Doom](https://github.com/Fishbiter/gz3doom)
by Fishbiter and [QuestZDoom](https://github.com/DrBeef/QuestZDoom) by DrBeef, and
maintained by hh79. The Linux work in this fork is a comparatively small addition on top
of theirs.

## Testers wanted

This fork has been run on exactly one machine with one headset. If you try it, a short
report helps a lot, whether it worked or not:
[open an issue](https://github.com/jantyka/gzdoomvr/issues).

Especially welcome:

- **Steam Frame.** Nobody has tried this fork with a Steam Frame. It should show up as
  just another SteamVR headset, but its controllers have no trackpad, and some input code
  and the SteamVR binding in `linux/` are specific to Index controllers. Expect to need
  your own key assignments; what you find out would let this fork ship a binding for it.
- **Other headsets and controllers** on Linux: Quest via a streaming app, Vive, Reverb
  and so on.
- **Other distributions and GPUs**, in particular NVIDIA and Intel. Everything so far was
  AMD on Arch Linux.
- **Monado / Envision** with an OpenVR translation layer instead of SteamVR.

Useful in a report: headset and controllers, distribution, GPU and driver version,
SteamVR version, the branch or build you used, what works and what does not. If the game
crashed, attach `gzdoomvr-crash.log` from the directory you started it in. For controller
problems, the lines containing `gzdoomvr` from `~/.local/share/Steam/logs/vrserver.txt`
show which binding SteamVR loaded.

## Questions people ask

- **Does GZDoomVR run on Linux?** Upstream only ships Windows builds. This fork builds
  and runs natively on Linux; [LINUX.md](LINUX.md) has the steps.
- **Do I need Proton or Wine?** No. The game is a native Linux program and talks to
  SteamVR for Linux directly.
- **Does it need SteamVR?** Yes. The game uses OpenVR, not OpenXR. Monado with an OpenVR
  translation layer might work, but has not been tried.
- **Which headsets work?** Only the Valve Index was tested. See
  [Testers wanted](#testers-wanted) for everything else.
- **Vulkan or OpenGL?** The VR renderer only exists for OpenGL.
- **Is there a package or a download?** Not yet. There is no release and no AUR package;
  you build from source, or take the AppImage from a workflow run (not yet tried in a
  headset) as described
  in [LINUX.md](LINUX.md#appimage).

#
Copyright (c) 1998-2024 ZDoom + GZDoom + GZDoomVR + QuestZDoom teams, and contributors

Doom Source (c) 1997 id Software, Raven Software, and contributors

Please see license files for individual contributor licenses

### Licensed under the GPL v3
##### https://www.gnu.org/licenses/quick-guide-gplv3.en.html
---
