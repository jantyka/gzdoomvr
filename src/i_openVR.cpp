#ifdef _WIN32
#include <Windows.h>
#endif
#include "d_event.h"
#ifdef _WIN32
#include "i_input.h"
#else
// Linux/SDL: the Win32 input header does not exist there, IJoystickConfig comes from m_joy.h
#include "m_joy.h"
#endif
#include "openvr_include.h"
#include "menu.h"
#include "i_openVR.h"
#include "vr_wheel.h"

using namespace openvr;

namespace s3d
{
	bool OpenVR_OnHandIsRight();
	VRControllerState_t& OpenVR_GetState(int hand);
	int OpenVR_GetTouchPadAxis();
	int OpenVR_GetJoystickAxis();
}

const float DEFAULT_DEADZONE = 0.25f;

enum Hand
{
	ON, OFF
};

enum Source
{
	STICK, PAD
};

enum Axis
{
	X, Y
};


enum AxisID
{
	OFF_HAND_PAD_X,
	OFF_HAND_STICK_X,
	OFF_HAND_PAD_Y,
	OFF_HAND_STICK_Y,

	ON_HAND_PAD_X,
	ON_HAND_STICK_X,
	ON_HAND_PAD_Y,
	ON_HAND_STICK_Y,

	NUM_AXES
};

static const Hand Hands[NUM_AXES] = { OFF, OFF, OFF, OFF, ON, ON, ON, ON };
static const Source Sources[NUM_AXES] = { PAD, STICK, PAD, STICK, PAD, STICK, PAD, STICK };
static const Axis AxisSources[NUM_AXES] = { X, X, Y, Y, X, X, Y, Y };

static const EJoyAxis DefaultMap[NUM_AXES] =
{
	JOYAXIS_Side,
	JOYAXIS_Side,
	JOYAXIS_Forward,
	JOYAXIS_Forward,
	JOYAXIS_Yaw,
	JOYAXIS_Yaw,
	JOYAXIS_Up,
	JOYAXIS_Up,
};


class FOpenVRJoystick : public IJoystickConfig
{
public:
	FOpenVRJoystick()
	{
		SetDefaultConfig();
		Multiplier = 1;
		M_LoadJoystickConfig(this);
	}

	~FOpenVRJoystick()
	{
		M_SaveJoystickConfig(this);
	}


	void ProcessInput()
	{

	}

	float GetAxisValue(int i, VRControllerState_t& offState, VRControllerState_t& onState)
	{
		//joysticks should be disabled while menu is shown, otherwise player moves while scrolling menu
		//The same while a VR wheel is open: then the stick of that hand chooses from the wheel.
		if (CurrentMenu == nullptr && !VR_IsWheelOpen(Hands[i] == ON ? VRWHEEL_Weapon : VRWHEEL_Item))
		{
			VRControllerState_t& state = Hands[i] == ON ? onState : offState;
			int axis = Sources[i] == PAD ? s3d::OpenVR_GetTouchPadAxis() : s3d::OpenVR_GetJoystickAxis();
			if (axis != -1)
			{
				float value = AxisSources[i] == X ? -state.rAxis[axis].x : state.rAxis[axis].y;
				if (fabsf(value) > Axes[i].DeadZone)
				{
					return value * Axes[i].Multiplier * Multiplier;
				}
			}
		}
		return 0.0f;
	}

	void AddAxes(float axes[NUM_JOYAXIS])
	{
		VRControllerState_t& onState = s3d::OpenVR_GetState(1);
		VRControllerState_t& offState = s3d::OpenVR_GetState(0);

		for (int i = 0; i < NUM_AXES; i++)
		{
			//JOYAXIS_Yaw needs special handling - must accumulate per render frame, not logical frame
			if (Axes[i].GameAxis == JOYAXIS_None || Axes[i].GameAxis == JOYAXIS_Yaw)
			{
				continue;
			}
			axes[Axes[i].GameAxis] += GetAxisValue(i, offState, onState);
		}
	}

	float GetYaw()
	{
		VRControllerState_t& onState = s3d::OpenVR_GetState(1);
		VRControllerState_t& offState = s3d::OpenVR_GetState(0);

		float yaw = 0.0f;

		for (int i = 0; i < NUM_AXES; i++)
		{
			//JOYAXIS_Yaw needs special handling - must accumulate per render frame, not logical frame
			if (Axes[i].GameAxis == JOYAXIS_Yaw)
			{
				yaw += GetAxisValue(i, offState, onState);
			}
		}

		return yaw;
	}

	FString GetName()
	{
		return "OpenVR";
	}

	float GetSensitivity()
	{
		return Multiplier;
	}

	void SetSensitivity(float scale)
	{
		Multiplier = scale;
	}

	int GetNumAxes()
	{
		return NUM_AXES;
	}

	float GetAxisDeadZone(int axis)
	{
		if (unsigned(axis) < NUM_AXES)
		{
			return Axes[axis].DeadZone;
		}
		return 0;
	}

	EJoyAxis GetAxisMap(int axis)
	{
		if (unsigned(axis) < NUM_AXES)
		{
			return Axes[axis].GameAxis;
		}
		return JOYAXIS_None;
	}

