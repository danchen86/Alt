//
//  AltViewController.m
//  Alt
//
//  Created by Dan Chen on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AltViewController.h"

@implementation AltViewController

@synthesize imagePicker = _imagePicker;
@synthesize imagePickerPopover = _imagePickerPopover;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {

}
 */



/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];	
}
*/
 
- (void)resetTopToolBar{
	[self.view bringSubviewToFront:topToolBar];
}

- (void)addGestureRecognizersToImage{
	imageViewer.userInteractionEnabled = YES;
	
	//Pinch for Scaling
	UIPinchGestureRecognizer *pinchGR = 
		[[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(scaleImage:)];
	pinchGR.delegate = self;
	[imageViewer addGestureRecognizer:pinchGR];
	[pinchGR release];
	
	//Rotation
	UIRotationGestureRecognizer *rotationGR = 
		[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateImage:)];
	rotationGR.delegate = self;
	[imageViewer addGestureRecognizer:rotationGR];
	[rotationGR release];
	
	//Pan for Moving image when scaled
	UIPanGestureRecognizer *panGR = 
		[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panImage:)];
	panGR.delegate = self;
	[imageViewer addGestureRecognizer:panGR];
	[panGR release];
}

- (void)scaleImage:(UIPinchGestureRecognizer *)gestureRecognizer {
	
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || 
		[gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        
		[gestureRecognizer view].transform = 
			CGAffineTransformScale([[gestureRecognizer view] transform], [gestureRecognizer scale], [gestureRecognizer scale]);
        [gestureRecognizer setScale:1];
    }
	
	[self resetTopToolBar];
}

- (void)rotateImage:(UIRotationGestureRecognizer *)gestureRecognizer {
	if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || 
		[gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        
		[gestureRecognizer view].transform = 
			CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
        [gestureRecognizer setRotation:0];
    }

	[self resetTopToolBar];
}

- (void)panImage:(UIPanGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || 
		[gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        
		CGPoint translation = [gestureRecognizer translationInView:[imageViewer superview]];
        
        [imageViewer setCenter:CGPointMake([imageViewer center].x + translation.x, [imageViewer center].y + translation.y)];
        [gestureRecognizer setTranslation:CGPointZero inView:[imageViewer superview]];
    }
	
	[self resetTopToolBar];
}




// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)imageSelected:(NSString *)image {
    if ([image compare:@"Image1"] == NSOrderedSame) {
		[imageViewer setImage:[UIImage imageNamed:@"image1.jpg"]];
		[self addGestureRecognizersToImage];
		[imageViewer setBackgroundColor:[UIColor blackColor]];
//    } else if ([image compare:@"Image2"] == NSOrderedSame) {
//		[imageViewer setImage:nil];
//    } else if ([image compare:@"Image3"] == NSOrderedSame){
//		[imageViewer setImage:nil];
//    }
	} else {
		[imageViewer setImage:nil];
		imageViewer.userInteractionEnabled = NO;
	}

    [self.imagePickerPopover dismissPopoverAnimated:YES];
}

- (IBAction)setImageButtonTapped:(id)sender {
    if (_imagePicker == nil) {
        self.imagePicker = [[[ImagePickerController alloc] 
							 initWithStyle:UITableViewStylePlain] autorelease];
        _imagePicker.delegate = self;
        self.imagePickerPopover = [[[UIPopoverController alloc] 
									initWithContentViewController:_imagePicker] autorelease];               
    }
    [self.imagePickerPopover presentPopoverFromBarButtonItem:sender 
									permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}




- (void)dealloc {
    [super dealloc];
	self.imagePicker = nil;
	self.imagePickerPopover = nil;
}

@end
