# Playing GZDoomVR on Linux with Index controllers

This guide starts where [LINUX.md](../LINUX.md) ends: you have built `build/gzdoomvr`.
It covers the first start, the controller layout and how to change it, and mods.

Files in this directory:

| File | What it does |
|---|---|
| `steamvr_bindings/index_legacy.json` | Tells SteamVR which physical button reaches the game as which key. |
| `steamvr_bindings/select_binding.sh` | Selects that binding in a running SteamVR. |
| `index_controller.cfg` | Assigns game actions to those keys. Edit this one to change the layout. |
| `index_controller_brutaldoom.cfg` | Additional assignments for Brutal Doom. |
| `index_controller_brutaldoom64.cfg` | Additional assignments for Brutal Doom 64. |
| `get-tested-mods.sh` | Fetches the weapon packs and checks the other tested mods, see [below](#3d-weapons-and-other-mods). |

## First start

1. Start SteamVR from Steam and switch on headset and controllers.
2. Start the game once, so that SteamVR gets to know it, and quit it again:

   ```
   ./build/gzdoomvr -iwad /path/to/DOOM2.WAD
   ```

3. Select the Index binding while SteamVR is still running:

   ```
   linux/steamvr_bindings/select_binding.sh
   ```

   SteamVR remembers the choice together with the path of the file. Run the script again
   if you move the repository. It refuses paths with spaces or special characters; in
   that case load `index_legacy.json` by hand in SteamVR under Settings -> Controllers ->
   Manage Controller Bindings.

4. Start the game with the key bindings:

   ```
   ./build/gzdoomvr -iwad /path/to/DOOM2.WAD +exec "$PWD/linux/index_controller.cfg"
   ```

   The bindings are saved to `~/.config/gzdoomvr/gzdoomvr.ini`. You only need `+exec`
   again after you changed the file. The path must be a full path.

Why the binding is needed: SteamVR's own default for old ("legacy") games reports the A
buttons of the Index as grip, so the game can never tell them apart, and it reports a
thumbstick pushed to the edge as a click.

## Controls

This is the layout from `index_controller.cfg`, for a right-handed setup.

**Right controller**

| Input | In the game | In menus |
|---|---|---|
| Trigger | fire | confirm |
| Thumbstick left/right | turn | navigate |
| Thumbstick click, short | not assigned | |
| Thumbstick click, held | weapon wheel | |
| Trackpad, upper half (press) | next weapon | |
| Trackpad, lower half (press) | previous weapon | |
| B | use | confirm |
| A | not assigned | back |
| Grip (squeeze, from half force) | jump | |

**Left controller**

| Input | In the game | In menus |
|---|---|---|
| Thumbstick | move and strafe | navigate |
| Trigger | alternate fire | |
| Grip (squeeze, from half force) | crouch while held | |
| Thumbstick click, short | switch always-run on and off | |
| Thumbstick click, held | item wheel | |
| A | open the menu | |
| B | automap | |
| Trackpad | not assigned | |

The weapon follows the right hand.

**Weapon and item wheels.** Hold the thumbstick click of the right hand: a wheel with one
segment per weapon slot appears above the weapon. Point the stick at a segment and let go
to switch; let go with the stick in the middle to cancel. If a slot holds several weapons,
the trigger cycles through them while the wheel is open. The left thumbstick click opens
the same kind of wheel for inventory items (Heretic's artifacts, items from mods) and uses
the chosen one. A short click does what it did before. Turning (right) and moving (left)
pause while a wheel is open. Settings, including an off switch for mods with a wheel of
their own: Options -> OpenVR Options -> VR Wheels.

How long "held" takes is `vr_wheel_hold_ms` (250). Size, height above the hand and
opacity are `vr_wheel_size`, `vr_wheel_height` (meters) and `vr_wheel_alpha`;
`vr_wheel_freeze true` stops time while a wheel is open (single player only),
`vr_wheel_use_item false` only selects the item instead of using it. On the desktop the
wheels open with keys bound to `+vr_weaponwheel` and `+vr_itemwheel`, the mouse points.

## Changing the layout

There are two layers, and most changes only need the first.

**1. Which action is on which key.** Edit `index_controller.cfg` and load it again with
`+exec`, or use Options -> Customize Controls in the game. The file lists the key names;
these are the ones the binding above produces:

| Key name | Right hand | Key name | Left hand |
|---|---|---|---|
| `RTrigger` | trigger | `LTrigger` | trigger |
| `Pad_A` | B button | `Pad_X` | A button |
| `Pad_B` | A button | `Pad_Y` | B button |
| `RShoulder` | grip | `LShoulder` | grip |
| `RThumb` | thumbstick click | `LThumb` | thumbstick click |
| `DPadUp` / `DPadDown` | trackpad upper / lower half | `DPadLeft` / `DPadRight` | trackpad upper / lower half |
| `RStickLeft`, `RStickRight`, `RStickUp`, `RStickDown` | thumbstick pushed to the edge | `LStickLeft`, ... | thumbstick pushed to the edge |
| `Pad_Start` | system button, if SteamVR passes it on | | |

A line looks like `wait 2; bind RShoulder +jump`. To free a key, use
`wait 2; unbind RShoulder`. The `wait 2;` in front is needed: without it the game replaces
bindings from the script with what `gzdoomvr.ini` holds for the key sections of a loaded
mod. In the console or the options menu you do not need it.

Two things are fixed in the game and cannot be rebound: in menus `Pad_A` and the weapon
hand trigger confirm and `Pad_B` goes back. That is why the binding sends the physical B
button as `Pad_A`.

**2. What the thumbsticks do as axes** (move, strafe, turn, dead zone, sensitivity).
This cannot be set from a script. Use Options -> Controller Options -> OpenVR in the
game. For Index controllers the entries named "Joystick" are the thumbsticks; the "Pad"
entries have no effect. If you bind `RStickUp`/`RStickDown` to actions, set the vertical
axis of the right stick to "None" there, otherwise it also moves you up and down while
swimming or flying.

**The grip as a shift key.** With `vr_alternate_mappings true` the weapon hand grip no
longer sends `RShoulder`. Holding it switches the other buttons to a second set of keys
(`Pad_A_Alt`, `RTrigger_Alt`, ...) and makes the thumbsticks send the mouse wheel and
d-pad keys. That is the upstream default; `index_controller.cfg` turns it off so the grip
can be a button of its own.

**Which physical button is which key.** Only if the table above does not suit you: edit
the binding in SteamVR's binding editor, or change `index_legacy.json`. With SteamVR
running, the editor is also reachable in a browser at
`http://127.0.0.1:27062/dashboard/controllerbinding.html`.

## Brutal Doom

Tested with Brutal Doom v21. Load the additional bindings after the regular ones. The
Brutal Doom file only changes a few keys and expects the rest to be set already:

```
./build/gzdoomvr -iwad /path/to/DOOM2.WAD -file /path/to/brutalv21.pk3 \
    +exec "$PWD/linux/index_controller.cfg" \
    +exec "$PWD/linux/index_controller_brutaldoom.cfg"
```

| Input | Action |
|---|---|
| Right thumbstick forward | kick |
| Right thumbstick back | reload |
| Right A | throw grenade |
| Left trigger | dual wield / special action (replaces alternate fire) |
| Left trackpad (press) | offend |

These commands only exist while Brutal Doom is loaded. To get the plain layout back, load
`index_controller.cfg` again.

## 3D weapons and other mods

Mods are loaded as in GZDoom, in the order given after `-file`. File names are case
sensitive on Linux.

`linux/get-tested-mods.sh [directory]` collects the mods this fork was tested with. It
downloads the two weapon packs from GitHub and checks them against known checksums.
Brutal Doom and the Liquid Texture Pack are on ModDB, which does not allow scripted
downloads: the script tells you where to get them and checks the files once they are in
the directory. At the end it prints the tested load order.

- **3D weapon models.** Without a weapon pack the weapons are flat sprites. The packs
  linked in the main README work: `HDVRweapons.zip` for the original games and
  [br_vr](https://github.com/ajantaju/br_vr/releases) for Brutal Doom v21 (use the `pbr`
  file, the `Quest` file is for the Quest port). Load the pack after the game mod:

  ```
  ./build/gzdoomvr -iwad /path/to/DOOM2.WAD -file /path/to/brutalv21.pk3 /path/to/BR_VR_pbr_RC2.zip
  ```

  If the weapon points too far up or down in your hand, change `openvr_weaponRotate`
  (default -40) in the console. The `br_vr` README suggests -56 for the Vive.

- **Mods that need a newer engine.** A mod made for GZDoom 4.14 stops the frozen
  4.13 variant (tag `linux-openvr-4.13-final`) with "requires a newer version of
  GZDoomVR". Use the branch `linux-openvr-4.14` for those.

- **Savegames** belong to the mod combination they were saved with. Loading one with
  other mods fails with a message such as "Level was saved with a different number of ACS
  modules".

The weapon packs are not part of this repository. They come with their own credits and
without a stated license.

## The desktop window

By default the window on the monitor shows both eyes side by side. `openvr_desktop_view 1`
shows the left eye only, filling the window. On a wide monitor the image is cropped at
the top and bottom. `index_controller.cfg` sets it to 1.

## If something does not work

- **The game is only on the monitor, not in the headset.** Open the console and type
  `vr_mode 10`. Make sure SteamVR was running before you started the game.
- **Buttons and sticks do nothing, or A and grip do the same.** The binding is not
  selected. Run `select_binding.sh` again and look at its output.
- **A menu entry cannot be confirmed with A.** That is intended in this layout: B and the
  trigger confirm, A goes back.
- **A fully pushed stick crouches or uses an item.** SteamVR's default binding is active,
  see above.
- **The start fails with `libzmusic.so.1`.** Copy the ZMusic library next to the
  executable, see [LINUX.md](../LINUX.md).
- **The game crashes.** It writes `gzdoomvr-crash.log` into the directory you started it
  from. SteamVR's own logs are in `~/.local/share/Steam/logs/` (`vrserver.txt`,
  `vrcompositor.txt`, `vrclient_gzdoomvr.txt`).

**Still stuck, or found a bug?** Please
[open an issue](https://github.com/jantyka/gzdoomvr/issues). Look through the existing
ones first, and check the known issues in [LINUX.md](../LINUX.md#known-issues). A report
is most useful with:

- headset and controllers, distribution, GPU and driver version, SteamVR version,
- the branch or build you used and the command line you started the game with,
- what you did, what you expected, and what happened instead,
- `gzdoomvr-crash.log` if the game crashed, and for controller problems the lines
  containing `gzdoomvr` from `vrserver.txt`.

Problems of the Windows builds, or of the game on other platforms, belong to
[upstream](https://github.com/hh79/gzdoomvr/issues).
