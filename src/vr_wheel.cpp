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
** vr_wheel.cpp
** Input state of the VR selection wheels, see vr_wheel.h.
*/

#include "vr_wheel.h"
#include "c_cvars.h"
#include "c_dispatch.h"
#include "c_console.h"
#include "i_time.h"
#include "i_interface.h"
#include "gamestate.h"
#include "menustate.h"
#include "vm.h"

CVAR(Bool, vr_wheel_enabled, true, CVAR_ARCHIVE | CVAR_GLOBALCONFIG)
CVAR(Int, vr_wheel_hold_ms, 250, CVAR_ARCHIVE | CVAR_GLOBALCONFIG)
// Read by zscript/ui/vr_wheel.zs
CVAR(Float, vr_wheel_alpha, 0.85f, CVAR_ARCHIVE | CVAR_GLOBALCONFIG)
CVAR(Bool, vr_wheel_freeze, false, CVAR_ARCHIVE | CVAR_GLOBALCONFIG)	// stop time while a wheel is open (single player)
CVAR(Bool, vr_wheel_use_item, true, CVAR_ARCHIVE | CVAR_GLOBALCONFIG)	// false: the item wheel only selects

enum EWheelState
{
	WS_Idle,
	WS_PassThrough,	// click that began while no wheel could open, reaches the bindings unchanged
	WS_Pending,		// click held, not yet long enough to open the wheel
	WS_ShortClick,	// short click released, now sent to the bindings as a brief press
	WS_Open,
	WS_Releasing,	// click let go, the wheel waits a moment in case the click comes back
	WS_Released,	// selection is ready for ZScript to pick up
};

struct FVRWheel
{
	EWheelState State = WS_Idle;
	bool FromCommand = false;	// opened by +vr_weaponwheel/+vr_itemwheel instead of a stick click
	uint64_t Time = 0;			// when the current state began
	float X = 0, Y = 0;			// stick position; from the moment of release on, the position at release
};

static FVRWheel Wheels[NUM_VRWHEELS];

// Two tics, so that +action bindings see the short click in at least one of them.
static const uint64_t SHORT_CLICK_MS = 60;

// Pressing a thumbstick down and tilting it at the same time can lose the click for a moment.
// That must not count as letting go.
static const uint64_t RELEASE_GRACE_MS = 80;

static bool WheelCanOpen()
{
	return vr_wheel_enabled && gamestate == GS_LEVEL && menuactive == MENU_Off && ConsoleState == c_up && !paused;
}

bool VR_IsWheelOpen(EVRWheel wheel)
{
	auto state = Wheels[wheel].State;
	return state == WS_Open || state == WS_Releasing;
}

bool VR_FilterWheelClick(EVRWheel wheel, bool clickDown, float stickX, float stickY)
{
	auto &w = Wheels[wheel];
	uint64_t now = I_msTime();

	if (VR_IsWheelOpen(wheel) && !WheelCanOpen())
	{
		// A menu, the console or the end of the level closed the wheel. Nothing is selected.
		w.State = WS_Idle;
	}

	switch (w.State)
	{
	case WS_Idle:
	case WS_Released:	// a new click drops a selection that ZScript never picked up
		if (!clickDown)
		{
			return false;
		}
		w.State = WheelCanOpen() ? WS_Pending : WS_PassThrough;
		w.Time = now;
		return w.State == WS_PassThrough;

	case WS_PassThrough:
		if (!clickDown)
		{
			w.State = WS_Idle;
		}
		return clickDown;

	case WS_Pending:
		if (!clickDown)
		{
			w.State = WS_ShortClick;
			w.Time = now;
			return true;
		}
		if (vr_wheel_hold_ms <= 0 || now - w.Time >= (uint64_t)*vr_wheel_hold_ms)
		{
			w.State = WS_Open;
			w.FromCommand = false;
			w.Time = now;
		}
		w.X = stickX;
		w.Y = stickY;
		return false;

	case WS_ShortClick:
		if (now - w.Time < SHORT_CLICK_MS)
		{
			return true;
		}
		w.State = WS_Idle;
		return false;

	case WS_Open:
		if (w.FromCommand)
		{
			return false;
		}
		if (!clickDown)
		{
			// X and Y stay as they are now: the stick position at release decides.
			w.State = WS_Releasing;
			w.Time = now;
			return false;
		}
		w.X = stickX;
		w.Y = stickY;
		return false;

	case WS_Releasing:
		if (clickDown)
		{
			w.State = WS_Open;
		}
		else if (now - w.Time >= RELEASE_GRACE_MS)
		{
			w.State = WS_Released;
		}
		return false;
	}
	return false;
}

// Desktop and keyboard players: hold a key bound to +vr_weaponwheel or +vr_itemwheel to open a
// wheel, ZScript then picks the direction from the mouse. Also handy to test the wheels without
// a headset.
static void OpenWheelFromCommand(EVRWheel wheel)
{
	auto &w = Wheels[wheel];
	if (w.State != WS_Open && WheelCanOpen())
	{
		w.State = WS_Open;
		w.FromCommand = true;
		w.Time = I_msTime();
		w.X = w.Y = 0;
	}
}

static void ReleaseWheelFromCommand(EVRWheel wheel)
{
	auto &w = Wheels[wheel];
	if (w.State == WS_Open && w.FromCommand)
	{
		w.State = WS_Released;
	}
}

static FConsoleCommand WeaponWheelDown("+vr_weaponwheel", [](FCommandLine &, int) { OpenWheelFromCommand(VRWHEEL_Weapon); });
static FConsoleCommand WeaponWheelUp("-vr_weaponwheel", [](FCommandLine &, int) { ReleaseWheelFromCommand(VRWHEEL_Weapon); });
static FConsoleCommand ItemWheelDown("+vr_itemwheel", [](FCommandLine &, int) { OpenWheelFromCommand(VRWHEEL_Item); });
static FConsoleCommand ItemWheelUp("-vr_itemwheel", [](FCommandLine &, int) { ReleaseWheelFromCommand(VRWHEEL_Item); });

//==========================================================================
//
// ZScript interface (struct VRWheel in zscript/ui/vr_wheel.zs)
//
//==========================================================================

static FVRWheel &CheckWheel(int wheel)
{
	if ((unsigned)wheel >= NUM_VRWHEELS)
	{
		ThrowAbortException(X_ARRAY_OUT_OF_BOUNDS, "VRWheel: wheel %d does not exist", wheel);
	}
	return Wheels[wheel];
}

// 0 = closed, 1 = open, 2 = just released. The release is reported once, then the wheel is closed.
DEFINE_ACTION_FUNCTION(_VRWheel, Poll)
{
	PARAM_PROLOGUE;
	PARAM_INT(wheel);
	auto &w = CheckWheel(wheel);
	int result = 0;
	if (VR_IsWheelOpen(EVRWheel(wheel)))
	{
		result = 1;
	}
	else if (w.State == WS_Released)
	{
		w.State = WS_Idle;
		result = 2;
	}
	ACTION_RETURN_INT(result);
}

DEFINE_ACTION_FUNCTION(_VRWheel, GetStick)
{
	PARAM_PROLOGUE;
	PARAM_INT(wheel);
	auto &w = CheckWheel(wheel);
	ACTION_RETURN_VEC2(DVector2(w.X, w.Y));
}

DEFINE_ACTION_FUNCTION(_VRWheel, FromCommand)
{
	PARAM_PROLOGUE;
	PARAM_INT(wheel);
	ACTION_RETURN_BOOL(CheckWheel(wheel).FromCommand);
}
