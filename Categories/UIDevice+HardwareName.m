/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

// Thanks to Emanuele Vulcano, Kevin Ballard/Eridius, Ryandjohnson, Matt Brown, etc.

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "UIDevice+HardwareName.h"

@implementation UIDevice (Hardware)
/*
 Platforms
 
 iFPGA ->        ??

 iPhone1,1 ->    iPhone 1G, M68
 iPhone1,2 ->    iPhone 3G, N82
 iPhone2,1 ->    iPhone 3GS, N88
 iPhone3,1 ->    iPhone 4/AT&T, N89
 iPhone3,2 ->    iPhone 4/Other Carrier?, ??
 iPhone3,3 ->    iPhone 4/Verizon, TBD
 iPhone4,1 ->    (iPhone 4S/GSM), TBD
 iPhone4,2 ->    (iPhone 4S/CDMA), TBD
 iPhone4,3 ->    (iPhone 4S/???)
 iPhone5,1 ->    iPhone 5
 iPhone5,2 ->    iPhone 5
 iPhone5,3 ->    iPhone 5c
 iPhone5,4 ->    iPhone 5c
 iPhone6,1 ->    iPhone 5s
 iPhone6,2 ->    iPhone 5s
 iPhone7,1 ->    iPhone 6 Plus
 iPhone7,2 ->    iPhone 6
 iPhone8,1 ->    iPhone 6s
 iPhone8,2 ->    iPhone 6s Plus

 iPod1,1   ->    iPod touch 1G, N45
 iPod2,1   ->    iPod touch 2G, N72
 iPod2,2   ->    Unknown, ??
 iPod3,1   ->    iPod touch 3G, N18
 iPod4,1   ->    iPod touch 4G, N80
 iPod5,1   ->    iPod touch 5G, N78
 
 // Thanks NSForge
 iPad1,1   ->    iPad 1G, WiFi and 3G, K48
 iPad2,1   ->    iPad 2G, WiFi, K93
 iPad2,2   ->    iPad 2G, GSM 3G, K94
 iPad2,3   ->    iPad 2G, CDMA 3G, K95
 iPad2,4   ->    iPad 2G, 
 iPad3,1   ->    (iPad 3G, WiFi)
 iPad3,2   ->    (iPad 3G, GSM)
 iPad3,3   ->    (iPad 3G, CDMA)
 iPad3,4   ->    (iPad 3G)
 iPad3,5   ->    (iPad 3G)
 iPad3,6   ->    (iPad 3G)
 iPad4,1   ->    (iPad Air, WiFi)
 iPad4,2   ->    (iPad Air, GSM)
 iPad4,3   ->    (iPad Air, CDMA)
 iPad5,3   ->    (iPad Air 2)
 iPad5,4   ->    (iPad Air 2)

 iPad2,5   ->    iPad Mini 1G, 
 iPad2,6   ->    iPad Mini 1G, 
 iPad2,7   ->    iPad Mini 1G, 
 iPad4,4   ->    iPad Mini 2G, 
 iPad4,5   ->    iPad Mini 2G, 
 iPad4,6   ->    iPad Mini 2G, 
 iPad4,7   ->    iPad Mini 3G, 
 iPad4,8   ->    iPad Mini 3G, 
 iPad4,9   ->    iPad Mini 3G, 

 AppleTV2,1 ->   AppleTV 2, A1378
 AppleTV3,1 ->   AppleTV 3, A1427
 AppleTV3,2 ->   AppleTV 4, A1469

 i386, x86_64 -> iPhone Simulator
*/


#pragma mark sysctlbyname utils
- (NSString *) getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);
    return results;
}

- (NSString *) platform
{
    return [self getSysInfoByName:"hw.machine"];
}


// Thanks, Tom Harrington (Atomicbird)
- (NSString *) hwmodel
{
    return [self getSysInfoByName:"hw.model"];
}

#pragma mark sysctl utils
- (NSUInteger) getSysInfo: (uint) typeSpecifier
{
    size_t size = sizeof(int);
    int results;
    int mib[2] = {CTL_HW, typeSpecifier};
    sysctl(mib, 2, &results, &size, NULL, 0);
    return (NSUInteger) results;
}

- (NSUInteger) cpuFrequency
{
    return [self getSysInfo:HW_CPU_FREQ];
}

