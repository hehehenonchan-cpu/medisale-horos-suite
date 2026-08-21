#import <Foundation/Foundation.h>

@class LineOverlayModel;
@class GuideEngine;
@class ViewerController;

NS_ASSUME_NONNULL_BEGIN

typedef void (^MedisalePanelHostInvalidation)(void);

@protocol MeasurementPanelHost <NSObject>

@property(nonatomic, readonly, getter=isVisible) BOOL visible;
@property(nonatomic, readonly, getter=isBound) BOOL bound;

- (instancetype)initWithViewer:(ViewerController *)viewer
                           model:(LineOverlayModel *)model
                     guideEngine:(GuideEngine *)guideEngine
                    invalidation:(MedisalePanelHostInvalidation)invalidation;
- (BOOL)present;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
