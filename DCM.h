#import "DCMAttribute.h"
#import "DCMAttributeTag.h"
#import "DCMCalendarDate.h"
#import "DCMCharacterSet.h"
#import "DCMDataContainer.h"
#import "DCMObject.h"
#import "DCMPixelDataAttribute.h"
#import "DCMSequenceAttribute.h"
#import "DCMTagDictionary.h"
#import "DCMTagForNameDictionary.h"
#import "DCMValueRepresentation.h"


#import "DCMTransferSyntax.h"

#define DCMDEBUG NO
#define DCMFramework_compile YES

enum DCM_CompressionQuality {DCMLosslessQuality = 0, DCMHighQuality, DCMMediumQuality, DCMLowQuality};
