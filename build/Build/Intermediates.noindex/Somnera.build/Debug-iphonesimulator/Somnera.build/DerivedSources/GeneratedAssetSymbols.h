#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "digital_twin_3d" asset catalog image resource.
static NSString * const ACImageNameDigitalTwin3D AC_SWIFT_PRIVATE = @"digital_twin_3d";

#undef AC_SWIFT_PRIVATE
