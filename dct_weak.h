#ifndef _DCT_WEAK_H
	#define _DCT_WEAK_H

// Macros for portable support of notionally weak properties with ARC
// Contributors: Daniel Tull, Abizer Nasir, Rowan James
// Current version: https://gist.github.com/1594037
//
// Defines:
//	dct_weak		to be used as a replacement for the 'weak' keyword:
//						@property (dct_weak) NSObject* propertyName;
//	__dct_weak		to be used as a replacement for the '__weak' variable attribute:
//						__dct_weak NSObject* variableName;
//	dct_nil(x)		assigns nil to x only if ARC is not supported

	#import <Availability.h>

	#define dct_arc_MIN_IOS_TARGET			__IPHONE_4_0
	#define dct_arc_MIN_IOS_WEAK_TARGET		__IPHONE_5_0

	#define dct_arc_MIN_OS_X_TARGET			__MAC_10_6
	#define dct_arc_MIN_OS_X_WEAK_TARGET	__MAC_10_7

	// iOS conditions
	#if defined __IPHONE_OS_VERSION_MIN_REQUIRED
		
		#if __IPHONE_OS_VERSION_MIN_REQUIRED < dct_arc_MIN_IOS_SDK
			#warning "This program uses ARC which is only available in iOS SDK 4.0 and later."
		#endif
		
		#if __IPHONE_OS_VERSION_MIN_REQUIRED >= dct_arc_MIN_IOS_WEAK_TARGET
			#define dct_weak weak
			#define __dct_weak __weak
			#define dct_nil(x)
		
		#elif __IPHONE_OS_VERSION_MIN_REQUIRED >= dct_arc_MIN_IOS_TARGET
			#define dct_weak unsafe_unretained
			#define __dct_weak __unsafe_unretained
			#define dct_nil(x)	x = nil
		#endif

	// OS X equivalent
	#elif defined __MAC_OS_X_VERSION_MIN_REQUIRED

	// check for the OS X 10.7 SDK (can still target 10.6 with ARC using it)
		#if __MAC_OS_X_VERSION_MIN_REQUIRED < dct_arc_MIN_OS_X_SDK 
			#warning "This program uses ARC which is only available in OS X SDK 10.7 and later."
		#endif
		
		#if __MAC_OS_X_VERSION_MIN_REQUIRED >= dct_arc_MIN_OS_X_WEAK_TARGET
			#define dct_weak weak
			#define __dct_weak __weak
			#define dct_nil(x)
		
		#elif __MAC_OS_X_VERSION_MIN_REQUIRED >= dct_arc_MIN_OS_X_TARGET
			#define dct_weak unsafe_unretained
			#define __dct_weak __unsafe_unretained
			#define dct_nil(x)	x = nil
		#endif

	#else
	// Couldn't determine the platform, but ARC is still needed, so...
		#warning "This program requires ARC but we couldn't determine if your environment supports it"
	#endif

#endif // include guard