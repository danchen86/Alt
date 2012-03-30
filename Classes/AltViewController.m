//
//  AltViewController.m
//  Alt
//
//  Created by Dan Chen on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AltViewController.h"

@implementation AltViewController

//@synthesize imageNavigation = _imageNavigation;
//@synthesize imagePicker = _imagePicker;
//@synthesize imagePickerPopover = _imagePickerPopover;
@synthesize navigationPopoverController = _navigationPopoverController;


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
 

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)displayImage:(UIImage*) imageToDisplay {
	if( imageViewer != nil) {
		[imageViewer setImage:nil];
		[imageViewer release];
	}
	imageViewer = [[UIImageView alloc] initWithImage:imageToDisplay];
	[imageViewer setFrame:CGRectMake(0, 44, 768, 911)];
	[self.view addSubview:imageViewer];
	[imageToDisplay release];

}


- (void)addGestureRecognizersToImage{
	if (imageViewer != nil) {
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
		panGR.minimumNumberOfTouches = 1;
		panGR.maximumNumberOfTouches = 1;
		[imageViewer addGestureRecognizer:panGR];
		[panGR release];
		
		//Scrolling with two fingers
		UIPanGestureRecognizer *scrollGR = 
		[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(scrollImage:)];
		scrollGR.delegate = self;
		scrollGR.minimumNumberOfTouches = 2;
		scrollGR.maximumNumberOfTouches = 2;
		[imageViewer addGestureRecognizer:scrollGR];
		[scrollGR release];
		
	}
}

- (void)bringToolBarsToFront {
	[self.view bringSubviewToFront:topNavBar];
	[self.view bringSubviewToFront:bottomTabBar];
}

- (void)scaleImage:(UIPinchGestureRecognizer *)gestureRecognizer {
	
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || 
		[gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        
		[gestureRecognizer view].transform = 
			CGAffineTransformScale([[gestureRecognizer view] transform], [gestureRecognizer scale], [gestureRecognizer scale]);
        [gestureRecognizer setScale:1];
    }
	[self bringToolBarsToFront];
	
}

- (void)rotateImage:(UIRotationGestureRecognizer *)gestureRecognizer {
	
	if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || 
		[gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        
		[gestureRecognizer view].transform = 
			CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
		
		[gestureRecognizer setRotation:0];
    }
	[self bringToolBarsToFront];

}

- (void)panImage:(UIPanGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || 
		[gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        
		CGPoint translation = [gestureRecognizer translationInView:[imageViewer superview]];
        
        [imageViewer setCenter:CGPointMake([imageViewer center].x + translation.x, [imageViewer center].y + translation.y)];
        [gestureRecognizer setTranslation:CGPointZero inView:[imageViewer superview]];
    }

	[self bringToolBarsToFront];

}

- (void)scrollImage:(UIPanGestureRecognizer *)gestureRecognizer {
	//scroll images
}

- (void)createImageMenu:(NSString *)type {
	_type = type;
	ImageTableController *imageController = 
		[[ImageTableController alloc] initWithStyle:UITableViewStylePlain];
	
	if ([type compare:@"Abdomen"] == NSOrderedSame) {
		imageController.images = [NSMutableArray array];
		[imageController.images addObject:@"Front View"];
		[imageController.images addObject:@"Slice View"];
	} else if ([type compare:@"Test"] == NSOrderedSame) {
		imageController.images = [NSMutableArray array];
		[imageController.images addObject:@"Test"];
	}
	imageController.delegate = self;
	
	[(UINavigationController *)(self.navigationPopoverController.contentViewController)
		pushViewController:imageController animated:YES];
	
	[imageController release];
	[type release];
}

- (void)imageSelected:(NSString *)image {
	if([_type compare:@"Abdomen"] == NSOrderedSame) {
		
		if ([image compare:@"Front View"] == NSOrderedSame) {
			//[self displayImage:[UIImage imageNamed:@"abdomen.jpg"]];
			//DCMPix *dcmPix = [[DCMPix alloc] initWithContentsOfFile:@"abdomen_dcm.dcm"];
			//[imageViewer setImage:[UIImage imageNamed:@"abdomen.jpg"]];
			
			[self addGestureRecognizersToImage];
			
		} else if ([image compare:@"Slice View"] == NSOrderedSame) {
			[self displayImage:[UIImage imageNamed:@"abdomen_slice.jpg"]];
			[self addGestureRecognizersToImage];
		}
	} else {
		[imageViewer setImage:nil];
		imageViewer.userInteractionEnabled = NO;
	}
	
	[self.navigationPopoverController dismissPopoverAnimated:YES];
	[self bringToolBarsToFront];
}

- (IBAction)setImageButtonTapped:(id)sender {
	if (self.navigationPopoverController == nil) {
		NavigationController *navMenu = [[NavigationController alloc] initWithStyle:UITableViewStylePlain];
		navMenu.navigationItem.title = @"Types";
		navMenu.delegate = self;
		
		UINavigationController *navController =
		[[UINavigationController alloc] initWithRootViewController:navMenu];
		
		UIPopoverController *popover = 
		[[UIPopoverController alloc] initWithContentViewController:navController];
		
		//self.imageNavigation.delegate = self;
        self.navigationPopoverController = popover;
		self.navigationPopoverController.delegate = self;
		
		[navMenu release];
		[navController release];
		[popover release];
		
    } 
	
	if (self.navigationPopoverController.popoverVisible == true) {
		[self.navigationPopoverController dismissPopoverAnimated:YES];
	} else {
		[self.navigationPopoverController presentPopoverFromBarButtonItem:sender 
												 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
	
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



- (void)dealloc {
    [super dealloc];
	[self.navigationPopoverController release];
	[imageViewer release];
}

@end
