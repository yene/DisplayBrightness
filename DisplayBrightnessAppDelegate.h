//
//  DisplayBrightnessAppDelegate.h
//  DisplayBrightness
//
//  Created by Yannick Weiss on 15.12.09.
//  Copyright 2009 autoreleasepool.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DisplayBrightnessAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	IBOutlet NSMenu *brightnessMenu;
}

@property (assign) IBOutlet NSWindow *window;

@end
