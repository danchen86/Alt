//
//  ImagePickerController.h
//  Alt
//
//  Created by Dan Chen on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "ImageTableController.h";

@protocol NavigationControllerDelegate
- (void)createImageMenu:(NSString *)type;
@end



@interface NavigationController : UITableViewController {
	NSMutableArray *_names;
	id<NavigationControllerDelegate> _delgate;
}

@property (nonatomic, retain) NSMutableArray *names;
@property (nonatomic, assign) id<NavigationControllerDelegate> delegate;


@end