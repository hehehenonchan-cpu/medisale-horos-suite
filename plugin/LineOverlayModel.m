#import "LineOverlayModel.h"

#import "ImageContext.h"
#import <math.h>

@interface LineOverlayModel ()
@property(nonatomic, readwrite) NSPoint pointA;
@property(nonatomic, readwrite) NSPoint pointB;
@end

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

- (double)pixelDistance
{
    return hypot(self.pointB.x - self.pointA.x, self.pointB.y - self.pointA.y);
}

- (void)updatePointA:(NSPoint)point
{
    self.pointA = point;
}

- (void)updatePointB:(NSPoint)point
{
    self.pointB = point;
}

@end
