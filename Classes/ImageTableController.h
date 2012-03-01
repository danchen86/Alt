//
//  ImageTableController.h
//  Alt
//
//  Created by Dan Chen on 2/29/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ImageTableDelegate
- (void)imageSelected:(NSString *)image;
@end

@interface ImageTableController : UITableViewController {
	NSMutableArray *_images;
	id<ImageTableDelegate> _delgate;

}
@property (nonatomic, retain) NSMutableArray *images;
@property (nonatomic, assign) id<ImageTableDelegate> delegate;

@end
