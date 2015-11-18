//
//  AppController.m
//  DisplayBrightness
//
//  Created by Yannick Weiss on 15.12.09.
//  Copyright 2009 yannickweiss.com. All rights reserved.
//

#import "AppController.h"
#include <stdio.h> 
#include <IOKit/graphics/IOGraphicsLib.h> 
#include <ApplicationServices/ApplicationServices.h> 

@implementation NSSlider (Scrollwheel)

- (void)    scrollWheel:(NSEvent*) event
{
  float range = [self maxValue] - [self minValue];
  float increment = (range * [event deltaY]) / 100;
  float val = [self floatValue] + increment;
  
  BOOL wrapValue = ([[self cell] sliderType] == NSCircularSlider);
  
  if( wrapValue )
  {
    if ( val < [self minValue])
      val = [self maxValue] - fabs(increment);
    
    if( val > [self maxValue])
      val = [self minValue] + fabs(increment);
  }
  
  [self setFloatValue:val];
  [self sendAction:[self action] to:[self target]];
}

@end

@implementation AppController
- (void) awakeFromNib {
  
  // on first run ask to add the app to login items, ignore if it already is added
  BOOL launchedBefore = [[NSUserDefaults standardUserDefaults] boolForKey:@"LaunchedBefore"];
  if (!launchedBefore) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"LaunchedBefore"];
    
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    if (![self loginItemExistsForPath:appPath]) {
      NSAlert *alert = [[NSAlert alloc] init];
      alert.messageText = @"Should start on Login?";
      [alert addButtonWithTitle:@"Launch on Startup"];
      [alert addButtonWithTitle:@"Cancel"];
      [alert setInformativeText:@"Should the App be added to your Login items. You can remove it anytime in the User settings."];
      NSModalResponse response = [alert runModal];
      if (response == NSAlertFirstButtonReturn) {
        [self enableLoginItemForPath:appPath];
      }
    }
  }
  
  
	//Create the NSStatusBar and set its length
  brightnessItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  
  //Used to detect where our files are
  NSBundle *bundle = [NSBundle mainBundle];
    
  //Allocates and loads the images into the application which will be used for our NSStatusItem
  brightnessImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"display_icon" ofType:@"png"]];
  brightnessImageHighlight = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"display_icon_white" ofType:@"png"]];

  //Sets the images in our NSStatusItem
  [brightnessItem setImage:brightnessImage];
  [brightnessItem setAlternateImage:brightnessImageHighlight];
  
	NSRect size = NSMakeRect(0,0,30,104);
	NSSlider *brightnessSlider = [[NSSlider alloc] initWithFrame:size];
	[brightnessSlider bind:@"value" toObject:self withKeyPath:@"value" options:nil];
	[brightnessSlider setMaxValue:1.0];
	[brightnessSlider setMinValue:0.01];
	[brightnessSlider setFloatValue:[self getDisplayBrightness]];
	[brightnessSlider setContinuous:YES];

	[brightnessSliderItem setView:brightnessSlider];
  //Tells the NSStatusItem what menu to load
  [brightnessItem setMenu:brightnessMenu];
  //Sets the tooptip for our item
  [brightnessItem setToolTip:@"DisplayBrightness Menu Item"];
  //Enables highlighting
  [brightnessItem setHighlightMode:YES];
	
	[self addObserver:self forKeyPath:@"value"
							  options:(NSKeyValueObservingOptionNew)
							  context:NULL]; 
}

- (void)menuWillOpen:(NSMenu *)menu
{
    [self willChangeValueForKey:@"value"];
    value = [self getDisplayBrightness];
    [self didChangeValueForKey:@"value"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	[self setDisplayBrightness:value];
}



- (void)setDisplayBrightness:(float)brightness {
  CFStringRef key = CFSTR(kIODisplayBrightnessKey);
  CGDirectDisplayID targetDisplay = [self currentDisplay];
  io_service_t service = IOServicePortFromCGDisplayID(targetDisplay);
  if (brightness != HUGE_VALF) { // set the brightness, if requested
    IODisplaySetFloatParameter(service, kNilOptions, key, brightness);
  }
}

- (CGDirectDisplayID)currentDisplay{
  NSPoint mouseLocation = [NSEvent mouseLocation];
  CGDirectDisplayID dspys;
  uint32_t dspyCnt;
  CGError dErr = CGGetDisplaysWithPoint(mouseLocation, 1, &dspys, &dspyCnt);
  if (dErr == kCGErrorSuccess) {
    return dspys;
  } else {
    return CGMainDisplayID();
  }
}

- (float)getDisplayBrightness {
  [self currentDisplay];
  CGDisplayErr      dErr;
  io_service_t      service;
  CGDirectDisplayID targetDisplay;
  
  CFStringRef key = CFSTR(kIODisplayBrightnessKey);
  targetDisplay = [self currentDisplay];
  service = IOServicePortFromCGDisplayID(targetDisplay);
  float brightness = 1.0;
  dErr = IODisplayGetFloatParameter(service, kNilOptions, key, &brightness);
  IOObjectRelease(service);
  
  if (dErr == kIOReturnSuccess) {
    return brightness;
  } else {
    // TODO disable the slider for this screen
    return 1.0;
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
static io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID)
{
  io_iterator_t iter;
  io_service_t serv, servicePort = 0;
  
  CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
  
  // releases matching for us
  kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                   matching,
                                                   &iter);
  if (err)
    return 0;
  
  while ((serv = IOIteratorNext(iter)) != 0)
  {
    CFDictionaryRef info;
    CFIndex vendorID, productID;
    CFNumberRef vendorIDRef, productIDRef;
    Boolean success;
    
    info = IODisplayCreateInfoDictionary(serv,
                                         kIODisplayOnlyPreferredName);
    
    vendorIDRef = CFDictionaryGetValue(info,
                                       CFSTR(kDisplayVendorID));
    productIDRef = CFDictionaryGetValue(info,
                                        CFSTR(kDisplayProductID));
    
    success = CFNumberGetValue(vendorIDRef, kCFNumberCFIndexType,
                               &vendorID);
    success &= CFNumberGetValue(productIDRef, kCFNumberCFIndexType,
                                &productID);
    
    if (!success)
    {
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


@end
