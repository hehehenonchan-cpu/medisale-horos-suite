#import <Cocoa/Cocoa.h>
#import <BrowserController.h>
#import <DicomSeries.h>
#import <DicomStudy.h>
#import <PluginFilter.h>
#import "HorosAdapter.h"
#import "ImageContext.h"
#import "LineOverlayModel.h"
#import "MeasurementContextConsumer.h"
#import "TransientLineOverlayController.h"
#import "TwoPointInputController.h"

static NSString *const MedisaleViewerToolbarIdentifier = @"jp.medisale.horos.viewer-toolbar-test";
static NSString *const MedisaleBrowserToolbarIdentifier = @"jp.medisale.horos.browser-toolbar-test";
static NSString *const MedisaleContextToolbarIdentifier = @"jp.medisale.horos.image-context-test";
static NSString *const MedisaleTwoPointToolbarIdentifier = @"jp.medisale.horos.two-point-test";

@interface MedisalePluginFilter : PluginFilter {
    NSMapTable<NSToolbarItem *, id> *_viewerByToolbarItem;
    NSMapTable<id, NSNumber *> *_viewerNumberByViewer;
    NSMapTable<NSToolbarItem *, BrowserController *> *_browserByToolbarItem;
    NSMapTable<ViewerController *, TwoPointInputController *> *_inputByViewer;
    NSMapTable<ViewerController *, TransientLineOverlayController *> *_overlayByViewer;
    NSUInteger _nextViewerNumber;
}
@end

@implementation MedisalePluginFilter

