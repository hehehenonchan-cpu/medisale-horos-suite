#import <Cocoa/Cocoa.h>

#import "MeasurementPanelHost.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewerInspectorPanelHost : NSObject <MeasurementPanelHost, NSWindowDelegate>

- (instancetype)initWithViewer:(ViewerController *)viewer
                           model:(LineOverlayModel *)model
                     guideEngine:(GuideEngine *)guideEngine
                    invalidation:(MedisalePanelHostInvalidation)invalidation NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
