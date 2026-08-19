#import <Cocoa/Cocoa.h>
#import <BrowserController.h>
#import <DicomSeries.h>
#import <DicomStudy.h>
#import <PluginFilter.h>
#import "HorosAdapter.h"
#import "ImageContext.h"
#import "MeasurementContextConsumer.h"

static NSString *const MedisaleViewerToolbarIdentifier = @"jp.medisale.horos.viewer-toolbar-test";
static NSString *const MedisaleBrowserToolbarIdentifier = @"jp.medisale.horos.browser-toolbar-test";
static NSString *const MedisaleContextToolbarIdentifier = @"jp.medisale.horos.image-context-test";

@interface MedisalePluginFilter : PluginFilter {
    NSMapTable<NSToolbarItem *, id> *_viewerByToolbarItem;
    NSMapTable<id, NSNumber *> *_viewerNumberByViewer;
    NSMapTable<NSToolbarItem *, BrowserController *> *_browserByToolbarItem;
    NSUInteger _nextViewerNumber;
}
@end

@implementation MedisalePluginFilter

- (long)filterImage:(NSString *)menuName
{
    (void)menuName;

    if (viewerController != nil) {
        [self showImageContextForViewer:viewerController];
        return 0;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Medisale Plugin OK";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];

    return 0;
}

- (BOOL)isCertifiedForMedicalImaging
{
    return NO;
}

- (NSArray *)toolbarAllowedIdentifiersForViewer:(id)controller
{
    (void)controller;
    return @[MedisaleViewerToolbarIdentifier, MedisaleContextToolbarIdentifier];
}

- (NSToolbarItem *)toolbarItemForItemIdentifier:(NSString *)identifier forViewer:(id)controller
{
    if ((! [identifier isEqualToString:MedisaleViewerToolbarIdentifier] &&
         ![identifier isEqualToString:MedisaleContextToolbarIdentifier]) || controller == nil) {
        return nil;
    }

    [self ensureViewerTracking];

    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    BOOL contextItem = [identifier isEqualToString:MedisaleContextToolbarIdentifier];
    item.label = contextItem ? @"Medisale Context" : @"Medisale Test";
    item.paletteLabel = item.label;
    item.toolTip = contextItem ? @"Create an independent ImageContext" : @"Verify the owning Viewer";
    item.image = [NSImage imageNamed:NSImageNameActionTemplate];
    item.target = self;
    item.action = contextItem ? @selector(showImageContext:) : @selector(showViewerToolbarOK:);

    [_viewerByToolbarItem setObject:controller forKey:item];
    [self viewerNumberForViewer:controller];

    return item;
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
