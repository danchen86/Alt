//
//  DCMPix.m
//  Alt
//
//  Created by Dan Chen on 3/27/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "DCMPix.h"
#import "DCMObject.h"
#import "DCMPixelDataAttribute.h"
#import "DCM.h"


@implementation DCMPix
//static NSMutableDictionary *cachedDCMFrameworkFiles = nil;
static NSConditionLock *purgeCacheLock = nil;
BOOL gUseShutter = NO;
BOOL gDisplayDICOMOverlays = YES;


@synthesize laterality;
@synthesize frameofReferenceUID;
@synthesize SOPClassUID;
@synthesize srcFile;
@synthesize echotime;
@synthesize flipAngle;

@synthesize isOriginDefined;
@synthesize originY;
@synthesize originX;
@synthesize originZ;
@synthesize pixelSpacingX;
@synthesize pixelSpacingY;
@synthesize repetitiontime;


- (void) dcmFrameworkLoad0x0018: (DCMObject*) dcmObject
{
	if( [dcmObject attributeValueWithName:@"PatientsWeight"]) patientsWeight = [[dcmObject attributeValueWithName:@"PatientsWeight"] floatValue];
	
	if( [dcmObject attributeValueWithName:@"SliceThickness"]) sliceThickness = [[dcmObject attributeValueWithName:@"SliceThickness"] floatValue];
	if( [dcmObject attributeValueWithName:@"SpacingBetweenSlices"]) spacingBetweenSlices = [[dcmObject attributeValueWithName:@"SpacingBetweenSlices"] floatValue];
	if( [dcmObject attributeValueWithName:@"RepetitionTime"])
	{
		[repetitiontime release];
		repetitiontime = [[dcmObject attributeValueWithName:@"RepetitionTime"] retain];
	}
	if( [dcmObject attributeValueWithName:@"EchoTime"])	
	{
		[echotime release];
		echotime = [[dcmObject attributeValueWithName:@"EchoTime"] retain];	
	}
	if( [dcmObject attributeValueWithName:@"FlipAngle"])
	{
		[flipAngle release];
		flipAngle = [[dcmObject attributeValueWithName:@"FlipAngle"] retain];
	}
	if( [dcmObject attributeValueWithName:@"ViewPosition"])
	{
		[viewPosition release];
		viewPosition = [[dcmObject attributeValueWithName:@"ViewPosition"] retain];
	}
	if( [dcmObject attributeValueWithName:@"PositionerPrimaryAngle"])
	{
		[positionerPrimaryAngle release];
		positionerPrimaryAngle = [[dcmObject attributeValueWithName:@"PositionerPrimaryAngle"] retain];
	}
	if( [dcmObject attributeValueWithName:@"PositionerSecondaryAngle"])
	{
		[positionerSecondaryAngle release];
		positionerSecondaryAngle = [[dcmObject attributeValueWithName:@"PositionerSecondaryAngle"] retain];
	}
	if( [dcmObject attributeValueWithName:@"PatientPosition"])
	{
		[patientPosition release];
		patientPosition = [[dcmObject attributeValueWithName:@"PatientPosition"] retain];
	}
	if( [dcmObject attributeValueWithName:@"RecommendedDisplayFrameRate"]) cineRate = [[dcmObject attributeValueWithName:@"RecommendedDisplayFrameRate"] floatValue]; 
	if( !cineRate && [dcmObject attributeValueWithName:@"CineRate"]) cineRate = [[dcmObject attributeValueWithName:@"CineRate"] floatValue]; 
	if (!cineRate && [dcmObject attributeValueWithName:@"FrameDelay"])
	{
		if( [[dcmObject attributeValueWithName:@"FrameDelay"] floatValue] > 0)
			cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameDelay"] floatValue];
	}
    if (!cineRate && [dcmObject attributeValueWithName:@"FrameTime"])
	{
		if( [[dcmObject attributeValueWithName:@"FrameTime"] floatValue] > 0)
			cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameTime"] floatValue];	
	}
	if (!cineRate && [dcmObject attributeValueWithName:@"FrameTimeVector"])
	{
		if( [[dcmObject attributeValueWithName:@"FrameTimeVector"] floatValue] > 0)
			cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameTimeVector"] floatValue];	
	}
	
	if ( gUseShutter)
	{
		if( [dcmObject attributeValueWithName:@"ShutterShape"])
		{
			NSArray *shutterArray = [dcmObject attributeArrayWithName:@"ShutterShape"];
			
			for( NSString *shutter in shutterArray)
			{
				if ( [shutter isEqualToString:@"RECTANGULAR"])
				{
					DCMPixShutterOnOff = YES;
					
					shutterRect_x = [[dcmObject attributeValueWithName:@"ShutterLeftVerticalEdge"] floatValue]; 
					shutterRect_w = [[dcmObject attributeValueWithName:@"ShutterRightVerticalEdge"] floatValue]  - shutterRect_x;
					shutterRect_y = [[dcmObject attributeValueWithName:@"ShutterUpperHorizontalEdge"] floatValue]; 
					shutterRect_h = [[dcmObject attributeValueWithName:@"ShutterLowerHorizontalEdge"] floatValue]  - shutterRect_y;
				}
				else if( [shutter isEqualToString:@"CIRCULAR"])
				{
					DCMPixShutterOnOff = YES;
					
					NSArray *centerArray = [dcmObject attributeArrayWithName:@"CenterofCircularShutter"];
					
					if( centerArray.count == 2)
					{
						shutterCircular_x = [[centerArray objectAtIndex:0] intValue];
						shutterCircular_y = [[centerArray objectAtIndex:1] intValue];
					}
					
					shutterCircular_radius = [[dcmObject attributeValueWithName:@"RadiusofCircularShutter"] floatValue];
				}
				else if( [shutter isEqualToString:@"POLYGONAL"])
				{
					DCMPixShutterOnOff = YES;
					
					NSArray *locArray = [dcmObject attributeArrayWithName:@"VerticesofthePolygonalShutter"];
					
					if( shutterPolygonal) free( shutterPolygonal);
					
					shutterPolygonalSize = 0;
					shutterPolygonal = malloc( [locArray count] * sizeof( CGPoint) / 2);
					for( unsigned int i = 0, x = 0; i < [locArray count]; i+=2, x++)
					{
						shutterPolygonal[ x].x = [[locArray objectAtIndex: i] intValue];
						shutterPolygonal[ x].y = [[locArray objectAtIndex: i+1] intValue];
						shutterPolygonalSize++;
					}
				}
				else NSLog( @"Shutter not supported: %@", shutter);
			}
		}
	}
}
//end dcmFrameworkLoad0x0018

