#import <Foundation/Foundation.h>

@class ImageContext;
@class ViewerController;

NS_ASSUME_NONNULL_BEGIN

@interface HorosAdapter : NSObject

+ (nullable ImageContext *)imageContextForViewer:(ViewerController *)viewer
                                           error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
