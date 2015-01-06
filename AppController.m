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
  io_service_t      service;
  CGDirectDisplayID targetDisplay;
  
  CFStringRef key = CFSTR(kIODisplayBrightnessKey);
  
  targetDisplay = [self currentDisplay];
  service = CGDisplayIOServicePort(targetDisplay);
  
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
  service = CGDisplayIOServicePort(targetDisplay);
  
  float brightness = 1.0;
  dErr = IODisplayGetFloatParameter(service, kNilOptions, key, &brightness);
  
  if (dErr == kIOReturnSuccess) {
    return brightness;
  } else {
    // TODO disable the slider for this screen
    return 1.0;
  }
}

@end