- (void) dcmFrameworkLoad0x0020: (DCMObject*) dcmObject
{
	//orientation
	originX = 0;	originY = 0;	originZ = 0;
	NSArray *ipp = [dcmObject attributeArrayWithName:@"ImagePositionPatient"];
	if( ipp)
	{
		originX = [[ipp objectAtIndex:0] floatValue];
		originY = [[ipp objectAtIndex:1] floatValue];
		originZ = [[ipp objectAtIndex:2] floatValue];
		isOriginDefined = YES;
	}
	
	orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
	orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
	NSArray *iop = [dcmObject attributeArrayWithName:@"ImageOrientationPatient"];
	if( iop)
	{
		for ( int j = 0; j < iop.count; j++) 
			orientation[ j ] = [[iop objectAtIndex:j] floatValue];
	}
	
	if( [dcmObject attributeValueWithName:@"ImageLaterality"])
	{
		[laterality release];
		laterality = [[dcmObject attributeValueWithName:@"ImageLaterality"] retain];	
	}
	if( laterality == nil)
	{
		[laterality release];
		laterality = [[dcmObject attributeValueWithName:@"Laterality"] retain];	
	}
	
	self.frameofReferenceUID = [dcmObject attributeValueWithName: @"FrameofReferenceUID"];
}
//end dcmFrameworkLoad0x0020

- (void) dcmFrameworkLoad0x0028: (DCMObject*) dcmObject
{
	// Group 0x0028
	
	if( [dcmObject attributeValueWithName:@"PixelRepresentation"]) fIsSigned = [[dcmObject attributeValueWithName:@"PixelRepresentation"] intValue];
	if( [dcmObject attributeValueWithName:@"BitsAllocated"]) bitsAllocated = [[dcmObject attributeValueWithName:@"BitsAllocated"] intValue]; 
	
	bitsStored = [[dcmObject attributeValueWithName:@"BitsStored"] intValue];
	if( bitsStored == 8 && bitsAllocated == 16 && [[dcmObject attributeValueWithName:@"PhotometricInterpretation"] isEqualToString:@"RGB"])
		bitsAllocated = 8;
	
	if ([dcmObject attributeValueWithName:@"RescaleIntercept"]) offset = [[dcmObject attributeValueWithName:@"RescaleIntercept"] floatValue];
	if ([dcmObject attributeValueWithName:@"RescaleSlope"])
	{
		slope = [[dcmObject attributeValueWithName:@"RescaleSlope"] floatValue]; 
		if( slope == 0) slope = 1.0;
	}
	
	// image size
	if( [dcmObject attributeValueWithName:@"Rows"])
	{
		height = [[dcmObject attributeValueWithName:@"Rows"] intValue];
	}
	
	if( [dcmObject attributeValueWithName:@"Columns"])
	{
		width =  [[dcmObject attributeValueWithName:@"Columns"] intValue];
	}
	
//	if( savedHeightInDB != 0 && savedHeightInDB != height)
//	{
//		NSLog( @"******* [[imageObj valueForKey:@'height'] intValue] != height - %d versus %d", (int)savedHeightInDB, (int)height);
//		[imageObj setValue: [NSNumber numberWithInt: height] forKey: @"height"];
//		if( height > savedHeightInDB)
//			height = savedHeightInDB;
//	}
	
//	if( savedWidthInDB != 0 && savedWidthInDB != width)
//	{
//		NSLog( @"******* [[imageObj valueForKey:@'width'] intValue] != width - %d versus %d", (int)savedWidthInDB, (int)width);
//		[imageObj setValue: [NSNumber numberWithInt: width] forKey: @"width"];
//		if( width > savedWidthInDB)
//			width = savedWidthInDB;
//	}
	
	if( shutterRect_w == 0) shutterRect_w = width;
	if( shutterRect_h == 0) shutterRect_h = height;
	
	//window level & width
	if ([dcmObject attributeValueWithName:@"WindowCenter"] && isRGB == NO) savedWL = (int)[[dcmObject attributeValueWithName:@"WindowCenter"] floatValue];
	if ([dcmObject attributeValueWithName:@"WindowWidth"] && isRGB == NO) savedWW =  (int) [[dcmObject attributeValueWithName:@"WindowWidth"] floatValue];
	if(  savedWW < 0) savedWW =-savedWW;
	
	//planar configuration
	if( [dcmObject attributeValueWithName:@"PlanarConfiguration"])
		fPlanarConf = [[dcmObject attributeValueWithName:@"PlanarConfiguration"] intValue]; 
	
	//pixel Spacing
	if( pixelSpacingFromUltrasoundRegions == NO)
	{
		NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"PixelSpacing"];
		if(pixelSpacing.count >= 2)
		{
			pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
			pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
		}
		else if(pixelSpacing.count >= 1)
		{ 
			pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
			pixelSpacingX = [[pixelSpacing objectAtIndex:0] floatValue];
		}
		else
		{
			NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"ImagerPixelSpacing"];
			if(pixelSpacing.count >= 2)
			{
				pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
				pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
			}
			else if(pixelSpacing.count >= 1)
			{
				pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
				pixelSpacingX = [[pixelSpacing objectAtIndex:0] floatValue];
			}
		}
	}
	
	
