#include <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <dlfcn.h>

@interface FLEXManager2

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
	[[objc_getClass("FLEXManager2") sharedManager] showExplorer];
}

@end

%ctor {
	@autoreleasepool {
		NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.bomo.flexloader.plist"];
		
		NSString *flexFrameworkPath = @"/usr/lib/FLEXLoader/FLEX.framework/FLEX";
		if (![[NSFileManager defaultManager] fileExistsAtPath:flexFrameworkPath]) {
			NSLog(@"FLEX.framework file not found: %@", flexFrameworkPath);
			return;
		}
		NSString *keyPath = [NSString stringWithFormat:@"FLEXLoaderEnabled-%@", [[NSBundle mainBundle] bundleIdentifier]];
		if ([[pref objectForKey:keyPath] boolValue]) {
			void *handle = dlopen([flexFrameworkPath UTF8String], RTLD_NOW);
			if (handle == NULL) {
				char *error = dlerror();
				NSLog(@"Load FLEX.framework fail: %s", error);
				return;
			} 
		
			FLEXLoader *loader = [FLEXLoader sharedInstance];
			[[NSNotificationCenter defaultCenter] addObserver:loader
											selector:@selector(show)
												name:UIApplicationDidBecomeActiveNotification
												object:nil];
		}
	}
}