- (NSUInteger) busFrequency
{
    return [self getSysInfo:HW_BUS_FREQ];
}

- (NSUInteger) cpuCount
{
    return [self getSysInfo:HW_NCPU];
}

- (NSUInteger) totalMemory
{
    return [self getSysInfo:HW_PHYSMEM];
}

- (NSUInteger) userMemory
{
    return [self getSysInfo:HW_USERMEM];
}

- (NSUInteger) maxSocketBufferSize
{
    return [self getSysInfo:KIPC_MAXSOCKBUF];
}

#pragma mark file system -- Thanks Joachim Bean!

/*
 extern NSString *NSFileSystemSize;
 extern NSString *NSFileSystemFreeSize;
 extern NSString *NSFileSystemNodes;
 extern NSString *NSFileSystemFreeNodes;
 extern NSString *NSFileSystemNumber;
*/

- (NSNumber *) totalDiskSpace
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [fattributes objectForKey:NSFileSystemSize];
}

- (NSNumber *) freeDiskSpace
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [fattributes objectForKey:NSFileSystemFreeSize];
}

#pragma mark platform type and name utils

- (NSUInteger) platformType
{
    NSString *platform = [self platform];
    return [self platform2type:platform];
}

- (NSString *) platform2string: (NSString *)platform
{
    NSUInteger type = [self platform2type:platform];
    return [self type2string:type];
}

