#import "LineOverlayModel.h"

#import "ImageContext.h"

@implementation LineOverlayModel

- (instancetype)initWithPointA:(NSPoint)pointA
                        pointB:(NSPoint)pointB
                 imageIdentity:(ImageContext *)imageIdentity
{
    self = [super init];
    if (self) {
        _pointA = pointA;
        _pointB = pointB;
        _imageIdentity = [imageIdentity copy];
    }
    return self;
}

@end