//	DCMSequenceAttribute* seq = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"SequenceofUltrasoundRegions"];
//	
//	if (seq)
//	{
//		// US Regions		BOOL spacingFound = NO;
//		[usRegions release];
//        usRegions = [[NSMutableArray array] retain];
//        
//		for ( DCMObject *sequenceItem in seq.sequence)
//		{
//			/* US Regions --->
//			 if( spacingFound == NO)
//			 {
//			 int physicalUnitsX = 0;
//			 int physicalUnitsY = 0;
//			 int spatialFormat = 0;
//			 
//			 physicalUnitsX = [[sequenceItem attributeValueWithName:@"PhysicalUnitsXDirection"] intValue];
//			 physicalUnitsY = [[sequenceItem attributeValueWithName:@"PhysicalUnitsYDirection"] intValue];
//			 spatialFormat = [[sequenceItem attributeValueWithName:@"RegionSpatialFormat"] intValue];
//			 
//			 if( physicalUnitsX == 3 && physicalUnitsY == 3 && spatialFormat == 1)	// We want only cm !
//			 {
//			 double xxx = 0, yyy = 0;
//			 
//			 xxx = [[sequenceItem attributeValueWithName:@"PhysicalDeltaX"] doubleValue];
//			 yyy = [[sequenceItem attributeValueWithName:@"PhysicalDeltaY"] doubleValue];
//			 
//			 if( xxx && yyy)
//			 {
//			 pixelSpacingX = fabs( xxx) * 10.;	// These are in cm !
//			 pixelSpacingY = fabs( yyy) * 10.;
//			 spacingFound = YES;
//			 
//			 pixelSpacingFromUltrasoundRegions = YES;
//			 }
//			 }
//			 }
//			 <--- US Regions */
//			// US Regions --->
//#ifdef OSIRIX_VIEWER
//			
//            // Read US Region Calibration Attributes
//            DCMUSRegion *usRegion = [[[DCMUSRegion alloc] init] autorelease];
//            
//            [usRegion setRegionSpatialFormat:[[sequenceItem attributeValueWithName:@"RegionSpatialFormat"] intValue]];
//            [usRegion setRegionDataType: [[sequenceItem attributeValueWithName:@"RegionDataType"] intValue]];
//            [usRegion setRegionFlags: [[sequenceItem attributeValueWithName:@"RegionFlags"] intValue]];
//            [usRegion setRegionLocationMinX0: [[sequenceItem attributeValueWithName:@"RegionLocationMinX0"] intValue]];
//            [usRegion setRegionLocationMinY0: [[sequenceItem attributeValueWithName:@"RegionLocationMinY0"] intValue]];
//            [usRegion setRegionLocationMaxX1: [[sequenceItem attributeValueWithName:@"RegionLocationMaxX1"] intValue]];
//            [usRegion setRegionLocationMaxY1: [[sequenceItem attributeValueWithName:@"RegionLocationMaxY1"] intValue]];
//            [usRegion setReferencePixelX0: [[sequenceItem attributeValueWithName:@"ReferencePixelX0"] intValue]];
//            [usRegion setIsReferencePixelX0Present:([sequenceItem attributeValueWithName:@"ReferencePixelX0"] != nil)];
//            [usRegion setReferencePixelY0: [[sequenceItem attributeValueWithName:@"ReferencePixelY0"] intValue]];
//            [usRegion setIsReferencePixelY0Present:([sequenceItem attributeValueWithName:@"ReferencePixelY0"] != nil)];
//            [usRegion setPhysicalUnitsXDirection: [[sequenceItem attributeValueWithName:@"PhysicalUnitsXDirection"] intValue]];
//            [usRegion setPhysicalUnitsYDirection: [[sequenceItem attributeValueWithName:@"PhysicalUnitsYDirection"] intValue]];
//            [usRegion setRefPixelPhysicalValueX: [[sequenceItem attributeValueWithName:@"ReferencePixelPhysicalValueX"] doubleValue]];
//            [usRegion setRefPixelPhysicalValueY: [[sequenceItem attributeValueWithName:@"ReferencePixelPhysicalValueY"] doubleValue]];
//            [usRegion setPhysicalDeltaX: [[sequenceItem attributeValueWithName:@"PhysicalDeltaX"] doubleValue]];
//            [usRegion setPhysicalDeltaY: [[sequenceItem attributeValueWithName:@"PhysicalDeltaY"] doubleValue]];
//            [usRegion setDopplerCorrectionAngle: [[sequenceItem attributeValueWithName:@"DopplerCorrectionAngle"] doubleValue]];
//            
//            if ([usRegion physicalUnitsXDirection] == 3 && [usRegion physicalUnitsYDirection] == 3 && [usRegion regionSpatialFormat] == 1) {
//                // We want only cm, for 2D images
//                if ([usRegion physicalDeltaX] && [usRegion physicalDeltaY])
//                {
//                    pixelSpacingX = fabs([usRegion physicalDeltaX]) * 10.;	// These are in cm !
//                    pixelSpacingY = fabs([usRegion physicalDeltaY]) * 10.;
//                    pixelSpacingFromUltrasoundRegions = YES;
//                }
//            }
//            
//            // Adds current US Region Calibration Attributes to usRegions collection
//            [usRegions addObject:usRegion];
//            
//            //NSLog (@"dcmFrameworkLoad0x0028 - US REGION is [%@]", [usRegion toString]);
//#endif
//			// <--- US Regions
//        }
//	}

	
	//PixelAspectRatio
	if( pixelSpacingFromUltrasoundRegions == NO)
	{
		NSArray *par = [dcmObject attributeArrayWithName:@"PixelAspectRatio"];
		if ( par.count >= 2)
		{
			float ratiox = 1, ratioy = 1;
			ratiox = [[par objectAtIndex:0] floatValue];
			ratioy = [[par objectAtIndex:1] floatValue];
			
			if( ratioy != 0)
			{
				pixelRatio = ratiox / ratioy;
			}
		}
		else if( pixelSpacingX != pixelSpacingY)
		{
			if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
		}
	}
	
	//PhotoInterpret
	if ([[dcmObject attributeValueWithName:@"PhotometricInterpretation"] rangeOfString:@"PALETTE"].location != NSNotFound)
	{
		// palette conversions done by dcm Object
		isRGB = YES;
	}
}
//end dcmFrameworkLoad0x0028


-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d pixelCenter: (BOOL) pixelCenter
{
	if( pixelCenter)
	{
		x -= 0.5;
		y -= 0.5;
	}
	
	d[0] = originX + y*orientation[3]*pixelSpacingY + x*orientation[0]*pixelSpacingX;
	d[1] = originY + y*orientation[4]*pixelSpacingY + x*orientation[1]*pixelSpacingX;
	d[2] = originZ + y*orientation[5]*pixelSpacingY + x*orientation[2]*pixelSpacingX;
}

-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d
{
	[self convertPixX: x pixY: y toDICOMCoords: d pixelCenter: YES];
}


- (BOOL)loadDICOMDCMFramework
{
    // Memory test: DCMFramework requires a lot of memory...
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath: srcFile error: nil] fileSize];
    fileSize *= 1.5;
    
    void *memoryTest = malloc( fileSize);
    if( memoryTest == nil)
    {
        NSLog( @"------ loadDICOMDCMFramework memory test failed -> return");
        return NO;
    }
    free( memoryTest);
    
    /////////////////////////
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL returnValue = YES;
	DCMObject *dcmObject = 0L;
	
	if( purgeCacheLock == nil)
		purgeCacheLock = [[NSConditionLock alloc] initWithCondition: 0];
    
	[purgeCacheLock lock];
	[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]+1];
	
	//[PapyrusLock lock];
	
	@try
	{
//		if( [cachedDCMFrameworkFiles objectForKey: srcFile])
//		{
//			NSMutableDictionary *dic = [cachedDCMFrameworkFiles objectForKey: srcFile];
//			
//			dcmObject = [dic objectForKey: @"dcmObject"];
//			
//			if( retainedCacheGroup == nil)
//			{
//				[dic setValue: [NSNumber numberWithInt: [[dic objectForKey: @"count"] intValue]+1] forKey: @"count"];
//				retainedCacheGroup = dic;
//			}
//			else NSLog( @"******** DCMPix : retainedCacheGroup 3 != nil ! %@", srcFile);
//		}
//		else
//		{
			dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
			
//			if( dcmObject)
//			{
//				NSMutableDictionary *dic = [NSMutableDictionary dictionary];
//				
//				[dic setValue: dcmObject forKey: @"dcmObject"];
//				if( retainedCacheGroup == nil)
//				{
//					[dic setValue: [NSNumber numberWithInt: 1] forKey: @"count"];
//					retainedCacheGroup = dic;
//				}
//				else NSLog( @"******** DCMPix : retainedCacheGroup 4 != nil ! %@", srcFile);
//				
//				[cachedDCMFrameworkFiles setObject: dic forKey: srcFile];
//			}
//		}
	}
	@catch (NSException *e)
	{
		NSLog( @"******** loadDICOMDCMFramework exception : %@", e);
		dcmObject = nil;
	}
	
