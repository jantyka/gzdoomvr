/*
** vr_wheel.zs
** Weapon wheel (weapon hand) and item wheel (off hand) for VR.
**
**---------------------------------------------------------------------------
** Copyright 2026 jantyka
** All rights reserved.
**
** This program is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see http://www.gnu.org/licenses/
**---------------------------------------------------------------------------
**
** The engine (src/vr_wheel.cpp) decides when a wheel is open and where its stick points.
** This file fills the wheels from what the player carries, draws them and sends the choice
** as a network event, so it works the same in multiplayer.
**
** How weapons are found (weapon slots of the player), which icon is used and how the choice
** is sent follows Gearbox by Alexander Kromm (m8f), https://github.com/mmaulwurff/gearbox
** (GPLv3). No code was copied; the class names differ, so Gearbox can still be loaded as a mod.
*/

struct VRWheel native
{
	enum EWheel
	{
		Weapon,
		Item,
		NumWheels
	}

	enum EPoll
	{
		Closed,
		Open,
		Released	// reported once, then the wheel is closed
	}

	native ui static int Poll(int wheel);
	// Stick position, -1..1 per axis, y up. After the release the position at release.
	native ui static Vector2 GetStick(int wheel);
	// Opened by +vr_weaponwheel/+vr_itemwheel: the direction then comes from the mouse.
	native ui static bool FromCommand(int wheel);
	// In VR, what is drawn in between appears at the hand of the wheel.
	native ui static void BeginHandDraw(int wheel);
	native ui static void EndHandDraw();
}

// One segment of a wheel. Weapon segments hold every weapon of one slot, item segments one item.
class VRWheelEntry ui
{
	Array<Inventory> Choices;
	int Choice;
	int Slot;	// weapon slot, -1 for items

	Inventory Current()
	{
		return Choices[Choice];
	}
}

class VRWheelState ui
{
	Array<VRWheelEntry> Entries;
	int Hover;
	bool WasOpen;
	Vector2 Mouse;
	// Weapon chosen per slot with the trigger while the wheel is open, -1 = not chosen yet.
	int SlotChoice[10];
}

class VRWheelHandler : StaticEventHandler
{
	// Below this stick deflection nothing is selected; releasing there cancels.
	const DEADZONE = 0.5;
	// Mouse travel that counts as a fully deflected stick, for +vr_weaponwheel/+vr_itemwheel.
	const MOUSE_RANGE = 200.;
	// Wheel radius as part of the screen height. The VR hand projection in gl_openvr.cpp
	// assumes this value (VRWHEEL_SCREEN_RADIUS).
	const SCREEN_RADIUS = 0.4;
	const INNER_RADIUS = 0.38;	// hole in the middle, part of the radius
	const ARC_STEPS = 64;		// corners of a full circle
	const GAP = 1.5;			// degrees between segments

	ui VRWheelState mWheels[VRWheel.NumWheels];
	ui bool mFrozen;

	//==========================================================================
	//
	// Input
	//
	//==========================================================================

	override void RenderOverlay(RenderEvent e)
	{
		for (int wheel = 0; wheel < VRWheel.NumWheels; wheel++)
		{
			UpdateWheel(wheel);
		}
	}

	override bool InputProcess(InputEvent e)
	{
		if (e.Type == InputEvent.Type_Mouse)
		{
			bool used = false;
			for (int wheel = 0; wheel < VRWheel.NumWheels; wheel++)
			{
				let st = mWheels[wheel];
				if (st && st.WasOpen && VRWheel.FromCommand(wheel))
				{
					st.Mouse += (e.MouseX, e.MouseY);
					if (st.Mouse.Length() > MOUSE_RANGE) st.Mouse = st.Mouse.Unit() * MOUSE_RANGE;
					used = true;
				}
			}
			// Keeps the view from turning while the mouse points at the wheel.
			return used;
		}

		// The fire key switches between the weapons of the slot under the stick. Fire is swallowed,
		// so the open wheel never shoots.
		let st = mWheels[VRWheel.Weapon];
		if (e.Type == InputEvent.Type_KeyDown && st && st.WasOpen && IsKeyFor(e.KeyScan, "+attack"))
		{
			if (st.Hover >= 0)
			{
				let entry = st.Entries[st.Hover];
				entry.Choice = (entry.Choice + 1) % entry.Choices.Size();
				st.SlotChoice[entry.Slot] = entry.Choice;
			}
			return true;
		}
		return false;
	}

