//
//---------------------------------------------------------------------------
//
// Copyright(C) 2026 jantyka
// All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/
//
//--------------------------------------------------------------------------
//
/*
** vr_wheel.h
** Input state of the VR selection wheels: the weapon wheel on the weapon hand and the item
** wheel on the off hand. The wheels themselves are drawn and filled in ZScript
** (zscript/ui/vr_wheel.zs). No OpenVR types on purpose, so another VR backend can drive the
** same state.
*/

#pragma once

enum EVRWheel
{
	VRWHEEL_Weapon,	// weapon hand
	VRWHEEL_Item,	// off hand
	NUM_VRWHEELS
};

// What the key bindings see of a thumbstick click, as bits.
enum EVRWheelClick
{
	VRCLICK_Short = 1,	// RThumb/LThumb: a short click, sent briefly after the release
	VRCLICK_Held = 2,	// RThumb_Alt/LThumb_Alt: held while the wheel is off for this game
};

// Feeds the thumbstick click and the stick position of the hand that owns the wheel. Call it
// once per frame. Returns EVRWheelClick bits: a short click arrives after the release as a
// brief press, a long one opens the wheel. If the wheel is off for this game (the item wheel
// in Doom by default), a long click is held as the _Alt key instead, so it can be bound.
int VR_FilterWheelClick(EVRWheel wheel, bool clickDown, float stickX, float stickY);

// True while the wheel is open. The stick of its hand must then neither turn nor move the player.
bool VR_IsWheelOpen(EVRWheel wheel);

// True from the start of a click that may open the wheel. The stick directions of its hand must
// then not arrive as keys, or tilting the stick towards an entry would already trigger them.
bool VR_WheelHoldsStick(EVRWheel wheel);
