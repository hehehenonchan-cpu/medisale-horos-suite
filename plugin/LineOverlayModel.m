#import "LineOverlayModel.h"

#import "ImageContext.h"
#import <math.h>

NSNotificationName const LineOverlayModelDidChangeNotification =
    @"MedisaleLineOverlayModelDidChangeNotification";

@interface LineOverlayModel ()
@property(nonatomic, readwrite) NSPoint pointA;
@property(nonatomic, readwrite) NSPoint pointB;
@property(nonatomic, readwrite) LineOverlayInputState inputState;
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
        _inputState = LineOverlayInputStateComplete;
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
    [self notifyChange];
}

- (void)updatePointB:(NSPoint)point
{
    self.pointB = point;
    [self notifyChange];
}

- (void)updateInputState:(LineOverlayInputState)inputState
{
    if (self.inputState == inputState) {
        return;
    }
    self.inputState = inputState;
    [self notifyChange];
}

- (void)notifyChange
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:LineOverlayModelDidChangeNotification object:self];
}

@end
