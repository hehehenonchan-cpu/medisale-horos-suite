#import "TransientLineOverlayController.h"

#import "HorosAdapter.h"
#import "ImageContext.h"
#import "LineOverlayModel.h"
#import <DCMView.h>
#import <Notifications.h>
#import <ViewerController.h>

@interface MedisaleLineOverlayView : NSView
@property(nonatomic, weak) DCMView *imageView;
@property(nonatomic, strong) LineOverlayModel *model;
@end

@implementation MedisaleLineOverlayView

- (BOOL)isOpaque
{
    return NO;
}

- (BOOL)isFlipped
{
    return NO;
}

- (NSView *)hitTest:(NSPoint)point
{
    (void)point;
    return nil;
}

- (void)drawRect:(NSRect)dirtyRect
{
    (void)dirtyRect;
    DCMView *imageView = self.imageView;
    LineOverlayModel *model = self.model;
    if (imageView == nil || model == nil) {
        return;
    }

    NSPoint a = [imageView ConvertFromGL2NSView:model.pointA];
    NSPoint b = [imageView ConvertFromGL2NSView:model.pointB];

    NSBezierPath *outline = [NSBezierPath bezierPath];
    [outline moveToPoint:a];
    [outline lineToPoint:b];
    outline.lineWidth = 5.0;
    outline.lineCapStyle = NSLineCapStyleRound;
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.85] setStroke];
    [outline stroke];

    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:a];
    [line lineToPoint:b];
    line.lineWidth = 2.5;
    line.lineCapStyle = NSLineCapStyleRound;
    [[NSColor colorWithCalibratedRed:0.0 green:0.95 blue:1.0 alpha:1.0] setStroke];
    [line stroke];

    for (NSValue *value in @[[NSValue valueWithPoint:a], [NSValue valueWithPoint:b]]) {
        NSPoint point = value.pointValue;
        NSRect markerRect = NSMakeRect(point.x - 4.0, point.y - 4.0, 8.0, 8.0);
        NSBezierPath *marker = [NSBezierPath bezierPathWithOvalInRect:markerRect];
        [[NSColor colorWithCalibratedRed:0.0 green:0.95 blue:1.0 alpha:1.0] setFill];
        [marker fill];
        [[NSColor blackColor] setStroke];
        marker.lineWidth = 1.0;
        [marker stroke];
    }
}

@end

@interface TransientLineOverlayController ()
@property(nonatomic, weak, readwrite) ViewerController *viewer;
@property(nonatomic, strong, readwrite) LineOverlayModel *model;
@property(nonatomic, readwrite, getter=isActive) BOOL active;
@property(nonatomic, strong) MedisaleLineOverlayView *overlayView;
@property(nonatomic, strong) NSTimer *redrawTimer;
@property(nonatomic, strong) NSMutableArray *observers;
@property(nonatomic, strong) id eventMonitor;
@property(nonatomic, copy) MedisaleOverlayInvalidation invalidation;
@property(nonatomic) BOOL originalPostsFrameChangedNotifications;
@end

@implementation TransientLineOverlayController

- (instancetype)initWithViewer:(ViewerController *)viewer
                           model:(LineOverlayModel *)model
                    invalidation:(MedisaleOverlayInvalidation)invalidation
{
    self = [super init];
    if (self) {
        _viewer = viewer;
        _model = model;
        _invalidation = [invalidation copy];
        _observers = [NSMutableArray array];
    }
    return self;
}

