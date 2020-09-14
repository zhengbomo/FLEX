#include <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <dlfcn.h>

@interface FLEXManager

+ (instancetype)sharedManager;
- (void)showExplorer;

@end


@interface FLEXLoader: NSObject
@end

@implementation FLEXLoader

+ (instancetype)sharedInstance {
	static dispatch_once_t onceToken;
	static FLEXLoader *loader;
	dispatch_once(&onceToken, ^{
		loader = [[FLEXLoader alloc] init];
	});	

	return loader;
}

- (void)show {
	[[objc_getClass("FLEXManager") sharedManager] showExplorer];
}

@end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.bomo.flexloader.plist"];
	NSString *frameworkPath = @"/usr/lib/FLEXLoader/FLEX.framework/FLEX";

	if (![[NSFileManager defaultManager] fileExistsAtPath:frameworkPath]) {
		NSLog(@"FLEX.framework file not found: %@", frameworkPath);
		return;
	} 

	NSString *keyPath = [NSString stringWithFormat:@"FLEXLoaderEnabled-%@", [[NSBundle mainBundle] bundleIdentifier]];
	if ([[pref objectForKey:keyPath] boolValue]) {
		void *handle = dlopen([frameworkPath UTF8String], RTLD_NOW);
		if (handle == NULL) {
			char *error = dlerror();
			NSLog(@"Load FLEX.framework fail: %s", error);
			return;
		} 

		[[NSNotificationCenter defaultCenter] addObserver:[FLEXLoader sharedInstance]
										   selector:@selector(show)
											   name:UIApplicationDidBecomeActiveNotification
											 object:nil];
	}	

	[pool drain];
}
