# GZDoomVR on Linux

This fork makes GZDoomVR build and run natively on Linux, against the existing OpenVR
interface and SteamVR for Linux. It was developed and tested with a Valve Index.

There are no release builds yet. You build it from source as described below.

- **Playing:** see [linux/README.md](linux/README.md) for the first start, the controller
  layout, how to change it, and mods.
- **Windows:** compiles in CI, not runtime-tested. See [Windows](#windows).

## Branches

| Branch | Based on | Notes |
|---|---|---|
| `linux-openvr-4.14` | upstream `openvr_controller` (GZDoom 4.14.2) | Recommended. Needed for mods that require GZDoom 4.14. |
| `linux-openvr` | release `gvr4.13.2.2` (GZDoom 4.13.2) | Same Linux changes on the last release. |

The executable still reports `gvr4.13.2.2-…` on both branches, because that is the last
upstream tag.

## What you need

- A 64-bit Linux with a working SteamVR for Linux installation and a headset SteamVR
  supports.
- SteamVR 2.17.10 or newer is recommended. Valve lists fixes for two AMD crashes on Linux
  in that version.
- A GPU with a working OpenGL driver. The VR renderer only exists for the OpenGL backend
  (`vid_preferbackend 0`), not for Vulkan.
- The game data (`DOOM.WAD`, `DOOM2.WAD`, ...). No game data is included.

### Packages (Arch Linux)

```
sudo pacman -S --needed base-devel git cmake ninja pkgconf sdl2-compat openal \
    libjpeg-turbo libvpx bzip2 gtk3 zlib libwebp
```

`sdl2-compat` provides SDL2. On other distributions install the matching development
packages for SDL2, OpenAL, libjpeg, libvpx, bzip2, GTK 3, zlib and libwebp. Only Arch has
been tested.

### ZMusic

GZDoom needs the ZMusic library with its headers. Arch has no package for it in the
official repositories, so build it into a local directory:

```
git clone https://github.com/ZDoom/ZMusic
cd ZMusic
git checkout 1.3.0
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/zmusic"
cmake --build build
cmake --install build
```

### OpenVR SDK

The repository contains no OpenVR headers. Clone the SDK to `~/openvr`, where the build
looks for it (or point `OPENVR_DIR` to it):

```
git clone https://github.com/ValveSoftware/openvr ~/openvr
```

Tested with SDK 2.15.6.

## Building

```
git clone https://github.com/jantyka/gzdoomvr
cd gzdoomvr
git checkout linux-openvr-4.14

OPENVR_DIR=~/openvr cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DZMUSIC_INCLUDE_DIR="$HOME/zmusic/include" \
    -DZMUSIC_LIBRARIES="$HOME/zmusic/lib/libzmusic.so"
cmake --build build

cp -a "$HOME"/zmusic/lib/libzmusic.so.1* build/
```

The result is `build/gzdoomvr`. `libopenvr_api.so` is copied next to it by the build.
The last line is needed because the executable only looks for its libraries in its own
directory; without it the start fails with `libzmusic.so.1: cannot open shared object
file`.

Nothing is installed system-wide and you do not need `make install`. A regular GZDoom
installation is not touched: GZDoomVR keeps its configuration and savegames in
`~/.config/gzdoomvr/`.

If the build fails with `libvpx.so.X not found` after a system update, rebuild.

## Running

Start SteamVR from Steam first, with the headset on. Then:

```
./build/gzdoomvr -iwad /path/to/DOOM2.WAD
```

Continue with [linux/README.md](linux/README.md) for the controller setup.

Things to know:

- **Every start contacts SteamVR.** If a headset is attached, GZDoomVR starts SteamVR
  even when `vr_mode` is not set to OpenVR. This is how upstream behaves. Starting SteamVR
  this way instead of from Steam made its status window (`vrmonitor`) crash on the test
  system, so start SteamVR from Steam first.
- **`vr_mode` must be 10** (OpenVR) for the image to appear in the headset. That is the
  default. If the game only shows on the monitor, type `vr_mode 10` in the console.
- **Audio.** SteamVR does not make the headset the default audio device on Linux. Select
  it in your desktop's sound settings.

## SteamVR on Linux

These points are about SteamVR itself, not about this port. They were needed or checked
on the test system.

- `vrcompositor-launcher` needs `CAP_SYS_NICE`. SteamVR asks for it; after SteamVR updates
  it may have to be set again:

  ```
  sudo setcap CAP_SYS_NICE=eip ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
  ```

- **Two GPUs.** On a system with an integrated and a dedicated AMD GPU, the compositor
  could not start under GNOME until the integrated GPU was detached from the `amdgpu`
  driver before the display manager starts (or disabled in the firmware setup).
- The Vulkan layer `steamvr-linux-fixes-layer` was installed on the test system.
- Wayland works if the compositor supports DRM leasing. GNOME (Mutter) does.

## What was changed for Linux

Fixes that were needed to build and run at all:

- **OpenVR joystick device.** `gl_openvr.cpp` calls `I_StartupOpenVR()` and
  `I_OpenVRGetYaw()`, which only existed in the Windows sources. The file moved from
  `src/win32/` to `src/i_openVR.cpp` and is hooked into the SDL joystick code. The Windows
  path is unchanged.
- **Controller state layout.** `openvr_capi.h` defines `VRControllerState_t` without the
  4-byte packing that `openvr.h` applies on Linux and macOS. Buttons and axes were read
  from the wrong offsets and the controllers did nothing. See `src/openvr_include.h`.
- **Index thumbstick.** Index controllers report their axes as trackpad, trigger, trigger.
  There is no axis of type joystick, so menu navigation never saw the stick.
- **Build.** The Linux executable is called `gzdoomvr`, `libopenvr_api.so` is copied next
  to it, and ARM64 Linux uses the `linuxarm64` directory of the SDK.

Crash fixes in shared code. They are not Linux specific and are active on all platforms:

- Division by zero in the dynamic light buffer when the driver reports a uniform buffer
  offset alignment below 16 bytes. Mesa (radeonsi) reports 4. It crashed as soon as a
  dynamic light was drawn, for example right after starting a map in Brutal Doom.
- Crash on every exit once a controller model had been loaded: the models were freed after
  the OpenGL context was gone.
- Crash in VR when the player has no body for some frames, for example after loading a
  savegame that does not match the loaded mods.

Input additions. They are only active in the Linux build, because they could not be
tested on Windows:

- The weapon hand trigger confirms in menus.
- Thumbstick directions arrive as the keys `LStick*`/`RStick*` and can be bound.
- The weapon hand system button arrives as `Pad_Start`.
- The upper and lower half of the Index trackpad arrive as `DPadUp`/`DPadDown` (Index
  controllers only).

Other:

- `openvr_desktop_view`: `0` shows both eyes side by side on the desktop window as before,
  `1` shows the left eye only, filling the window. There is no menu entry for it yet, set
  it in the console.
- `linux/`: a SteamVR legacy binding for Index controllers and editable key binding
  scripts. See [linux/README.md](linux/README.md).

## Tested system

| | |
|---|---|
| Distribution | Arch Linux, kernel 7.2.9 |
| Desktop | GNOME 51 on Wayland |
| GPU | AMD Radeon RX 7900 XT, Mesa 26.2.4 (radeonsi / RADV) |
| CPU | AMD Ryzen 7 9800X3D |
| Headset | Valve Index with Index controllers, 90 Hz |
| SteamVR | 2.16.7 for most tests, 2.17.10 for a short final run |
| Compiler | GCC 16.2.1, CMake 4.4.4 |

What was tested, October 2026:

| Test | Result |
|---|---|
| Doom 2 without VR: menu, new game, sound, save, load | works |
| Own configuration directory, regular GZDoom untouched | works |
| Image in the headset, head tracking, hand tracking, sound | works |
| Index controllers: move, turn, shoot, use, jump, crouch, weapon change, menus | works |
| Brutal Doom v21 with Doom and Doom 2 | works |
| Brutal Doom v21 with the `br_vr` 3D weapons | works |
| LTP V7.0.1 liquid textures with real time reflections (`linux-openvr-4.14` only) | works |
| Loading a savegame from another mod combination | error message, no crash |
| Exit | no crash |

Not tested yet:

- Frame timing measured over longer runs, and refresh rates above 90 Hz. In the test runs
  SteamVR reported no reprojected frames at 90 Hz, but those runs were between one and
  ten minutes long and are not a benchmark.
- Snap turning, left-handed setup, haptics.
- Controllers other than the Index.
- Any distribution other than Arch Linux.

## Known issues

- SteamVR 2.16.7 crashed three times on the test system (`vrcompositor`, once at start,
  once while idle, once at shutdown), each time without GZDoomVR being the cause as far as
  the logs show. Whether 2.17.10 fixes this is not known yet.
- The weapon hand system button is reserved by SteamVR for its dashboard and may not reach
  the game.
- Without the FluidR3 soundfonts the log shows `Could not find patch set` and music falls
  back to the system MIDI device.
- GNOME logs `Client provided invalid window geometry` when the window is created. No
  visible effect was noticed.
- `AppImageBuilder.yml` is the unchanged upstream GZDoom template and does not produce a
  working GZDoomVR AppImage.

## Windows

**Compiles in CI, not runtime-tested.** The workflow `.github/workflows/build.yml` builds
this fork with Visual Studio 2022 on every push, next to the Linux build. That shows the
Windows build still compiles and links. It has never been started: nobody has run a
Windows build of this fork, with or without a headset.

The Linux changes are separated with `#ifdef` or a build-time flag so that the Windows
behavior should stay as it is, with one exception: the three crash fixes listed above
are active on all platforms. This fork publishes no Windows builds. Use the upstream
releases on Windows: https://github.com/hh79/gzdoomvr/releases

## License

Unchanged from upstream, see `LICENSE` and `docs/licenses/`.