- (BOOL)start
{
    if (self.active) {
        return YES;
    }
    DCMView *imageView = self.viewer.imageView;
    if (imageView == nil || ![self currentImageMatchesModel]) {
        return NO;
    }

    self.originalPostsFrameChangedNotifications = imageView.postsFrameChangedNotifications;
    imageView.postsFrameChangedNotifications = YES;

    MedisaleLineOverlayView *overlayView = [[MedisaleLineOverlayView alloc]
        initWithFrame:imageView.bounds];
    overlayView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    overlayView.imageView = imageView;
    overlayView.model = self.model;
    overlayView.wantsLayer = YES;
    [imageView addSubview:overlayView positioned:NSWindowAbove relativeTo:nil];
    self.overlayView = overlayView;
    self.active = YES;

    __weak typeof(self) weakSelf = self;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (imageView.window != nil) {
        [self.observers addObject:[center
            addObserverForName:NSWindowWillCloseNotification
            object:imageView.window
            queue:[NSOperationQueue mainQueue]
            usingBlock:^(NSNotification *notification) {
                (void)notification;
                [weakSelf invalidate];
            }]];
    }
    [self.observers addObject:[center
        addObserverForName:OsirixDCMViewIndexChangedNotification
        object:imageView
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            typeof(self) self = weakSelf;
            if (self != nil && ![self currentImageMatchesModel]) {
                [self invalidate];
            }
        }]];
    [self.observers addObject:[center
        addObserverForName:OsirixUpdateViewNotification
        object:imageView
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf requestRedraw];
        }]];
    [self.observers addObject:[center
        addObserverForName:NSViewFrameDidChangeNotification
        object:imageView
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf requestRedraw];
        }]];

    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:
        (NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged |
         NSEventMaskOtherMouseDragged | NSEventMaskScrollWheel |
         NSEventMaskMagnify | NSEventMaskRotate)
        handler:^NSEvent * _Nullable(NSEvent *event) {
            typeof(self) self = weakSelf;
            if (self != nil && event.window == self.viewer.imageView.window) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self requestRedraw];
                });
            }
            return event;
        }];

    self.redrawTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                        repeats:YES
                                                          block:^(NSTimer *timer) {
        (void)timer;
        typeof(self) self = weakSelf;
        if (self == nil) {
            return;
        }
        if (![self currentImageMatchesModel]) {
            [self invalidate];
            return;
        }
        [self requestRedraw];
    }];
    [self requestRedraw];
    return YES;
}

- (BOOL)currentImageMatchesModel
{
    ViewerController *viewer = self.viewer;
    NSError *error = nil;
    ImageContext *current = viewer == nil ? nil :
        [HorosAdapter imageContextForViewer:viewer error:&error];
    (void)error;
    ImageContext *expected = self.model.imageIdentity;
    return current != nil &&
        [current.sopInstanceUID isEqualToString:expected.sopInstanceUID] &&
        current.frameNumber == expected.frameNumber;
}

- (void)requestRedraw
{
    if (!self.active) {
        return;
    }
    DCMView *imageView = self.viewer.imageView;
    if (imageView == nil) {
        [self invalidate];
        return;
    }
    if (!NSEqualRects(self.overlayView.frame, imageView.bounds)) {
        self.overlayView.frame = imageView.bounds;
    }
    [self.overlayView setNeedsDisplay:YES];
}

- (void)invalidate
{
    if (!self.active && self.overlayView == nil && self.eventMonitor == nil &&
        self.observers.count == 0 && self.redrawTimer == nil) {
        return;
    }

    self.active = NO;
    [self.redrawTimer invalidate];
    self.redrawTimer = nil;
    if (self.eventMonitor != nil) {
        [NSEvent removeMonitor:self.eventMonitor];
        self.eventMonitor = nil;
    }
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    for (id observer in self.observers) {
        [center removeObserver:observer];
    }
    [self.observers removeAllObjects];

    DCMView *imageView = self.viewer.imageView;
    if (imageView != nil) {
        imageView.postsFrameChangedNotifications = self.originalPostsFrameChangedNotifications;
    }
    [self.overlayView removeFromSuperview];
    self.overlayView.imageView = nil;
    self.overlayView.model = nil;
    self.overlayView = nil;

    MedisaleOverlayInvalidation invalidation = self.invalidation;
    self.invalidation = nil;
    self.viewer = nil;
    if (invalidation != nil) {
        invalidation();
    }
}

- (void)dealloc
{
    [self invalidate];
}

@end
