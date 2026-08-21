#import <Cocoa/Cocoa.h>

@class ImageContext;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LineOverlayInputState) {
    LineOverlayInputStateComplete = 0,
    LineOverlayInputStateEndpointASelected,
    LineOverlayInputStateEndpointBSelected,
    LineOverlayInputStateEditingEndpointA,
    LineOverlayInputStateEditingEndpointB,
};

FOUNDATION_EXPORT NSNotificationName const LineOverlayModelDidChangeNotification;

@interface LineOverlayModel : NSObject

@property(nonatomic, readonly) NSPoint pointA;
@property(nonatomic, readonly) NSPoint pointB;
@property(nonatomic, copy, readonly) ImageContext *imageIdentity;
@property(nonatomic, readonly) double pixelDistance;
@property(nonatomic, readonly) LineOverlayInputState inputState;

- (instancetype)initWithPointA:(NSPoint)pointA
                        pointB:(NSPoint)pointB
                 imageIdentity:(ImageContext *)imageIdentity NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)updatePointA:(NSPoint)point;
- (void)updatePointB:(NSPoint)point;
- (void)updateInputState:(LineOverlayInputState)inputState;

@end

NS_ASSUME_NONNULL_END
