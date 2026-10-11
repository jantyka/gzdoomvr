#pragma once

#if defined(__linux__) || defined(__APPLE__)
// Linux/macOS: openvr.h packs the controller state to 4 bytes on these platforms and the
// runtime fills in that layout. See the comment above VRControllerState001_t in openvr.h of the
// OpenVR SDK: "This structure was originally defined mis-packed on Linux, preserved for
// compatibility." openvr_capi.h has no such pragma for VRControllerState_t (checked with SDK
// 2.15.6), so its struct is 4 bytes larger and every button and axis would be read from the
// wrong offset. Keep the C header's struct under another name and define the packed one below.
#define VRControllerState_t VRControllerState_capi_t
#endif
namespace openvr {
	#include "openvr_capi.h"
#if defined(__linux__) || defined(__APPLE__)
#undef VRControllerState_t
#pragma pack( push, 4 )
	struct VRControllerState_t
	{
		uint32_t unPacketNum;
		uint64_t ulButtonPressed;
		uint64_t ulButtonTouched;
		VRControllerAxis_t rAxis[5];
	};
#pragma pack( pop )
#else
	typedef VRControllerState_t VRControllerState_capi_t;
#endif
}
