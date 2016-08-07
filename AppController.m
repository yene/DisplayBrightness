
#import "AppController.h"
#include <stdio.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

@implementation NSSlider (Scrollwheel)

- (void)scrollWheel:(NSEvent*)event {
	float range = [self maxValue] - [self minValue];
	float increment = (range * [event deltaY]) / 100;
	float val = [self floatValue] + increment;
	
	BOOL wrapValue = ([[self cell] sliderType] == NSCircularSlider);
	
	if (wrapValue) {
		if (val < [self minValue]) {
			val = [self maxValue] - fabs(increment);
		}
		
		if( val > [self maxValue]) {
			val = [self minValue] + fabs(increment);
		}
	}
	
	[self setFloatValue:val];
	[self sendAction:[self action] to:[self target]];
}

@end

@implementation AppController {
	NSStatusItem *brightnessItem;
}

- (void)awakeFromNib {
	
	BOOL launchedBefore = [[NSUserDefaults standardUserDefaults] boolForKey:@"LaunchedBefore"];
	if (!launchedBefore) {
		[self askForLaunchOnStartup];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"LaunchedBefore"];
	}
	
	brightnessItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	NSBundle *bundle = [NSBundle mainBundle];
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon" ofType:@"png"]];
	[image setTemplate:YES];
	NSImage *imageWhite = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon_white" ofType:@"png"]];
	[brightnessItem.button setImage:image];
	[brightnessItem.button setAlternateImage:imageWhite];
	[brightnessItem.button setTarget:self];
	[brightnessItem.button setAction:@selector(openMenu)];
}

- (void)askForLaunchOnStartup {
	
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	if (![self loginItemExistsForPath:appPath]) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = NSLocalizedString(@"AlertTitel", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"AlertOK", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"AlertCancel", nil)];
		[alert setInformativeText:NSLocalizedString(@"AlertText", nil)];
		NSModalResponse response = [alert runModal];
		if (response == NSAlertFirstButtonReturn) {
			[self enableLoginItemForPath:appPath];
		}
	}
}

- (void)openMenu {
	
	NSMenu *menu = [[NSMenu alloc] init];
	[brightnessItem setMenu:menu];
	
	float br = [self getDisplayBrightness];
	if (br == -1) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] init];
		menuItem.title = NSLocalizedString(@"ToolTipNotSupported", nil);
		[brightnessItem.menu addItem:menuItem];
	} else {
		NSRect size = NSMakeRect(0,0,30,104);
		NSSlider *slider = [[NSSlider alloc] initWithFrame:size];
		[slider setTarget:self];
		[slider setAction:@selector(sliderAction:)];
		[slider setMaxValue:1.0];
		[slider setMinValue:0.01]; // 0 would turn the display black
		[slider setFloatValue:br];
		[slider setContinuous:YES];
		NSMenuItem *sliderItem = [[NSMenuItem alloc] init];
		[sliderItem setView:slider];
		[brightnessItem.menu addItem:sliderItem];
	}
	
	[brightnessItem.button performClick:self];
	brightnessItem.menu = nil;
}

- (void)sliderAction:(id)sender {
	[self setDisplayBrightness:[sender floatValue]];
}

- (void)setDisplayBrightness:(float)brightness {
	CFStringRef key = CFSTR(kIODisplayBrightnessKey);
	CGDirectDisplayID targetDisplay = [self currentDisplay];
	io_service_t service = IOServicePortFromCGDisplayID(targetDisplay);
	if (brightness != HUGE_VALF) {
		IODisplaySetFloatParameter(service, kNilOptions, key, brightness);
	}
}

- (CGDirectDisplayID)currentDisplay{
	CGEventRef ourEvent = CGEventCreate(NULL);
	CGPoint point = CGEventGetLocation(ourEvent);
	CFRelease(ourEvent);
	CGDirectDisplayID dspys;
	uint32_t dspyCnt;
	CGError dErr = CGGetDisplaysWithPoint(point, 1, &dspys, &dspyCnt);
	if (dErr == kCGErrorSuccess) {
		return dspys;
	} else {
		return CGMainDisplayID();
	}
}

- (float)getDisplayBrightness {
	
	CFStringRef key = CFSTR(kIODisplayBrightnessKey);
	CGDirectDisplayID targetDisplay = [self currentDisplay];
	io_service_t service = IOServicePortFromCGDisplayID(targetDisplay);
	float brightness = 1.0;
	CGDisplayErr dErr = IODisplayGetFloatParameter(service, kNilOptions, key, &brightness);
	IOObjectRelease(service);
	
	if (dErr == kIOReturnSuccess) {
		return brightness;
	} else {
		return -1;
	}
}

