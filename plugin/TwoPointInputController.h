#import <Cocoa/Cocoa.h>

@class ViewerController;

NS_ASSUME_NONNULL_BEGIN

typedef void (^MedisaleTwoPointCompletion)(BOOL cancelled, NSArray<NSValue *> *points);

@interface TwoPointInputController : NSObject

@property(nonatomic, weak, readonly) ViewerController *viewer;
@property(nonatomic, copy, readonly) NSArray<NSValue *> *points;

- (instancetype)initWithViewer:(ViewerController *)viewer
                     completion:(MedisaleTwoPointCompletion)completion NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
