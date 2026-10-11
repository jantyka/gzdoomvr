//
//---------------------------------------------------------------------------
//
// Copyright(C) 2026 jantyka
// All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/
//
//--------------------------------------------------------------------------
//
/*
** i_openVR.h
** Access to the OpenVR controller device (FOpenVRJoystick in i_openVR.cpp).
** No OpenVR types on purpose, so another VR backend could provide the same functions.
*/

#pragma once

#include "m_joy.h"

// Creates the controller device once and announces it with EV_DeviceChange. All platforms;
// called every frame while VR renders, later calls do nothing.
void I_StartupOpenVR();

// Sum of the stick axes mapped to turning, 0 without a device. All platforms. Turning is read
// per render frame instead of per tic, which is why it does not go through I_GetAxes().
float I_OpenVRGetYaw();

#ifndef _WIN32
// Linux/SDL only: on Windows the device is registered in JoyDevices[INPUT_OpenVR] and the
// Win32 input code handles the three jobs below.

// Deletes the device. This is what saves its axis configuration to the config file.
void I_ShutdownOpenVR();

// Appends the device to the list shown under Controller Options, if it exists.
void I_OpenVRGetJoysticks(TArray<IJoystickConfig *> &sticks);

// Adds the stick axes that are not mapped to turning to the given axis values.
void I_OpenVRAddAxes(float axes[NUM_JOYAXIS]);
#endif