- (BOOL)loginItemExistsForPath:(NSString *)appPath {
	BOOL found = NO;
	UInt32 seedValue;
	CFURLRef thePath;
	
	LSSharedFileListRef theLoginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
				found = YES;
				break;
			}
			CFRelease(thePath);
		}
	}
	CFRelease((CFArrayRef)loginItemsArray);
	CFRelease(theLoginItemsRefs);
	
	return found;
}

- (void)disableLoginItem {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	[self disableLoginItemForPath:appPath];
}

- (void)disableLoginItemForPath:(NSString *)appPath {
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	LSSharedFileListRef loginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItemsRefs, &seedValue);
	for (id item in (__bridge NSArray *)loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
				LSSharedFileListItemRemove(loginItemsRefs, itemRef); // Deleting the item
			}
			// Docs for LSSharedFileListItemResolve say we're responsible
			// for releasing the CFURLRef that is returned
			if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
}

- (void)enableLoginItem {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	[self enableLoginItemForPath:appPath];
}

- (void)enableLoginItemForPath:(NSString *)appPath {
	LSSharedFileListRef theLoginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
	if (item) {
		CFRelease(item);
	}
	CFRelease(theLoginItemsRefs);
}

// Returns the io_service_t corresponding to a CG display ID, or 0 on failure.
// The io_service_t should be released with IOObjectRelease when not needed.
//
static io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID) {
	io_iterator_t iter;
	io_service_t serv, servicePort = 0;
	
	CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
	
	// releases matching for us
	kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault,
																									 matching,
																									 &iter);
	if (err) {
		return 0;
	}
	
	while ((serv = IOIteratorNext(iter)) != 0) {
		CFDictionaryRef info;
		CFIndex vendorID, productID;
		CFNumberRef vendorIDRef, productIDRef;
		Boolean success;
		
		info = IODisplayCreateInfoDictionary(serv, kIODisplayOnlyPreferredName);
		
		vendorIDRef = CFDictionaryGetValue(info, CFSTR(kDisplayVendorID));
		productIDRef = CFDictionaryGetValue(info, CFSTR(kDisplayProductID));
		
		success = CFNumberGetValue(vendorIDRef, kCFNumberCFIndexType, &vendorID);
		success &= CFNumberGetValue(productIDRef, kCFNumberCFIndexType, &productID);
		
		if (!success) {
			CFRelease(info);
			continue;
		}
		
		// If the vendor and product id along with the serial don't match
		// then we are not looking at the correct monitor.
		// NOTE: The serial number is important in cases where two monitors
		//       are the exact same.
		if (CGDisplayVendorNumber(displayID) != vendorID  ||
				CGDisplayModelNumber(displayID) != productID)
		{
			CFRelease(info);
			continue;
		}
		
		// The VendorID, Product ID, and the Serial Number all Match Up!
		// Therefore we have found the appropriate display io_service
		servicePort = serv;
		CFRelease(info);
		break;
	}
	
	IOObjectRelease(iter);
	return servicePort;
}

- (void)addQuitMenu {
	NSMenu *menu = [[NSMenu alloc] init];
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	NSMenuItem *menuItem = [[NSMenuItem alloc] init];
	menuItem.title = NSLocalizedString(@"Launch at startup", nil); // Launch at startup
	menuItem.target = self;
	
	if (![self loginItemExistsForPath:appPath]) {
		menuItem.action = @selector(enableLoginItem);
		[menuItem setState:NSOffState];
	} else {
		menuItem.action = @selector(disableLoginItem);
		[menuItem setState:NSOnState];
	}
	[menu addItem:menuItem];
	
	NSMenuItem *quitMenuItem = [[NSMenuItem alloc] init];
	quitMenuItem.title = NSLocalizedString(@"Quit", nil);
	quitMenuItem.target = self;
	quitMenuItem.action = @selector(quit);
	[menu addItem:quitMenuItem];
	
	brightnessItem.menu = menu;
	[brightnessItem.button performClick:self];
	brightnessItem.menu = nil;
}

- (void)quit {
	[NSApp terminate:self];
}

@end

@interface NSStatusBarButton (NSStatusBarButtonQuit)
- (void)rightMouseDown:(NSEvent *)event;
@end

@implementation NSStatusBarButton (NSStatusBarButtonQuit)
- (void)rightMouseDown:(NSEvent *)event {
	[self.target performSelector:@selector(addQuitMenu) withObject:nil];
}
- (void)scrollWheel:(NSEvent *)theEvent {
	[self.target performSelector:@selector(openMenu) withObject:nil];
}

@end
