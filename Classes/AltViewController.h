//
//  AltViewController.h
//  Alt
//
//  Created by Dan Chen on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImagePickerController.h"

@interface AltViewController : UIViewController <ImagePickerDelegate>{
	IBOutlet UIImageView *imageViewer;
	ImagePickerController *_imagePicker;
	UIPopoverController *_imagePickerPopover;

}

@property (nonatomic, retain) ImagePickerController *imagePicker;
@property (nonatomic, retain) UIPopoverController *imagePickerPopover;

- (IBAction)setImageButtonTapped:(id)sender;


@end

