//
//  AltViewController.h
//  Alt
//
//  Created by Dan Chen on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavigationController.h"
#import "ImageTableController.h"
#import "DCMPix.h"

@interface AltViewController : UIViewController <UIGestureRecognizerDelegate, UIPopoverControllerDelegate, 
												NavigationControllerDelegate, ImageTableDelegate>{
	IBOutlet UIImageView *imageViewer;
	//IBOutlet UIToolbar *topToolBar;
	UIPopoverController *_navigationPopoverController;
	
	IBOutlet UINavigationBar *topNavBar;
	IBOutlet UITabBar *bottomTabBar;
	
	NSString *_type;
}

@property (nonatomic, retain) UIPopoverController *navigationPopoverController;

- (IBAction)setImageButtonTapped:(id)sender;


@end

