//
//  AppController.m
//  DisplayBrightness
//
//  Created by Yannick Weiss on 15.12.09.
//  Copyright 2009 autoreleasepool.com. All rights reserved.
//

// Some code is from http://blacktree-nocturne.googlecode.com/svn-history/r12/trunk/QSNocturneController.m
// Icons come from http://www.bergdesign.com/brightness/

#import "AppController.h"
#include <stdio.h> 
#include <IOKit/graphics/IOGraphicsLib.h> 
#include <ApplicationServices/ApplicationServices.h> 

@implementation AppController
- (void) awakeFromNib {
	
	//Create the NSStatusBar and set its length
    brightnessItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
  
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    brightnessImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"display_icon" ofType:@"png"]];
    brightnessImageHighlight = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"display_icon_white" ofType:@"png"]];
    
    //Sets the images in our NSStatusItem
    [brightnessItem setImage:brightnessImage];
    [brightnessItem setAlternateImage:brightnessImageHighlight];
    
	NSRect size = NSMakeRect(0,0,30,100);
	NSSlider *brightnessSlider = [[NSSlider alloc] initWithFrame:size];
	[brightnessSlider bind:@"value" toObject:self withKeyPath:@"value" options:nil];
	[brightnessSlider setMaxValue:1.0];
	[brightnessSlider setMinValue:0.0];
	[brightnessSlider setFloatValue:[self getDisplayBrightness]];
	[brightnessSlider setContinuous:YES];

	[brightnessSliderItem setView:brightnessSlider];
	[brightnessSlider release];
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

- (void) dealloc {
    //Releases the 2 images we loaded into memory
    [brightnessImage release];
	[brightnessImageHighlight release];
    [super dealloc];
}


- (void)setDisplayBrightness:(float)brightness {
	CGDisplayErr      dErr;
	io_service_t      service;
	CGDirectDisplayID targetDisplay;
	
	CFStringRef key = CFSTR(kIODisplayBrightnessKey);
	
	targetDisplay = CGMainDisplayID();
	service = CGDisplayIOServicePort(targetDisplay);
	
	if (brightness != HUGE_VALF) { // set the brightness, if requested
		dErr = IODisplaySetFloatParameter(service, kNilOptions, key, brightness);
	}
}
- (float)getDisplayBrightness {
	CGDisplayErr      dErr;
	io_service_t      service;
	CGDirectDisplayID targetDisplay;
	
	CFStringRef key = CFSTR(kIODisplayBrightnessKey);
	
	targetDisplay = CGMainDisplayID();
	service = CGDisplayIOServicePort(targetDisplay);
	
	float brightness = 1.0;
	dErr = IODisplayGetFloatParameter(service, kNilOptions, key, &brightness);
	
	if (dErr == kIOReturnSuccess) {
		return brightness;
	} else {
		return 1.0;
	}
}

@end
