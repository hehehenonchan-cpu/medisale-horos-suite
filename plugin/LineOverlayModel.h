#import <Cocoa/Cocoa.h>

@class ImageContext;

NS_ASSUME_NONNULL_BEGIN

@interface LineOverlayModel : NSObject

@property(nonatomic, readonly) NSPoint pointA;
@property(nonatomic, readonly) NSPoint pointB;
@property(nonatomic, copy, readonly) ImageContext *imageIdentity;
@property(nonatomic, readonly) double pixelDistance;

- (instancetype)initWithPointA:(NSPoint)pointA
                        pointB:(NSPoint)pointB
                 imageIdentity:(ImageContext *)imageIdentity NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)updatePointA:(NSPoint)point;
- (void)updatePointB:(NSPoint)point;

@end

NS_ASSUME_NONNULL_END
