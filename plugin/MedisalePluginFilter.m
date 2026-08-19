#import <Cocoa/Cocoa.h>
#import <PluginFilter.h>

static NSString *const MedisaleViewerToolbarIdentifier = @"jp.medisale.horos.viewer-toolbar-test";

@interface MedisalePluginFilter : PluginFilter {
    NSMapTable<NSToolbarItem *, id> *_viewerByToolbarItem;
    NSMapTable<id, NSNumber *> *_viewerNumberByViewer;
    NSUInteger _nextViewerNumber;
}
@end

@implementation MedisalePluginFilter

- (long)filterImage:(NSString *)menuName
{
    (void)menuName;

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
    return @[MedisaleViewerToolbarIdentifier];
}

- (NSToolbarItem *)toolbarItemForItemIdentifier:(NSString *)identifier forViewer:(id)controller
{
    if (![identifier isEqualToString:MedisaleViewerToolbarIdentifier] || controller == nil) {
        return nil;
    }

    [self ensureViewerTracking];

    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    item.label = @"Medisale Test";
    item.paletteLabel = @"Medisale Test";
    item.toolTip = @"Verify the owning Viewer";
    item.image = [NSImage imageNamed:NSImageNameActionTemplate];
    item.target = self;
    item.action = @selector(showViewerToolbarOK:);

    [_viewerByToolbarItem setObject:controller forKey:item];
    [self viewerNumberForViewer:controller];

    return item;
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

@end