	private ui static bool IsKeyFor(int key, String command)
	{
		Array<int> keys;
		Bindings.GetAllKeysForCommand(keys, command);
		return keys.Find(key) != keys.Size();
	}

	private ui void UpdateWheel(int wheel)
	{
		if (mWheels[wheel] == null)
		{
			mWheels[wheel] = new("VRWheelState");
		}
		let st = mWheels[wheel];

		int poll = VRWheel.Poll(wheel);
		let mo = players[consoleplayer].mo;
		if (poll == VRWheel.Closed || mo == null || mo.health <= 0)
		{
			// Also when the engine closed the wheel for a menu or the console: nothing is chosen.
			if (st.WasOpen) Close(st);
			return;
		}

		if (!st.WasOpen) Open(st);
		Fill(st, wheel);
		Vector2 dir = VRWheel.FromCommand(wheel) ? st.Mouse / MOUSE_RANGE : VRWheel.GetStick(wheel);
		st.Hover = FindEntry(st.Entries.Size(), dir);

		if (poll == VRWheel.Released)
		{
			// Thaw first: a frozen player cannot use items.
			Close(st);
			if (st.Hover >= 0) SendChoice(wheel, st.Entries[st.Hover].Current());
			return;
		}
		VRWheel.BeginHandDraw(wheel);
		Draw(st, wheel);
		VRWheel.EndHandDraw();
	}

	private ui void Open(VRWheelState st)
	{
		st.WasOpen = true;
		st.Mouse = (0, 0);
		for (int i = 0; i < 10; i++) st.SlotChoice[i] = -1;
		UpdateFreeze();
	}

	private ui void Close(VRWheelState st)
	{
		st.WasOpen = false;
		UpdateFreeze();
	}

	// Time stays frozen while any wheel is open, so closing one of two does not thaw it.
	private ui void UpdateFreeze()
	{
		bool anyOpen = false;
		for (int wheel = 0; wheel < VRWheel.NumWheels; wheel++)
		{
			if (mWheels[wheel] != null && mWheels[wheel].WasOpen) anyOpen = true;
		}
		bool freeze = anyOpen && vr_wheel_freeze;
		if (freeze != mFrozen)
		{
			mFrozen = freeze;
			EventHandler.SendNetworkEvent(freeze ? "vrwheel_freeze:1" : "vrwheel_freeze:0");
		}
	}

	private ui static void SendChoice(int wheel, Inventory item)
	{
		String command = "vrwheel_weapon";
		if (wheel == VRWheel.Item)
		{
			command = vr_wheel_use_item ? "vrwheel_useitem" : "vrwheel_selectitem";
		}
		EventHandler.SendNetworkEvent(command .. ":" .. item.GetClassName());
	}

	// Segment 0 is at the top, the others follow clockwise.
	private ui static int FindEntry(int count, Vector2 dir)
	{
		if (count == 0 || dir.Length() < DEADZONE) return -1;
		double size = 360. / count;
		double angle = atan2(dir.X, dir.Y) + size / 2;
		if (angle < 0) angle += 360;
		return int(angle / size) % count;
	}

	//==========================================================================
	//
	// Contents, read from the inventory every frame so that ammo stays current
	// and mods need no support of their own.
	//
	//==========================================================================

	private ui void Fill(VRWheelState st, int wheel)
	{
		st.Entries.Clear();
		if (wheel == VRWheel.Weapon) FillWeapons(st);
		else FillItems(st);
	}

