//
//  DCMPix.h
//  Alt
//
//  Created by Dan Chen on 3/27/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <CoreData/CoreData.h>


@interface DCMPix : NSObject {

	//Sources
	NSString                    *srcFile;  /**< source File */
	BOOL                        isBonjour;  /**< Flag to indicate if file is accessed over Bonjour */
	BOOL                        nonDICOM;   /**< Flag to indicate if file is not DICOM */
	
	//BUFFERS	
	NSArray				*pixArray;
	NSManagedObject		*imageObj;	/**< Core data object for image */
	float                       *fImage; /**< float buffer of image Data */
    float                       *fExternalOwnedImage;  /**< float buffer of image Data - provided by another source, not owned by this object, not release by this object */

	
	/** 12 bit monitors */
	BOOL				needToCompute8bitRepresentation;
	
	//image size
    long                height, width;
	
	//window level & width
	float				savedWL, savedWW;
	
	//photointerpretation
	BOOL				isRGB;
	BOOL				inverseVal;
    
    BOOL                notAbleToLoadImage;
    
    NSRecursiveLock		*checking;
    
    //-------------------------------------------------------	
	long				frameNo;
	long				serieNo;
	long				imID, imTot;    
    char                *baseAddr;
	
	
	//pixel representation
    float               slope, offset;
	BOOL				fIsSigned;
	short				bitsAllocated, bitsStored;
	
	//planar configuration
	long				fPlanarConf;
	double				pixelSpacingX, pixelSpacingY, pixelRatio;
	BOOL				pixelSpacingFromUltrasoundRegions;
	
	//slice
	double				sliceInterval, sliceLocation, sliceThickness;
	double				spacingBetweenSlices;	
    
    //DICOM params needed for SUV calculations
	float				patientsWeight;
	NSString			*repetitiontime, *echotime, *flipAngle, *laterality;
	NSString			*viewPosition, *patientPosition, *acquisitionDate, *SOPClassUID, *frameofReferenceUID;
	NSString			*units, *decayCorrection;
	float				decayFactor, factorPET2SUV;
	
	NSNumber			*positionerPrimaryAngle;
	NSNumber			*positionerSecondaryAngle;
	
	float				cineRate;
	
	long				shutterRect_x;
	long				shutterRect_y;
	long				shutterRect_w;
	long				shutterRect_h;
	
	long				shutterCircular_x;
	long				shutterCircular_y;
	long				shutterCircular_radius;
	
	CGPoint	 			*shutterPolygonal;
	long				shutterPolygonalSize;
	
	
	BOOL				DCMPixShutterOnOff;
	
	//orientation
	BOOL				isOriginDefined;
	double				originX /**< x position of image origin */ , originY /**< y Position of image origin */ , originZ /**< Z position of image origin*/;
	double				orientation[ 9];  /**< pointer to orientation vectors  */
	
	// DICOM params for Overlays - 0x6000 group	
	int					oRows, oColumns, oType, oOrigin[ 2], oBits, oBitPosition;
	unsigned char		*oData;
	
	float				ww, wl;
	
	//stack
	short				stack;
	
	//DSA-subtraction	
	float				subtractedfPercent;
	float				subtractedfZ;
	float				subtractedfZero;
	float				subtractedfGamma;

	long				maskID;
	
	/** custom annotations */
	NSMutableDictionary *annotationsDictionary;

}

/** Database links */
//@property(readonly) NSManagedObject *seriesObj;
//@property(retain) NSManagedObject *imageObj;
@property(retain) NSString *srcFile, *SOPClassUID;

/**  pixel size */
@property double pixelSpacingX, pixelSpacingY;

@property(retain) NSString *repetitiontime, *echotime;
@property(readonly) NSString *flipAngle, *laterality;

/** Slice location */
@property(readonly) double originX, originY, originZ;
@property(readonly) BOOL isOriginDefined;
@property(retain) NSString *frameofReferenceUID;

- (id) initWithContentsOfFile: (NSString *)file; 
/** create an NSImage from the current pix using the current ww/wl. Full size*/
- (UIImage*) image;

@end