- (NSUInteger) platform2type: (NSString *)platform
{
    // The ever mysterious iFPGA
    if ([platform isEqualToString:@"iFPGA"])        return UIDeviceIFPGA;

    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"])    return UIDevice1GiPhone;
    if ([platform isEqualToString:@"iPhone1,2"])    return UIDevice3GiPhone;
    if ([platform isEqualToString:@"iPhone2,1"])    return UIDevice3GSiPhone;
    if ([platform isEqualToString:@"iPhone3,1"])    return UIDevice4iPhone;
    if ([platform isEqualToString:@"iPhone3,2"])    return UIDevice4iPhone;
    if ([platform isEqualToString:@"iPhone3,3"])    return UIDevice4iPhone;
    if ([platform isEqualToString:@"iPhone4,1"])    return UIDevice4SiPhone;
    if ([platform isEqualToString:@"iPhone4,2"])    return UIDevice4SiPhone;
    if ([platform isEqualToString:@"iPhone4,3"])    return UIDevice4SiPhone;
    if ([platform isEqualToString:@"iPhone5,1"])    return UIDevice5iPhone;
    if ([platform isEqualToString:@"iPhone5,2"])    return UIDevice5iPhone;
    if ([platform isEqualToString:@"iPhone5,3"])    return UIDevice5CiPhone;
    if ([platform isEqualToString:@"iPhone5,4"])    return UIDevice5CiPhone;
    if ([platform isEqualToString:@"iPhone6,1"])    return UIDevice5SiPhone;
    if ([platform isEqualToString:@"iPhone6,2"])    return UIDevice5SiPhone;
    if ([platform isEqualToString:@"iPhone7,1"])    return UIDevice6PlusiPhone;
    if ([platform isEqualToString:@"iPhone7,2"])    return UIDevice6iPhone;
	if ([platform isEqualToString:@"iPhone8,1"])    return UIDevice6sPlusiPhone;
	if ([platform isEqualToString:@"iPhone8,2"])    return UIDevice6siPhone;

    if ([platform isEqualToString:@"iPod1,1"])    return UIDevice1GiPod;
    if ([platform isEqualToString:@"iPod2,1"])    return UIDevice2GiPod;
    if ([platform isEqualToString:@"iPod2,2"])    return UIDevice2GiPod;
    if ([platform isEqualToString:@"iPod3,1"])    return UIDevice3GiPod;
    if ([platform isEqualToString:@"iPod4,1"])    return UIDevice4GiPod;
    if ([platform isEqualToString:@"iPod5,1"])    return UIDevice5GiPod;
    
    // Thanks NSForge
    if ([platform isEqualToString:@"iPad1,1"])    return UIDevice1GiPad;
    if ([platform isEqualToString:@"iPad2,1"])    return UIDevice2GiPad;
    if ([platform isEqualToString:@"iPad2,2"])    return UIDevice2GiPad;
    if ([platform isEqualToString:@"iPad2,3"])    return UIDevice2GiPad;
    if ([platform isEqualToString:@"iPad2,4"])    return UIDevice2GiPad;
    if ([platform isEqualToString:@"iPad3,1"])    return UIDevice3GiPad;
    if ([platform isEqualToString:@"iPad3,2"])    return UIDevice3GiPad;
    if ([platform isEqualToString:@"iPad3,3"])    return UIDevice3GiPad;
    if ([platform isEqualToString:@"iPad3,4"])    return UIDevice3GiPad;
    if ([platform isEqualToString:@"iPad3,5"])    return UIDevice3GiPad;
    if ([platform isEqualToString:@"iPad3,6"])    return UIDevice3GiPad;
    if ([platform isEqualToString:@"iPad4,1"])    return UIDeviceAiriPad;
    if ([platform isEqualToString:@"iPad4,2"])    return UIDeviceAiriPad;
    if ([platform isEqualToString:@"iPad4,3"])    return UIDeviceAiriPad;
    if ([platform isEqualToString:@"iPad5,3"])    return UIDeviceAir2iPad;
    if ([platform isEqualToString:@"iPad5,4"])    return UIDeviceAir2iPad;
    
    if ([platform isEqualToString:@"iPad2,5"])    return UIDevice1GiPadMini;
    if ([platform isEqualToString:@"iPad2,6"])    return UIDevice1GiPadMini;
    if ([platform isEqualToString:@"iPad2,7"])    return UIDevice1GiPadMini;
    if ([platform isEqualToString:@"iPad4,4"])    return UIDevice2GiPadMini;
    if ([platform isEqualToString:@"iPad4,5"])    return UIDevice2GiPadMini;
    if ([platform isEqualToString:@"iPad4,6"])    return UIDevice2GiPadMini;
    if ([platform isEqualToString:@"iPad4,7"])    return UIDevice3GiPadMini;
    if ([platform isEqualToString:@"iPad4,8"])    return UIDevice3GiPadMini;
    if ([platform isEqualToString:@"iPad4,9"])    return UIDevice3GiPadMini;
    
    if ([platform isEqualToString:@"AppleTV2,1"])    return UIDeviceAppleTV2;
    if ([platform isEqualToString:@"AppleTV3,1"])    return UIDeviceAppleTV3;
    if ([platform isEqualToString:@"AppleTV3,2"])    return UIDeviceAppleTV4;

    if ([platform hasPrefix:@"iPhone"])             return UIDeviceUnknowniPhone;
    if ([platform hasPrefix:@"iPod"])               return UIDeviceUnknowniPod;
    if ([platform hasPrefix:@"iPad"])               return UIDeviceUnknowniPad;
    if ([platform hasPrefix:@"iPad"])               return UIDeviceUnknowniPad;
    if ([platform hasPrefix:@"AppleTV"])            return UIDeviceUnknownAppleTV;
    
    // Simulator thanks Jordan Breeding
    if ([platform hasSuffix:@"86"] || [platform isEqual:@"x86_64"])
    {
        BOOL smallerScreen = [[UIScreen mainScreen] bounds].size.width < 768;
        return smallerScreen ? UIDeviceSimulatoriPhone : UIDeviceSimulatoriPad;
    }

    return UIDeviceUnknown;
}

- (NSString *) platformString
{
    return [self type2string:[self platformType]];
}