- (long)filterImage:(NSString *)menuName
{
    (void)menuName;

    if (viewerController != nil) {
        [self startTwoPointInputForViewer:viewerController];
        return 0;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Medisale Plugin OK";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];

    return 0;
}

- (void)startTwoPointInputForViewer:(ViewerController *)controller
{
    NSError *contextError = nil;
    ImageContext *inputIdentity = [HorosAdapter imageContextForViewer:controller
                                                                error:&contextError];
    if (inputIdentity == nil) {
        NSAlert *stop = [[NSAlert alloc] init];
        stop.messageText = @"Transient Overlay STOP";
        stop.informativeText = contextError.localizedDescription;
        [stop addButtonWithTitle:@"OK"];
        [stop runModal];
        return;
    }
    if (_inputByViewer == nil) {
        _inputByViewer = [NSMapTable weakToStrongObjectsMapTable];
    }
    TwoPointInputController *existing = [_inputByViewer objectForKey:controller];
    [existing cancel];
    NSNumber *viewerNumber = [self viewerNumberForViewer:controller];

    __weak typeof(self) weakSelf = self;
    __weak ViewerController *weakViewer = controller;
    TwoPointInputController *input = [[TwoPointInputController alloc]
        initWithViewer:controller
        completion:^(BOOL cancelled, NSArray<NSValue *> *points) {
            typeof(self) self = weakSelf;
            ViewerController *viewer = weakViewer;
            if (self == nil) {
                return;
            }
            [self->_inputByViewer removeObjectForKey:viewer];
            NSAlert *result = [[NSAlert alloc] init];
            if (cancelled) {
                result.messageText = @"Overlay Input Cancelled";
                result.informativeText = [NSString stringWithFormat:
                    @"Viewer %@\nCaptured: %lu", viewerNumber,
                    (unsigned long)points.count];
            } else {
                NSPoint a = points[0].pointValue;
                NSPoint b = points[1].pointValue;
                NSError *currentError = nil;
                ImageContext *currentIdentity = viewer == nil ? nil :
                    [HorosAdapter imageContextForViewer:viewer error:&currentError];
                BOOL sameImage = currentIdentity != nil &&
                    [currentIdentity.sopInstanceUID isEqualToString:inputIdentity.sopInstanceUID] &&
                    currentIdentity.frameNumber == inputIdentity.frameNumber;
                if (!sameImage) {
                    result.messageText = @"Transient Overlay STOP";
                    result.informativeText = currentError.localizedDescription ?:
                        @"The displayed image or frame changed during point input.";
                    [result addButtonWithTitle:@"OK"];
                    [result runModal];
                    return;
                }

                if (self->_overlayByViewer == nil) {
                    self->_overlayByViewer = [NSMapTable weakToStrongObjectsMapTable];
                }
                TransientLineOverlayController *previous =
                    [self->_overlayByViewer objectForKey:viewer];
                [self->_overlayByViewer removeObjectForKey:viewer];
                [previous invalidate];

                LineOverlayModel *model = [[LineOverlayModel alloc]
                    initWithPointA:a pointB:b imageIdentity:currentIdentity];
                __block __weak TransientLineOverlayController *weakOverlay = nil;
                TransientLineOverlayController *overlay =
                    [[TransientLineOverlayController alloc]
                        initWithViewer:viewer
                                 model:model
                          invalidation:^{
                    typeof(self) self = weakSelf;
                    ViewerController *viewer = weakViewer;
                    TransientLineOverlayController *overlay = weakOverlay;
                    if (self != nil && viewer != nil &&
                        [self->_overlayByViewer objectForKey:viewer] == overlay) {
                        [self->_overlayByViewer removeObjectForKey:viewer];
                    }
                }];
                weakOverlay = overlay;
                [self->_overlayByViewer setObject:overlay forKey:viewer];
                if (![overlay start]) {
                    [self->_overlayByViewer removeObjectForKey:viewer];
                    [overlay invalidate];
                    result.messageText = @"Transient Overlay STOP";
                    result.informativeText = @"The overlay could not bind to the current image.";
                    [result addButtonWithTitle:@"OK"];
                    [result runModal];
                    return;
                }

                result.messageText = @"Transient Overlay OK";
                result.informativeText = [NSString stringWithFormat:
                    @"Viewer %@\nA: %.3f, %.3f\nB: %.3f, %.3f",
                    viewerNumber, a.x, a.y, b.x, b.y];
            }
            [result addButtonWithTitle:@"OK"];
            [result runModal];
        }];
    [_inputByViewer setObject:input forKey:controller];
    [input start];

    NSAlert *ready = [[NSAlert alloc] init];
    ready.messageText = @"Transient Overlay Ready";
    ready.informativeText = [NSString stringWithFormat:
        @"Viewer %@\nClick two points inside this Viewer to draw a transient line. Press Escape to cancel.",
        viewerNumber];
    [ready addButtonWithTitle:@"OK"];
    [ready addButtonWithTitle:@"Duplicate Viewer"];
    if ([ready runModal] == NSAlertSecondButtonReturn) {
        ViewerController *previousViewerController = viewerController;
        viewerController = controller;
        [self duplicateCurrent2DViewerWindow];
        viewerController = previousViewerController;
    }
}

- (BOOL)isCertifiedForMedicalImaging
{
    return NO;
}

- (NSArray *)toolbarAllowedIdentifiersForViewer:(id)controller
{
    (void)controller;
    return @[MedisaleViewerToolbarIdentifier, MedisaleContextToolbarIdentifier,
             MedisaleTwoPointToolbarIdentifier];
}

- (NSToolbarItem *)toolbarItemForItemIdentifier:(NSString *)identifier forViewer:(id)controller
{
    if ((! [identifier isEqualToString:MedisaleViewerToolbarIdentifier] &&
         ![identifier isEqualToString:MedisaleContextToolbarIdentifier] &&
         ![identifier isEqualToString:MedisaleTwoPointToolbarIdentifier]) || controller == nil) {
        return nil;
    }

    [self ensureViewerTracking];

    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    BOOL contextItem = [identifier isEqualToString:MedisaleContextToolbarIdentifier];
    BOOL twoPointItem = [identifier isEqualToString:MedisaleTwoPointToolbarIdentifier];
    item.label = contextItem ? @"Medisale Context" :
        (twoPointItem ? @"Medisale Overlay" : @"Medisale Test");
    item.paletteLabel = item.label;
    item.toolTip = contextItem ? @"Create an independent ImageContext" :
        (twoPointItem ? @"Draw a transient line from two image-coordinate points" : @"Verify the owning Viewer");
    item.image = [NSImage imageNamed:NSImageNameActionTemplate];
    item.target = self;
    item.action = contextItem ? @selector(showImageContext:) :
        (twoPointItem ? @selector(startTwoPointInput:) : @selector(showViewerToolbarOK:));

    [_viewerByToolbarItem setObject:controller forKey:item];
    [self viewerNumberForViewer:controller];

    return item;
}

- (void)startTwoPointInput:(id)sender
{
    ViewerController *controller = [sender isKindOfClass:[NSToolbarItem class]]
        ? [_viewerByToolbarItem objectForKey:sender]
        : nil;
    if (controller != nil) {
        [self startTwoPointInputForViewer:controller];
    }
}

- (void)showImageContext:(id)sender
{
    ViewerController *controller = [sender isKindOfClass:[NSToolbarItem class]]
        ? [_viewerByToolbarItem objectForKey:sender]
        : nil;
    [self showImageContextForViewer:controller];
}

- (void)showImageContextForViewer:(ViewerController *)controller
{
    NSError *error = nil;
    ImageContext *context = controller == nil ? nil :
        [HorosAdapter imageContextForViewer:controller error:&error];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = context == nil ? @"Image Context STOP" : @"Image Context OK";
    alert.informativeText = context == nil ? error.localizedDescription
        : MedisaleMeasurementSummary(context);
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)showViewerToolbarOK:(id)sender
{
    id controller = [sender isKindOfClass:[NSToolbarItem class]]
        ? [_viewerByToolbarItem objectForKey:sender]
        : nil;
    NSNumber *viewerNumber = controller == nil ? nil : [self viewerNumberForViewer:controller];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Viewer Toolbar OK";
    alert.informativeText = viewerNumber == nil
        ? @"Owning Viewer: Closed"
        : [NSString stringWithFormat:@"Owning Viewer: Viewer %@", viewerNumber];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Duplicate Viewer"];

    if ([alert runModal] == NSAlertSecondButtonReturn && controller != nil) {
        ViewerController *previousViewerController = viewerController;
        viewerController = controller;
        [self duplicateCurrent2DViewerWindow];
        viewerController = previousViewerController;
    }
}

- (void)ensureViewerTracking
{
    if (_viewerByToolbarItem == nil) {
        _viewerByToolbarItem = [NSMapTable weakToWeakObjectsMapTable];
        _viewerNumberByViewer = [NSMapTable weakToStrongObjectsMapTable];
        _nextViewerNumber = 1;
    }
}

- (NSNumber *)viewerNumberForViewer:(id)controller
{
    [self ensureViewerTracking];

    NSNumber *viewerNumber = [_viewerNumberByViewer objectForKey:controller];
    if (viewerNumber == nil) {
        viewerNumber = @(_nextViewerNumber++);
        [_viewerNumberByViewer setObject:viewerNumber forKey:controller];
    }
    return viewerNumber;
}

- (NSArray *)toolbarAllowedIdentifiersForBrowserController:(id)controller
{
    (void)controller;
    return @[MedisaleBrowserToolbarIdentifier];
}

- (NSToolbarItem *)toolbarItemForItemIdentifier:(NSString *)identifier
                           forBrowserController:(id)controller
{
    if (![identifier isEqualToString:MedisaleBrowserToolbarIdentifier] ||
        ![controller isKindOfClass:[BrowserController class]]) {
        return nil;
    }

    if (_browserByToolbarItem == nil) {
        _browserByToolbarItem = [NSMapTable weakToWeakObjectsMapTable];
    }

    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    item.label = @"Medisale Tools Test";
    item.paletteLabel = @"Medisale Tools Test";
    item.toolTip = @"Inspect the Browser selection without changing it";
    item.image = [NSImage imageNamed:NSImageNameInfo];
    item.target = self;
    item.action = @selector(showBrowserToolbarOK:);

    [_browserByToolbarItem setObject:controller forKey:item];
    return item;
}

- (void)showBrowserToolbarOK:(id)sender
{
    BrowserController *controller = [sender isKindOfClass:[NSToolbarItem class]]
        ? [_browserByToolbarItem objectForKey:sender]
        : nil;
    NSArray *selection = controller == nil ? @[] : [controller databaseSelection];
    NSUInteger studyCount = 0;
    NSUInteger seriesCount = 0;
    NSUInteger otherCount = 0;

    for (id object in selection) {
        if ([object isKindOfClass:[DicomStudy class]]) {
            studyCount++;
        } else if ([object isKindOfClass:[DicomSeries class]]) {
            seriesCount++;
        } else {
            otherCount++;
        }
    }

    NSString *summary;
    if (selection.count == 0) {
        summary = @"Selection: None";
    } else if (selection.count == 1 && studyCount == 1) {
        summary = @"Selection: Study 1";
    } else if (selection.count == 1 && seriesCount == 1) {
        summary = @"Selection: Series 1";
    } else {
        summary = [NSString stringWithFormat:
            @"Selection: Multiple %lu (Studies %lu, Series %lu, Other %lu)",
            (unsigned long)selection.count,
            (unsigned long)studyCount,
            (unsigned long)seriesCount,
            (unsigned long)otherCount];
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Browser Toolbar OK";
    alert.informativeText = summary;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

@end
