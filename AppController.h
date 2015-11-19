//
//  AppController.h
//  DisplayBrightness
//
//  Created by Yannick Weiss on 15.12.09.
//  Copyright 2009 yannickweiss.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
	IBOutlet NSMenu *brightnessMenu;
	IBOutlet NSMenuItem *brightnessSliderItem;
}

- (float)getDisplayBrightness;
- (void)setDisplayBrightness:(float)brightness;
@end