- (NSString *) type2string:(NSUInteger)type
{
    switch (type)
    {
        case UIDevice1GiPhone: return IPHONE_1G_NAMESTRING;
        case UIDevice3GiPhone: return IPHONE_3G_NAMESTRING;
        case UIDevice3GSiPhone: return IPHONE_3GS_NAMESTRING;
        case UIDevice4iPhone: return IPHONE_4_NAMESTRING;
        case UIDevice4SiPhone: return IPHONE_4S_NAMESTRING;
        case UIDevice5iPhone: return IPHONE_5_NAMESTRING;
        case UIDevice5CiPhone: return IPHONE_5C_NAMESTRING;
        case UIDevice5SiPhone: return IPHONE_5S_NAMESTRING;
        case UIDevice6iPhone: return IPHONE_6_NAMESTRING;
        case UIDevice6PlusiPhone: return IPHONE_6PLUS_NAMESTRING;
		case UIDevice6siPhone: return IPHONE_6S_NAMESTRING;
		case UIDevice6sPlusiPhone: return IPHONE_6SPLUS_NAMESTRING;
        case UIDeviceUnknowniPhone: return IPHONE_UNKNOWN_NAMESTRING;
        
        case UIDevice1GiPod: return IPOD_1G_NAMESTRING;
        case UIDevice2GiPod: return IPOD_2G_NAMESTRING;
        case UIDevice3GiPod: return IPOD_3G_NAMESTRING;
        case UIDevice4GiPod: return IPOD_4G_NAMESTRING;
        case UIDevice5GiPod: return IPOD_5G_NAMESTRING;
        case UIDeviceUnknowniPod: return IPOD_UNKNOWN_NAMESTRING;
            
        case UIDevice1GiPad: return IPAD_1G_NAMESTRING;
        case UIDevice2GiPad: return IPAD_2G_NAMESTRING;
        case UIDevice3GiPad: return IPAD_3G_NAMESTRING;
        case UIDeviceAiriPad: return IPAD_Air_NAMESTRING;
        case UIDeviceAir2iPad: return IPAD_Air2_NAMESTRING;
        case UIDeviceUnknowniPad: return IPAD_UNKNOWN_NAMESTRING;
            
        case UIDevice1GiPadMini: return IPAD_MINI_1G_NAMESTRING;
        case UIDevice2GiPadMini: return IPAD_MINI_2G_NAMESTRING;
        case UIDevice3GiPadMini: return IPAD_MINI_3G_NAMESTRING;
        case UIDeviceUnknowniPadMini: return IPAD_MINI_UNKNOWN_NAMESTRING;
            
        case UIDeviceAppleTV2: return APPLETV_2G_NAMESTRING;
        case UIDeviceAppleTV3: return APPLETV_3G_NAMESTRING;
        case UIDeviceAppleTV4: return APPLETV_4G_NAMESTRING;
        case UIDeviceUnknownAppleTV: return APPLETV_UNKNOWN_NAMESTRING;
            
        case UIDeviceSimulator: return SIMULATOR_NAMESTRING;
        case UIDeviceSimulatoriPhone: return SIMULATOR_IPHONE_NAMESTRING;
        case UIDeviceSimulatoriPad: return SIMULATOR_IPAD_NAMESTRING;
        case UIDeviceSimulatorAppleTV: return SIMULATOR_APPLETV_NAMESTRING;
            
        case UIDeviceIFPGA: return IFPGA_NAMESTRING;
            
        default: return IOS_FAMILY_UNKNOWN_DEVICE;
    }
}

- (BOOL) hasRetinaDisplay
{
    return ([UIScreen mainScreen].scale == 2.0f);
}

- (UIDeviceFamily) deviceFamily
{
    NSString *platform = [self platform];
    if ([platform hasPrefix:@"iPhone"]) return UIDeviceFamilyiPhone;
    if ([platform hasPrefix:@"iPod"]) return UIDeviceFamilyiPod;
    if ([platform hasPrefix:@"iPad"]) return UIDeviceFamilyiPad;
    if ([platform hasPrefix:@"AppleTV"]) return UIDeviceFamilyAppleTV;
    
    return UIDeviceFamilyUnknown;
}

#pragma mark MAC addy
// Return the local MAC addy
// Courtesy of FreeBSD hackers email list
// Accidentally munged during previous update. Fixed thanks to mlamb.
- (NSString *) macaddress
{
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Error: Memory allocation error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2\n");
        free(buf); // Thanks, Remy "Psy" Demerest
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];

    free(buf);
    return outstring;
}

// Illicit Bluetooth check -- cannot be used in App Store
/* 
Class  btclass = NSClassFromString(@"GKBluetoothSupport");
if ([btclass respondsToSelector:@selector(bluetoothStatus)])
{
    printf("BTStatus %d\n", ((int)[btclass performSelector:@selector(bluetoothStatus)] & 1) != 0);
    bluetooth = ((int)[btclass performSelector:@selector(bluetoothStatus)] & 1) != 0;
    printf("Bluetooth %s enabled\n", bluetooth ? "is" : "isn't");
}
*/
@end