	private ui void FillWeapons(VRWheelState st)
	{
		let player = players[consoleplayer];
		// Slots 1 to 9, then 0, like the number keys.
		for (int key = 1; key <= 10; key++)
		{
			int slot = key % 10;
			let entry = new("VRWheelEntry");
			entry.Slot = slot;
			Array<int> order;
			for (let item = player.mo.Inv; item != null; item = item.Inv)
			{
				let weap = Weapon(item);
				if (weap == null) continue;
				// Weapons outside the slots (powered-up versions, helper weapons of mods) stay out.
				bool found;
				int weapSlot, index;
				[found, weapSlot, index] = player.weapons.LocateWeapon(weap.GetClass());
				if (!found || weapSlot != slot) continue;

				int pos = 0;
				while (pos < order.Size() && order[pos] < index) pos++;
				order.Insert(pos, index);
				entry.Choices.Insert(pos, weap);
			}
			if (entry.Choices.Size() == 0) continue;

			// Without a choice made with the trigger, show the weapon in hand, otherwise the slot's first.
			entry.Choice = st.SlotChoice[slot];
			if (entry.Choice < 0 || entry.Choice >= entry.Choices.Size())
			{
				int ready = entry.Choices.Find(player.ReadyWeapon);
				entry.Choice = ready != entry.Choices.Size() ? ready : 0;
			}
			st.Entries.Push(entry);
		}
	}

	private ui void FillItems(VRWheelState st)
	{
		for (let item = players[consoleplayer].mo.Inv; item != null; item = item.Inv)
		{
			if (!item.bInvBar || item.Amount <= 0) continue;
			let entry = new("VRWheelEntry");
			entry.Slot = -1;
			entry.Choices.Push(item);
			st.Entries.Push(entry);
		}
	}

	//==========================================================================
	//
	// Drawing, in screen pixels around the middle of the screen. In VR the
	// engine moves this to the hand.
	//
	//==========================================================================

	private ui void Draw(VRWheelState st, int wheel)
	{
		double alpha = clamp(vr_wheel_alpha, 0.1, 1.);
		Vector2 center = (Screen.GetWidth() / 2, Screen.GetHeight() / 2);
		double outer = Screen.GetHeight() * SCREEN_RADIUS;
		double inner = outer * INNER_RADIUS;
		double textScale = outer / 150;
		int count = st.Entries.Size();

		if (count == 0)
		{
			String empty = wheel == VRWheel.Weapon ? "$VRWHEEL_NOWEAPONS" : "$VRWHEEL_NOITEMS";
			DrawCentered(StringTable.Localize(empty), center, textScale, alpha);
			return;
		}

		// New shapes every frame, destroyed right after drawing: the draw commands keep their
		// buffers until the frame is done. Shapes kept in this static handler would only be
		// destroyed at exit, after the GL context, and crash there.
		double size = 360. / count;
		let segments = new("Shape2D");
		let hoverSegment = new("Shape2D");
		int vertices = 0;
		for (int i = 0; i < count; i++)
		{
			if (i == st.Hover) AddSector(hoverSegment, 0, center, inner, outer, i * size - size / 2, size);
			else vertices = AddSector(segments, vertices, center, inner, outer, i * size - size / 2, size);
		}
		// Red and blue are equal on purpose: DrawShapeFill swaps them in VR builds (its buffers
		// skip the BGRA to RGBA swap in Draw2D).
		Screen.DrawShapeFill(Color(70, 70, 70), alpha * 0.8, segments);
		if (st.Hover >= 0) Screen.DrawShapeFill(Color(60, 170, 60), alpha * 0.9, hoverSegment);
		segments.Destroy();
		hoverSegment.Destroy();

		double ring = outer - inner;
		double iconBox = min(ring, 2 * (inner + ring / 2) * sin(size / 2)) * 0.7;
		for (int i = 0; i < count; i++)
		{
			let entry = st.Entries[i];
			double angle = i * size;
			Vector2 pos = center + (sin(angle), -cos(angle)) * (inner + ring / 2);
			DrawEntry(entry, pos, iconBox, textScale, alpha);
		}

		if (st.Hover >= 0)
		{
			let item = st.Entries[st.Hover].Current();
			DrawCentered(item.GetTag(), center, textScale, alpha);
		}
	}

