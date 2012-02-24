//
//  AltAppDelegate.h
//  Alt
//
//  Created by Dan Chen on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AltViewController;

@interface AltAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AltViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AltViewController *viewController;

@end