	const char* GetAxisName(int axis)
	{
		FString& name = Axes[axis].Name;

		name = "";
		name += s3d::OpenVR_OnHandIsRight() ? (Hands[axis] == ON ? "Right " : "Left ") : (Hands[axis] == ON ? "Left " : "Right ");
		name += Sources[axis] == PAD ? "Pad " : "Joystick ";
		name += AxisSources[axis] == X ? "Horizontal" : "Vertical";

		return name.GetChars();
	}

	float GetAxisScale(int axis)
	{
		return Axes[axis].Multiplier;
	}

	void SetAxisDeadZone(int axis, float v)
	{
		Axes[axis].DeadZone = v;
	}

	void SetAxisMap(int axis, EJoyAxis map)
	{
		Axes[axis].GameAxis = map;
	}

	void SetAxisScale(int axis, float v)
	{
		Axes[axis].Multiplier = v;
	}

	bool IsSensitivityDefault()
	{
		return Multiplier == 1;
	}

	bool IsAxisDeadZoneDefault(int axis)
	{
		return Axes[axis].DeadZone == DEFAULT_DEADZONE;
	}

	bool IsAxisMapDefault(int axis)
	{
		return Axes[axis].GameAxis == DefaultMap[axis];
	}

	bool IsAxisScaleDefault(int axis)
	{
		return Axes[axis].Multiplier == 1;
	}

	void SetDefaultConfig()
	{
		for (int i = 0; i < NUM_AXES; ++i)
		{
			Axes[i].GameAxis = DefaultMap[i];
			Axes[i].DeadZone = DEFAULT_DEADZONE;
			Axes[i].Multiplier = 1.0f;
		}
	}

	bool GetEnabled()
	{
		return true;
	}

	void SetEnabled(bool enabled)
	{
	}

	FString GetIdentifier()
	{
		return "OpenVR";
	}

	bool AllowsEnabledInBackground()
	{
		return true;
	}

	bool GetEnabledInBackground()
	{
		return true;
	}
	void SetEnabledInBackground(bool enabled) { }


	struct AxisInfo
	{
		float Multiplier;
		float DeadZone;
		EJoyAxis GameAxis;
		FString Name;
	};
	
	float Multiplier;
	AxisInfo Axes[NUM_AXES];


	int axisTrackpad = -1;
	int axisJoystick = -1;
	int axisTrigger = -1;
};

#ifdef _WIN32
class FOpenVRJoystickManager : public FJoystickCollection
{
public:
	bool GetDevice()
	{
		return true;
	}
	void ProcessInput()
	{
		m_device.ProcessInput();
	}
	void AddAxes(float axes[NUM_JOYAXIS])
	{
		m_device.AddAxes(axes);
	}
	float GetYaw()
	{
		return m_device.GetYaw();
	}
	void GetDevices(TArray<IJoystickConfig *> &sticks)
	{
		sticks.Push(&m_device);
	}
	IJoystickConfig *Rescan()
	{
		return &m_device;
	}

	FOpenVRJoystick m_device;
};

void I_StartupOpenVR()
{
	if (JoyDevices[INPUT_OpenVR] == NULL)
	{
		FJoystickCollection *joys = new FOpenVRJoystickManager;
		if (joys->GetDevice())
		{
			JoyDevices[INPUT_OpenVR] = joys;
			event_t ev = { EV_DeviceChange };
			D_PostEvent(&ev);
		}
	}
}

float I_OpenVRGetYaw()
{
	if (JoyDevices[INPUT_OpenVR] != NULL)
	{
		return ((FOpenVRJoystickManager*)JoyDevices[INPUT_OpenVR])->GetYaw();
	}
	return 0;
}

#else

// Linux/SDL: the SDL backend has no JoyDevices array and no FJoystickCollection, so the
// device is kept here and hooked into I_GetJoysticks()/I_GetAxes() in posix/sdl/i_joystick.cpp.
static FOpenVRJoystick *OpenVRJoystick;

void I_StartupOpenVR()
{
	if (OpenVRJoystick == nullptr)
	{
		OpenVRJoystick = new FOpenVRJoystick;
		event_t ev = { EV_DeviceChange };
		D_PostEvent(&ev);
	}
}

// Linux/SDL: deleting the device is what saves its axis configuration, like the
// JoyDevices cleanup in the Win32 I_ShutdownInput() does.
void I_ShutdownOpenVR()
{
	delete OpenVRJoystick;
	OpenVRJoystick = nullptr;
}

float I_OpenVRGetYaw()
{
	return OpenVRJoystick != nullptr ? OpenVRJoystick->GetYaw() : 0;
}

void I_OpenVRGetJoysticks(TArray<IJoystickConfig *> &sticks)
{
	if (OpenVRJoystick != nullptr)
	{
		sticks.Push(OpenVRJoystick);
	}
}

void I_OpenVRAddAxes(float axes[NUM_JOYAXIS])
{
	if (OpenVRJoystick != nullptr)
	{
		OpenVRJoystick->AddAxes(axes);
	}
}

#endif
