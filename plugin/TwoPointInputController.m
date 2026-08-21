#import "TwoPointInputController.h"

#import <DCMPix.h>
#import <DCMView.h>
#import <ViewerController.h>

@interface TwoPointInputController ()
@property(nonatomic, weak, readwrite) ViewerController *viewer;
@property(nonatomic, copy) MedisaleTwoPointCompletion completion;
@property(nonatomic, strong) id eventMonitor;
@property(nonatomic, strong) id windowCloseObserver;
@property(nonatomic, strong) NSMutableArray<NSValue *> *capturedPoints;
@end

@implementation TwoPointInputController

- (instancetype)initWithViewer:(ViewerController *)viewer
                     completion:(MedisaleTwoPointCompletion)completion
{
    self = [super init];
    if (self) {
        _viewer = viewer;
        _completion = [completion copy];
        _capturedPoints = [NSMutableArray arrayWithCapacity:2];
    }
    return self;
}

- (NSArray<NSValue *> *)points
{
    return [self.capturedPoints copy];
}

- (void)start
{
    if (self.eventMonitor != nil) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    NSWindow *window = self.viewer.imageView.window;
    if (window != nil) {
        self.windowCloseObserver = [[NSNotificationCenter defaultCenter]
            addObserverForName:NSWindowWillCloseNotification
            object:window
            queue:[NSOperationQueue mainQueue]
            usingBlock:^(NSNotification *notification) {
                (void)notification;
                [weakSelf cancel];
            }];
    }
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:
        (NSEventMaskLeftMouseDown | NSEventMaskKeyDown)
        handler:^NSEvent * _Nullable(NSEvent *event) {
            typeof(self) self = weakSelf;
            if (self == nil) {
                return event;
            }
            DCMView *view = self.viewer.imageView;
            if (event.type == NSEventTypeKeyDown) {
                if (event.keyCode == 53 && event.window == view.window) {
                    [self cancel];
                    return nil;
                }
                return event;
            }
            if (event.type != NSEventTypeLeftMouseDown || event.window != view.window) {
                return event;
            }
            NSPoint viewPoint = [view convertPoint:event.locationInWindow fromView:nil];
            if (!NSPointInRect(viewPoint, view.bounds)) {
                return event;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self captureCurrentImagePoint];
            });
            return event;
        }];
}

- (void)captureCurrentImagePoint
{
    DCMView *view = self.viewer.imageView;
    DCMPix *pix = view.curDCM;
    NSPoint point = NSMakePoint(view.mouseXPos, view.mouseYPos);
    if (pix == nil || point.x < 0 || point.y < 0 ||
        point.x >= pix.pwidth || point.y >= pix.pheight) {
        return;
    }
    [self.capturedPoints addObject:[NSValue valueWithPoint:point]];
    if (self.capturedPoints.count == 2) {
        [self finishCancelled:NO];
    }
}

- (void)cancel
{
    [self finishCancelled:YES];
}

- (void)invalidate
{
    if (self.eventMonitor != nil) {
        [NSEvent removeMonitor:self.eventMonitor];
        self.eventMonitor = nil;
    }
    if (self.windowCloseObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.windowCloseObserver];
        self.windowCloseObserver = nil;
    }
    self.completion = nil;
    [self.capturedPoints removeAllObjects];
    self.viewer = nil;
}

- (void)finishCancelled:(BOOL)cancelled
{
    if (self.eventMonitor != nil) {
        [NSEvent removeMonitor:self.eventMonitor];
        self.eventMonitor = nil;
    }
    if (self.windowCloseObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.windowCloseObserver];
        self.windowCloseObserver = nil;
    }
    MedisaleTwoPointCompletion completion = self.completion;
    self.completion = nil;
    if (completion != nil) {
        completion(cancelled, self.points);
    }
}

- (void)dealloc
{
    [self invalidate];
}

@end