//	[PapyrusLock unlock];
	
	if(dcmObject == nil)
	{
		NSLog( @"******** loadDICOMDCMFramework - no DCMObject at srcFile address, nothing to do");
		[purgeCacheLock lock];
		[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
		[pool release];
		return NO;
	}
	
	self.SOPClassUID = [dcmObject attributeValueWithName:@"SOPClassUID"];
	
	//-----------------------common----------------------------------------------------------	
	
	short maxFrame = 1;
	short imageNb = frameNo;
	
#pragma mark *pdf
//	if ([SOPClassUID isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
//	{
//		NSData *pdfData = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
//		
//		NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData: pdfData];	
//		[rep setCurrentPage: frameNo];
//		
//		NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
//		[pdfImage addRepresentation: rep];
//		
//		NSSize newSize;
//		
//		newSize.width = ceil( [rep bounds].size.width * 1.5);		// Increase PDF resolution to 72 * X DPI !
//		newSize.height = ceil( [rep bounds].size.height * 1.5);		// KEEP THIS VALUE IN SYNC WITH DICOMFILE.M
//		
//		[pdfImage setScalesWhenResized:YES];
//		[pdfImage setSize: newSize];
//		
//		[self getDataFromNSImage: pdfImage];
//		
//#ifdef OSIRIX_VIEWER
//        [self loadCustomImageAnnotationsPapyLink:-1 DCMLink:dcmObject];
//#endif
//		
//		[purgeCacheLock lock];
//		[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
//		[pool release];
//		return YES;
//	} // end encapsulatedPDF
//	else if( [SOPClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.88"]) // DICOM SR
//	{
//#ifdef OSIRIX_VIEWER
//#ifndef OSIRIX_LIGHT
//		
//		@try
//		{
//			if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/dicomsr_osirix/"] == NO)
//				[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/dicomsr_osirix/" attributes: nil];
//			
//			NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [srcFile lastPathComponent]] stringByAppendingPathExtension: @"xml"];
//			
//			if( [[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
//			{
//				NSTask *aTask = [[[NSTask alloc] init] autorelease];		
//				[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
//				[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
//				[aTask setArguments: [NSArray arrayWithObjects: @"+X1", @"--unknown-relationship", @"--ignore-constraints", @"--ignore-item-errors", @"--skip-invalid-items",srcFile, htmlpath, nil]];		
//				[aTask launch];
//				[aTask waitUntilExit];		
//				[aTask interrupt];
//			}
//			
//			if( [[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
//			{
//				NSTask *aTask = [[[NSTask alloc] init] autorelease];
//				[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
//				[aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];		
//				[aTask launch];
//				[aTask waitUntilExit];		
//				[aTask interrupt];
//			}
//			
//			NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData: [NSData dataWithContentsOfFile: [htmlpath stringByAppendingPathExtension: @"pdf"]]];
//			
//			[rep setCurrentPage: frameNo];	
//			
//			NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
//			[pdfImage addRepresentation: rep];
//			
//			NSSize newSize;
//			
//			newSize.width = ceil( [rep bounds].size.width * 1.5);		// Increase PDF resolution to 72 * X DPI !
//			newSize.height = ceil( [rep bounds].size.height * 1.5);		// KEEP THIS VALUE IN SYNC WITH DICOMFILE.M
//			
//			[pdfImage setScalesWhenResized:YES];
//			[pdfImage setSize: newSize];
//			
//			[self getDataFromNSImage: pdfImage];
//			
//			[self loadCustomImageAnnotationsPapyLink:-1 DCMLink:dcmObject];
//			
//			[purgeCacheLock lock];
//			[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
//			[pool release];
//			return YES;
//		}
//		@catch (NSException * e)
//		{
//			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
//		}
//#else
//		[self getDataFromNSImage: [NSImage imageNamed: @"NSIconViewTemplate"]];
//#endif
//#else
//		[self getDataFromNSImage: [NSImage imageNamed: @"NSIconViewTemplate"]];
//#endif
//	}
//	else if ( [DCMAbstractSyntaxUID isNonImageStorage: SOPClassUID])
//	{
//		if( fExternalOwnedImage)
//			fImage = fExternalOwnedImage;
//		else
			fImage = malloc( 128 * 128 * 4);
		
		height = 128;
		width = 128;
		isRGB = NO;
		
		for( int i = 0; i < 128*128; i++)
			fImage[ i ] = i%2;
		
#ifdef OSIRIX_VIEWER
        [self loadCustomImageAnnotationsPapyLink:-1 DCMLink:dcmObject];
#endif
		
		[purgeCacheLock lock];
		[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
		[pool release];
		return YES;
//	}
	
	@try
	{
		pixelSpacingX = 0;
		pixelSpacingY = 0;
		offset = 0.0;
		slope = 1.0;
		
		[self dcmFrameworkLoad0x0018: dcmObject];
		[self dcmFrameworkLoad0x0020: dcmObject];
		[self dcmFrameworkLoad0x0028: dcmObject];
		
#pragma mark *MR/CT functional multiframe
		
		// Is it a new MR/CT multi-frame exam?
//		DCMSequenceAttribute *sharedFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"SharedFunctionalGroupsSequence"];
//		if (sharedFunctionalGroupsSequence)
//		{
//			for ( DCMObject *sequenceItem in sharedFunctionalGroupsSequence.sequence)
//			{
//				DCMSequenceAttribute *MRTimingAndRelatedParametersSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"MRTimingAndRelatedParametersSequence"];
//				DCMObject *MRTimingAndRelatedParametersObject = [[MRTimingAndRelatedParametersSequence sequence] objectAtIndex:0];
//				if( MRTimingAndRelatedParametersObject)
//					[self dcmFrameworkLoad0x0020: MRTimingAndRelatedParametersObject];
//				
//				DCMSequenceAttribute *planeOrientationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PlaneOrientationSequence"];
//				DCMObject *planeOrientationObject = [[planeOrientationSequence sequence] objectAtIndex:0];
//				if( planeOrientationObject)
//					[self dcmFrameworkLoad0x0020: planeOrientationObject];
//				
//				DCMSequenceAttribute *pixelMeasureSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelMeasuresSequence"];
//				DCMObject *pixelMeasureObject = [[pixelMeasureSequence sequence] objectAtIndex:0];
//				if( pixelMeasureObject)
//					[self dcmFrameworkLoad0x0018: pixelMeasureObject];
//				if( pixelMeasureObject)
//					[self dcmFrameworkLoad0x0028: pixelMeasureObject];
//				
//				DCMSequenceAttribute *pixelTransformationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelValueTransformationSequence"];
//				DCMObject *pixelTransformationSequenceObject = [[pixelTransformationSequence sequence] objectAtIndex:0];
//				if( pixelTransformationSequenceObject)
//					[self dcmFrameworkLoad0x0028: pixelTransformationSequenceObject];
//			}
//		}
		
		
#pragma mark *per frame
		
		// ****** ****** ****** ************************************************************************
		// PER FRAME
		// ****** ****** ****** ************************************************************************
		
		//long frameCount = 0;
//		DCMSequenceAttribute *perFrameFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"Per-frameFunctionalGroupsSequence"];
//		
//		//NSLog(@"perFrameFunctionalGroupsSequence: %@", [perFrameFunctionalGroupsSequence description]);
//		if( perFrameFunctionalGroupsSequence)
//		{
//			if( perFrameFunctionalGroupsSequence.sequence.count > imageNb && imageNb >= 0)
//			{
//				DCMObject *sequenceItem = [[perFrameFunctionalGroupsSequence sequence] objectAtIndex:imageNb];
//				if( sequenceItem)
//				{
//					if( [sequenceItem attributeArrayWithName:@"MREchoSequence"])
//					{
//						DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"MREchoSequence"];
//						DCMObject *object = [[seq sequence] objectAtIndex: 0];
//						if( object)
//							[self dcmFrameworkLoad0x0018: object];
//					}
//					
//					if( [sequenceItem attributeArrayWithName:@"PixelMeasuresSequence"])
//					{
//						DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"PixelMeasuresSequence"];
//						DCMObject *object = [[seq sequence] objectAtIndex: 0];
//						if( object)
//							[self dcmFrameworkLoad0x0018: object];
//						if( object)
//							[self dcmFrameworkLoad0x0028: object];
//					}
//					
//					if( [sequenceItem attributeArrayWithName:@"PlanePositionSequence"])
//					{
//						DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"PlanePositionSequence"];
//						DCMObject *object = [[seq sequence] objectAtIndex: 0];
//						
//						if( object)
//							[self dcmFrameworkLoad0x0020: object];
//						if( object)
//							[self dcmFrameworkLoad0x0028: object];
//					}
//                    
//					if( [sequenceItem attributeArrayWithName:@"PlaneOrientationSequence"])
//					{
//						DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"PlaneOrientationSequence"];
//						DCMObject *object = [[seq sequence] objectAtIndex: 0];
//						if( object)
//							[self dcmFrameworkLoad0x0020: object];
//					}
//                    
//                    if( [sequenceItem attributeArrayWithName:@"PixelValueTransformationSequence"])
//					{
//						DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"PixelValueTransformationSequence"];
//						DCMObject *object = [[seq sequence] objectAtIndex: 0];
//						if( object)
//							[self dcmFrameworkLoad0x0028: object];
//					}
//				}
//			}
//			else
//			{
//				NSLog(@"No Frame %d in preFrameFunctionalGroupsSequence", imageNb);
//			}		
//		}
		
#pragma mark *tag group 6000
		
//		if( [dcmObject attributeValueWithName: @"OverlayRows"])
//		{
//			@try
//			{
//				oRows = [[dcmObject attributeValueWithName: @"OverlayRows"] intValue];
//				oColumns = [[dcmObject attributeValueWithName: @"OverlayColumns"] intValue];
//				oType = [[dcmObject attributeValueWithName: @"OverlayType"] characterAtIndex: 0];
//				
//				oOrigin[ 0] = [[[dcmObject attributeArrayWithName: @"OverlayOrigin"] objectAtIndex: 0] intValue];
//				oOrigin[ 1] = [[[dcmObject attributeArrayWithName: @"OverlayOrigin"] objectAtIndex: 1] intValue];
//				
//				oBits = [[dcmObject attributeValueWithName: @"OverlayBitsAllocated"] intValue];
//				
//				oBitPosition = [[dcmObject attributeValueWithName: @"OverlayBitPosition"] intValue];
//				
//				NSData	*data = [dcmObject attributeValueWithName: @"OverlayData"];
//				
//				if (data && oBits == 1 && oRows == height && oColumns == width && oType == 'G' && oBitPosition == 0 && oOrigin[ 0] == 1 && oOrigin[ 1] == 1)
//				{
//					if( oData) free( oData);
//					oData = calloc( oRows*oColumns, 1);
//					if( oData)
//					{
//						register unsigned short *pixels = (unsigned short*) [data bytes];
//						register unsigned char *oD = oData;
//						register char mask = 1;
//						register long t = oColumns*oRows/16;
//						
//						while( t-->0)
//						{
//							register unsigned short	octet = *pixels++;
//							register int x = 16;
//							while( x-->0)
//							{
//								char v = octet & mask ? 1 : 0;
//								octet = octet >> 1;
//								
//								if( v)
//									*oD = 0xFF;
//								
//								oD++;
//							}
//						}
//					}
//				}
//			}
//			@catch (NSException *e)
//			{
//				NSLog( @"***** exception in overlays DCMFramework : %s: %@", __PRETTY_FUNCTION__, e);
//			}
//		}
		
#pragma mark *SUV	
		
		// Get values needed for SUV calcs:
		if( [dcmObject attributeValueWithName:@"PatientsWeight"]) patientsWeight = [[dcmObject attributeValueWithName:@"PatientsWeight"] floatValue];
		else patientsWeight = 0.0;
		
		[units release];
		units = [[dcmObject attributeValueWithName:@"Units"] retain];
		
		[decayCorrection release];
		decayCorrection = [[dcmObject attributeValueWithName:@"DecayCorrection"] retain];
		
        //	if( [dcmObject attributeValueWithName:@"DecayFactor"])
        //		decayFactor = [[dcmObject attributeValueWithName:@"DecayFactor"] floatValue];
		
		decayFactor = 1.0;
		
//		DCMSequenceAttribute *radiopharmaceuticalInformationSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"RadiopharmaceuticalInformationSequence"];
//		if( radiopharmaceuticalInformationSequence && radiopharmaceuticalInformationSequence.sequence.count > 0)
//		{
//			DCMObject *radionuclideTotalDoseObject = [radiopharmaceuticalInformationSequence.sequence objectAtIndex:0];
//			radionuclideTotalDose = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideTotalDose"] floatValue];
//			halflife = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideHalfLife"] floatValue];
//			
//			NSArray *priority = nil;
//			
//			if( gSUVAcquisitionTimeField == 0) // Prefer SeriesTime
//				priority = [NSArray arrayWithObjects: @"SeriesDate", @"SeriesTime", @"AcquisitionDate", @"AcquisitionTime", @"ContentDate", @"ContentTime", @"StudyDate", @"StudyTime", nil];
//			
//			if( gSUVAcquisitionTimeField == 1) // Prefer AcquisitionTime
//				priority = [NSArray arrayWithObjects: @"AcquisitionDate", @"AcquisitionTime", @"SeriesDate", @"SeriesTime", @"ContentDate", @"ContentTime", @"StudyDate", @"StudyTime", nil];
//			
//			if( gSUVAcquisitionTimeField == 2) // Prefer ContentTime
//				priority = [NSArray arrayWithObjects: @"ContentDate", @"ContentTime", @"SeriesDate", @"SeriesTime", @"AcquisitionDate", @"AcquisitionTime", @"StudyDate", @"StudyTime", nil];
//			
//			if( gSUVAcquisitionTimeField == 3) // Prefer StudyTime
//				priority = [NSArray arrayWithObjects: @"StudyDate", @"StudyTime", @"SeriesDate", @"SeriesTime", @"AcquisitionDate", @"AcquisitionTime", @"ContentDate", @"ContentTime", nil];
//			
//			NSString *preferredTime = nil;
//			NSString *preferredDate = nil;
//			
//			for( int v = 0; v < priority.count;)
//			{
//				NSString *value;
//				
//				if( preferredDate == nil && (value = [[dcmObject attributeValueWithName: [priority objectAtIndex: v]] dateString])) preferredDate = value;
//				v++;
//				
//				if( preferredTime == nil && (value = [[dcmObject attributeValueWithName: [priority objectAtIndex: v]] timeString])) preferredTime = value;
//				v++;
//			}
//			
//			NSString *radioTime = [[radionuclideTotalDoseObject attributeValueWithName:@"RadiopharmaceuticalStartTime"] timeString];
//			
//			if( preferredDate && preferredTime && radioTime)
//			{
//				if( [preferredTime length] >= 6)
//				{
//					radiopharmaceuticalStartTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:radioTime] calendarFormat:@"%Y%m%d%H%M%S"];
//					acquisitionTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:preferredTime] calendarFormat:@"%Y%m%d%H%M%S"];
//				}
//				else
//				{
//					radiopharmaceuticalStartTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:radioTime] calendarFormat:@"%Y%m%d%H%M"];
//					acquisitionTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:preferredTime] calendarFormat:@"%Y%m%d%H%M"];
//				}
//			}
//            
//			[self computeTotalDoseCorrected];
//		}
//		
//		DCMSequenceAttribute *detectorInformationSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"DetectorInformationSequence"];
//		if( detectorInformationSequence && detectorInformationSequence.sequence.count > 0)
//		{
//			DCMObject *detectorInformation = [detectorInformationSequence.sequence objectAtIndex:0];
//			
//			NSArray *ipp = [detectorInformation attributeArrayWithName:@"ImagePositionPatient"];
//			if( ipp)
//			{
//				originX = [[ipp objectAtIndex:0] floatValue];
//				originY = [[ipp objectAtIndex:1] floatValue];
//				originZ = [[ipp objectAtIndex:2] floatValue];
//				isOriginDefined = YES;
//			}
//			
//			if( spacingBetweenSlices)
//				originZ += frameNo * spacingBetweenSlices;
//			else
//				originZ += frameNo * sliceThickness;
//            
//			orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
//			orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
//			
//			NSArray *iop = [detectorInformation attributeArrayWithName:@"ImageOrientationPatient"];
//			if( iop)
//			{
//				BOOL equalZero = YES;
//				
//				for ( int j = 0; j < iop.count; j++) 
//					if( [[iop objectAtIndex:j] floatValue] != 0)
//						equalZero = NO;
//				
//				if( equalZero == NO)
//				{
//					for ( int j = 0; j < iop.count; j++) 
//						orientation[ j ] = [[iop objectAtIndex:j] floatValue];
//				}
//				else // doesnt the root Image Orientation contains valid data? if not use the normal vector
//				{
//					equalZero = YES;
//					for ( int j = 0; j < 6; j++)
//						if( orientation[ j] != 0)
//							equalZero = NO;
//					
//					if( equalZero)
//					{
//						orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0;
//						orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
//					}
//				}
//			}
//		}
//		
//		if( [dcmObject attributeValueForKey: @"7053,1000"])
//		{
//			@try
//			{
//				philipsFactor = [[dcmObject attributeValueForKey: @"7053,1000"] floatValue];
//			}
//			@catch ( NSException *e)
//			{
//				NSLog( @"philipsFactor exception");
//				NSLog( @"%@", [e description]);
//			}
//			//NSLog( @"philipsFactor = %f", philipsFactor);
//		}
//		
		// End SUV		
		
#pragma mark *compute normal vector				
		// Compute normal vector
		
		orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
		orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
		orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
		
		float centerPix[ 3];
		[self convertPixX: width/2 pixY: height/2 toDICOMCoords: centerPix];
		
		if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
			sliceLocation = centerPix[ 0];
		
		if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
			sliceLocation = centerPix[ 1];
		
		if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
			sliceLocation = centerPix[ 2];
		
		
#pragma mark READ PIXEL DATA		
        
		maxFrame = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
		if( maxFrame == 0) maxFrame = 1;
		if( pixArray == nil) maxFrame = 1;
		//pixelAttr contains the whole PixelData attribute of every frames. Hence needs to be before the loop
		if ([dcmObject attributeValueWithName:@"PixelData"])
		{
			DCMPixelDataAttribute *pixelAttr = (DCMPixelDataAttribute *)[dcmObject attributeWithName:@"PixelData"];
            
			//=====================================================================
			
#pragma mark *loading a frame
			
			if ( [[dcmObject attributeValueWithName:@"Modality"] isEqualToString: @"RTDOSE"])
			{  // Set Z value for each frame
				NSArray *gridFrameOffsetArray = [dcmObject attributeArrayWithName: @"GridFrameOffsetVector"];  //List of Z values
				originZ += [[gridFrameOffsetArray objectAtIndex: imageNb] floatValue];
				if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
				{
					sliceLocation = originX;
				}
				
				if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
				{
					sliceLocation = originY;
				}
				
				if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
				{
					sliceLocation = originZ;
				}	
			}
			
			if( gUseShutter && imageNb != frameNo && maxFrame > 1)
			{
				self->shutterRect_x = shutterRect_x;
				self->shutterRect_y = shutterRect_y;
				self->shutterRect_w = shutterRect_w;
				self->shutterRect_h = shutterRect_h;
				
				self->shutterCircular_x = shutterCircular_x;
				self->shutterCircular_y = shutterCircular_y;
				self->shutterCircular_radius = shutterCircular_radius;
				
				if( shutterPolygonalSize)
				{
					self->shutterPolygonalSize = shutterPolygonalSize;
					self->shutterPolygonal = malloc( shutterPolygonalSize * sizeof( CGPoint));
					memcpy( self->shutterPolygonal, shutterPolygonal, shutterPolygonalSize * sizeof( CGPoint));
				}
				
				self->DCMPixShutterOnOff = DCMPixShutterOnOff;
			}
			
			//get PixelData
			short *oImage = nil;
			NSData *pixData = [pixelAttr decodeFrameAtIndex:imageNb];
			if( [pixData length] > 0)
			{
				oImage =  malloc( [pixData length]);	//pointer to a memory zone where each pixel of the data has a short value reserved
				if( oImage)
					[pixData getBytes:oImage];
                else
                    NSLog( @"----- Major memory problems 1...");
			}
			
			if( oImage == nil) //there was no data for this frame -> create empty image
			{
				//NSLog(@"image size: %d", ( height * width * 2));
				oImage = malloc( height * width * 2);
				if( oImage)
				{
                    long yo = 0;
                    for( unsigned long i = 0 ; i < height * width; i++)
                    {
                        oImage[ i] = yo++;
                        if( yo>= width) yo = 0;
                    }
                }
                else
                    NSLog( @"----- Major memory problems 2...");
			}
			
			//-----------------------frame data already loaded in (short) oImage --------------
			
			isRGB = NO;
			inverseVal = NO;
			
			NSString *colorspace = [dcmObject attributeValueWithName:@"PhotometricInterpretation"];		
			if ([colorspace rangeOfString:@"MONOCHROME1"].location != NSNotFound)
			{
				if( [[dcmObject attributeValueWithName:@"Modality"] isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpacityTableNM"] == YES && [[dcmObject attributeValueWithName:@"Modality"] isEqualToString:@"NM"] == YES))
				{
					
				}
				else
					inverseVal = YES; savedWL = -savedWL;
			}
			/*else if ( [colorspace hasPrefix:@"MONOCHROME2"])	{inverseVal = NO; savedWL = savedWL;} */
			if ( [colorspace hasPrefix:@"YBR"]) isRGB = YES;		
			if ( [colorspace hasPrefix:@"PALETTE"])	{ bitsAllocated = 8; isRGB = YES; NSLog(@"Palette depth conveted to 8 bit");}
			if ([colorspace rangeOfString:@"RGB"].location != NSNotFound) isRGB = YES;			
			/******** dcm Object will do this *******convertYbrToRgb -> planar is converted***/		
			if ([colorspace rangeOfString:@"YBR"].location != NSNotFound)
			{
				fPlanarConf = 0;
				isRGB = YES;
			}
			
			if (isRGB == YES)
			{
				unsigned char   *ptr, *tmpImage;
				int loop = (int) height * (int) width;
				tmpImage = malloc (loop * 4L);
				ptr = tmpImage;
				
				if( bitsAllocated > 8)
				{
					if( [pixData length] < height*width*2*3)
					{
						NSLog( @"************* [pixData length] < height*width*2*3");
						loop = [pixData length]/6;
					}
					
					// RGB_FFF
					unsigned short   *bufPtr;
					bufPtr = (unsigned short*) oImage;
					while( loop-- > 0)
					{		//unsigned short=16 bit, then I suppose A should be 65535
						*ptr++	= 255;			//ptr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
					}
				}
				else
				{
					if( [pixData length] < height*width*3)
					{
						NSLog( @"************* [pixData length] < height*width*3");
						loop = [pixData length]/3;
					}
					
					// RGB_888
					unsigned char   *bufPtr;
					bufPtr = (unsigned char*) oImage;
					
					while( loop-- > 0)
					{
						*ptr++	= 255;			//ptr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
					}
					
				}
				free(oImage);
				oImage = (short*) tmpImage;
			}
			else if( bitsAllocated == 8)
			{
				// Planar 8
				//-> 16 bits image
				unsigned char   *bufPtr;
				short			*ptr, *tmpImage;
				int			loop, totSize;
				
				totSize = (int) ((int) height * (int) width * 2L);
				tmpImage = malloc( totSize);
				
				bufPtr = (unsigned char*) oImage;
				ptr    = tmpImage;
				
				loop = totSize/2;
				
				if( [pixData length] < loop)
				{
					NSLog( @"************* [pixData length] < height * width");
					loop = [pixData length];
				}
				
				while( loop-- > 0)
				{
					*ptr++ = *bufPtr++;
				}
				free(oImage);
				oImage =  (short*) tmpImage;
			}
			
			//***********
			
			if( isRGB)
			{
				if( fExternalOwnedImage)
				{
					fImage = fExternalOwnedImage;
					memcpy( fImage, oImage, width*height*sizeof(float));
					free(oImage);
				}
				else fImage = (float*) oImage;
				oImage = nil;
				
				if( oData && gDisplayDICOMOverlays)
				{
					unsigned char	*rgbData = (unsigned char*) fImage;
					
					for( int y = 0; y < oRows; y++)
					{
						for( int x = 0; x < oColumns; x++)
						{
							if( oData[ y * oColumns + x])
							{
								rgbData[ y * width*4 + x*4 + 1] = 0xFF;
								rgbData[ y * width*4 + x*4 + 2] = 0xFF;
								rgbData[ y * width*4 + x*4 + 3] = 0xFF;
							}
						}
					}
				}
			}
			else
			{
				if( bitsAllocated == 32) // 32-bit float or 32-bit integers
				{
					if( fExternalOwnedImage)
						fImage = fExternalOwnedImage;
					else
						fImage = malloc(width*height*sizeof(float) + 100);
					
					if( fImage)
					{
						memcpy( fImage, oImage, height * width * sizeof( float));
						
						if( slope != 1.0 || offset != 0 || [[NSUserDefaults standardUserDefaults] boolForKey: @"32bitDICOMAreAlwaysIntegers"]) 
						{
							unsigned int *usint = (unsigned int*) oImage;
							int *sint = (int*) oImage;
							float *tDestF = fImage;
							double dOffset = offset, dSlope = slope;
							
							if( fIsSigned > 0)
							{
								unsigned long x = height * width;
								while( x-- > 0)
									*tDestF++ = ((double) (*sint++)) * dSlope + dOffset;
							}
							else
							{
								unsigned long x = height * width;
								while( x-- > 0)
									*tDestF++ = ((double) (*usint++)) * dSlope + dOffset;
							}
						}
					}
					else
						NSLog( @"*** Not enough memory - malloc failed");
                    
					free(oImage);
					oImage = nil;
				}
				else
				{
					vImage_Buffer src16, dstf;
					dstf.height = src16.height = height;
					dstf.width = src16.width = width;
					src16.rowBytes = width*2;
					dstf.rowBytes = width*sizeof(float);
					
					src16.data = oImage;
					
					if( fExternalOwnedImage)
						fImage = fExternalOwnedImage;
					else
						fImage = malloc(width*height*sizeof(float) + 100);
					
					dstf.data = fImage;
					
					if( dstf.data)
					{
						if( bitsAllocated == 16 && [pixData length] < height*width*2)
						{
							NSLog( @"************* [pixData length] < height * width");
							
							if( [pixData length] == height*width) // 8 bits??
							{
								NSLog( @"************* [[pixData length] == height*width : 8 bits? but declared as 16 bits...");
								
								unsigned long x = height * width;
								float *tDestF = (float*) dstf.data;
								unsigned char *oChar = (unsigned char*) oImage;
								while( x-- > 0)
									*tDestF++ = *oChar++;
							}
							else
								memset( dstf.data, 0, width*height*sizeof(float));
						}
						else
						{
							if( fIsSigned > 0)
								vImageConvert_16SToF( &src16, &dstf, offset, slope, 0);
							else
								vImageConvert_16UToF( &src16, &dstf, offset, slope, 0);
						}
						
						if( inverseVal)
						{
							float neg = -1;
							vDSP_vsmul( fImage, 1, &neg, fImage, 1, height * width);
						}
					}
					else NSLog( @"*** Not enough memory - malloc failed");
					
					free(oImage);
					oImage = nil;
				}
				
				if( oData && gDisplayDICOMOverlays)
				{
					float maxValue = 0;
					
					if( inverseVal)
						maxValue = -offset;
					else
					{
						maxValue = pow( 2, bitsStored);
						maxValue *= slope;
						maxValue += offset;
					}
					
					if( oColumns == width)
					{
						register unsigned long x = oRows * oColumns;
						register unsigned char *d = oData;
						register float *ffI = fImage;
						
						while( x-- > 0)
						{
							if( *d++)
								*ffI = maxValue;
							ffI++;
						}
					}
					else
					{
						NSLog( @"-- oColumns != width");
						
						for( int y = 0; y < oRows; y++)
						{
							for( int x = 0; x < oColumns; x++)
							{
								if( oData[ y * oColumns + x]) fImage[ y * width + x] = maxValue;
							}
						}
						
					}
				}
			}
			
			wl = 0;
			ww = 0; //Computed later, only if needed
			
			if( savedWW != 0)
			{
				wl = savedWL;
				ww = savedWW;
			}
			
#pragma mark *after loading a frame
			
		}//end of if ([dcmObject attributeValueWithName:@"PixelData"])
        
		if( pixelSpacingY != 0)
		{
			if( fabs(pixelSpacingX) / fabs(pixelSpacingY) > 10000 || fabs(pixelSpacingX) / fabs(pixelSpacingY) < 0.0001)
			{
				pixelSpacingX = 1;
				pixelSpacingY = 1;
			}
		}
		
		if( pixelSpacingX < 0) pixelSpacingX = -pixelSpacingX;
		if( pixelSpacingY < 0) pixelSpacingY = -pixelSpacingY;
		if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
		
#ifdef OSIRIX_VIEWER
        [self loadCustomImageAnnotationsPapyLink:-1 DCMLink:dcmObject];
#endif
	}
	@catch (NSException *e)
	{
		NSLog( @"******** loadDICOMDCMFramework exception 2: %@", e);
		returnValue = NO;
	}
	
	[purgeCacheLock lock];
	[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
	[pool release];
	
	return returnValue;
}

//loadDICOMDCMFramework

- (BOOL) isDICOMFile:(NSString *) file
{
	BOOL readable = YES;
	
	if( imageObj)
	{
		if( [[imageObj valueForKey:@"fileType"] hasPrefix:@"DICOM"] == NO) readable = NO;
	}
	else
	{
		//readable = [DicomFile isDICOMFile: file];
		readable = NO;

    }
	
    return readable;
}


- (void) CheckLoadIn
{
//	BOOL USECUSTOMTIFF = NO;
	
	if( fImage == nil)
	{
		BOOL success = NO;
		short *oImage = nil;
		
		needToCompute8bitRepresentation = YES;
		
		//if( runOsiriXInProtectedMode) return;
		
		if( srcFile == nil) return;
		
		if( isBonjour)
		{
#ifdef OSIRIX_VIEWER
			// LOAD THE FILE FROM BONJOUR SHARED DATABASE
			
			[srcFile release];
			srcFile = nil;
			srcFile = [[BrowserController currentBrowser] getLocalDCMPath: imageObj :0];
			[srcFile retain];
			
			if( srcFile == nil)
				return;
#endif
		}
		
		if( [self isDICOMFile: srcFile])
		{
			// PLEASE, KEEP BOTH FUNCTIONS FOR TESTING PURPOSE. THANKS
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			@try
			{

#ifndef OSIRIX_LIGHT

					success = [self loadDICOMDCMFramework];
					

#endif
				
//				if( [[imageObj valueForKey: @"numberOfFrames"] intValue] <= 1)
//					[self clearCachedPapyGroups];
			}
			
			@catch ( NSException *e)
			{
				NSLog( @"CheckLoadIn Exception");
				NSLog( @"%@", [e description]);
				NSLog( @"Exception for this file: %@", srcFile);
				success = NO;
			}
			
			//[self checkSUV];
			
			[pool release];
		}
		

			
		
		if( fImage == nil)
		{
			NSLog(@"not able to load the image : %@", srcFile);
			
            fImage = malloc( 128 * 128 * 4);
			
			height = 128;
			width = 128;
			oImage = nil;
			isRGB = NO;
			notAbleToLoadImage = YES;
			
			for( int i = 0; i < 128*128; i++)
				fImage[ i ] = i;
		}
		
		if( isRGB)	// COMPUTE ALPHA MASK = ALPHA = R+G+B/3
		{
			unsigned char *argbPtr = (unsigned char*) fImage;
			long ss = width * height;
			
			while( ss-->0)
			{
				*argbPtr = (*(argbPtr+1) + *(argbPtr+2) + *(argbPtr+3)) / 3;
				argbPtr+=4;
			}
		}
	}
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

-(void) CheckLoad
{
	// uses DCMPix class variable NSString *srcFile to load (CheckLoadIn method), for the first time or again, an fImage or oImage....
	
	[checking lock];
	
	@try
	{
		[self CheckLoadIn];
	}
	@catch (NSException *ne)
	{
		NSLog( @"CheckLoad Exception");
		NSLog( @"Exception : %@", [ne description]);
		NSLog( @"Exception for this file: %@", srcFile);
	}
	
	[checking unlock];
}





@end