	// Ring piece from angle start over sweep degrees, 0 = up, clockwise. Shape2D cannot tell how
	// many vertices it has, so the caller passes the count so far and gets the new one back.
	private ui static int AddSector(Shape2D shape, int base, Vector2 center, double inner, double outer, double start, double sweep)
	{
		start += GAP / 2;
		sweep -= GAP;
		int steps = max(2, int(ARC_STEPS * sweep / 360));
		for (int s = 0; s <= steps; s++)
		{
			double a = start + sweep * s / steps;
			Vector2 dir = (sin(a), -cos(a));
			// DrawShapeFill needs a texture coordinate for every vertex, even without a texture.
			shape.PushVertex(center + dir * inner);
			shape.PushCoord((0, 0));
			shape.PushVertex(center + dir * outer);
			shape.PushCoord((0, 0));
			if (s > 0)
			{
				int v = base + s * 2;
				shape.PushTriangle(v - 2, v - 1, v);
				shape.PushTriangle(v - 1, v + 1, v);
			}
		}
		return base + (steps + 1) * 2;
	}

	private ui static void DrawEntry(VRWheelEntry entry, Vector2 pos, double box, double textScale, double alpha)
	{
		let item = entry.Current();
		int flags = entry.Slot >= 0 ? BaseStatusBar.DI_ALTICONFIRST : 0;
		TextureID icon = BaseStatusBar.GetInventoryIcon(item, flags);
		if (icon.IsValid())
		{
			Vector2 size = TexMan.GetScaledSize(icon);
			double scale = min(box / size.X, box / size.Y);
			Screen.DrawTexture(icon, false, pos.X, pos.Y, DTA_CenterOffset, true,
				DTA_DestWidthF, size.X * scale, DTA_DestHeightF, size.Y * scale, DTA_Alpha, alpha);
		}
		else
		{
			DrawCentered(item.GetTag(), pos, textScale * 0.6, alpha);
		}

		// Small line below the icon: ammo or amount, and "2/3" when the slot holds more weapons.
		String info = "";
		let weap = Weapon(item);
		if (weap != null && weap.Ammo1 != null) info = String.Format("%d", weap.Ammo1.Amount);
		else if (weap == null && item.MaxAmount > 1) info = String.Format("%d", item.Amount);
		if (entry.Choices.Size() > 1) info = String.Format("%s  %d/%d", info, entry.Choice + 1, entry.Choices.Size());
		if (info.Length() > 0) DrawCentered(info, pos + (0, box * 0.55), textScale * 0.5, alpha);
	}

	private ui static void DrawCentered(String text, Vector2 pos, double scale, double alpha)
	{
		Font fnt = NewSmallFont;
		double w = fnt.StringWidth(text) * scale;
		double h = fnt.GetHeight() * scale;
		Screen.DrawText(fnt, Font.CR_WHITE, pos.X - w / 2, pos.Y - h / 2, text,
			DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Alpha, alpha);
	}

	//==========================================================================
	//
	// Network events: the choice takes effect in the game for every player.
	//
	//==========================================================================

	override void NetworkProcess(ConsoleEvent e)
	{
		Array<String> args;
		e.Name.Split(args, ":");
		if (args.Size() != 2 || args[0].Left(8) != "vrwheel_") return;

		let player = players[e.Player];
		let mo = player.mo;
		if (mo == null) return;

		if (args[0] == "vrwheel_freeze")
		{
			if (!multiplayer) level.SetFrozen(args[1] == "1");
			return;
		}

		let item = mo.FindInventory(args[1]);
		if (item == null) return;

		if (args[0] == "vrwheel_weapon")
		{
			// Through Use like the slot keys: with the Tome of Power active this keeps the
			// powered version of the weapon.
			if (item is "Weapon") mo.UseInventory(item);
		}
		else if (args[0] == "vrwheel_useitem")
		{
			mo.UseInventory(item);
		}
		else if (args[0] == "vrwheel_selectitem")
		{
			mo.InvSel = item;
		}
	}
}
