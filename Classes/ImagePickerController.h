//
//  ImagePickerController.h
//  Alt
//
//  Created by Dan Chen on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

//#import <UIKit/UIKit.h>
@protocol ImagePickerDelegate
- (void)imageSelected:(NSString *)color;
@end



@interface ImagePickerController : UITableViewController {
	NSMutableArray *_images;
	id<ImagePickerDelegate> _delegate;
}

@property (nonatomic, retain) NSMutableArray *images;
@property (nonatomic, assign) id<ImagePickerDelegate> delegate;

@end