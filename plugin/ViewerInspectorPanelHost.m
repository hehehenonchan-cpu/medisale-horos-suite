#import "ViewerInspectorPanelHost.h"

#import "GuideEngine.h"
#import "LineOverlayModel.h"
#import <ViewerController.h>

static NSString *MedisaleInputStateText(LineOverlayInputState state)
{
    switch (state) {
        case LineOverlayInputStateEndpointASelected:
            return @"Endpoint A selected";
        case LineOverlayInputStateEndpointBSelected:
            return @"Endpoint B selected";
        case LineOverlayInputStateEditingEndpointA:
            return @"Editing endpoint A";
        case LineOverlayInputStateEditingEndpointB:
            return @"Editing endpoint B";
        case LineOverlayInputStateComplete:
        default:
            return @"Complete";
    }
}

@interface ViewerInspectorPanelHost ()
@property(nonatomic, weak) ViewerController *viewer;
@property(nonatomic, strong) LineOverlayModel *model;
@property(nonatomic, strong) GuideEngine *guideEngine;
@property(nonatomic, copy) MedisalePanelHostInvalidation invalidation;
@property(nonatomic, strong) NSPanel *panel;
@property(nonatomic, strong) NSTextField *pointAField;
@property(nonatomic, strong) NSTextField *pointBField;
@property(nonatomic, strong) NSTextField *distanceField;
@property(nonatomic, strong) NSTextField *stateField;
@property(nonatomic, strong) NSTextField *bindingField;
@property(nonatomic, strong) NSTextField *shortInstructionsField;
@property(nonatomic, strong) NSButton *detailedGuideToggle;
@property(nonatomic, strong) NSTextField *detailedInstructionsField;
@property(nonatomic, strong) NSMutableArray *observers;
@property(nonatomic, readwrite, getter=isBound) BOOL bound;
@property(nonatomic) BOOL userClosed;
@end

@implementation ViewerInspectorPanelHost

- (instancetype)initWithViewer:(ViewerController *)viewer
                           model:(LineOverlayModel *)model
                     guideEngine:(GuideEngine *)guideEngine
                    invalidation:(MedisalePanelHostInvalidation)invalidation
{
    self = [super init];
    if (self) {
        _viewer = viewer;
        _model = model;
        _guideEngine = guideEngine;
        _invalidation = [invalidation copy];
        _observers = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isVisible
{
    return self.panel.isVisible;
}

- (BOOL)present
{
    ViewerController *viewer = self.viewer;
    NSWindow *viewerWindow = viewer.window;
    if (viewer == nil || viewerWindow == nil || self.model == nil ||
        self.guideEngine == nil) {
        return NO;
    }
    if (self.panel == nil) {
        [self buildPanel];
        [self installObserversForViewerWindow:viewerWindow];
    }
    self.bound = YES;
    self.userClosed = NO;
    [self updateFields];
    [self followViewerWindow];
    [self.panel orderFront:nil];
    return YES;
}

- (void)buildPanel
{
    NSRect frame = NSMakeRect(0.0, 0.0, 370.0, 470.0);
    NSWindowStyleMask style = NSWindowStyleMaskTitled |
        NSWindowStyleMaskClosable |
        NSWindowStyleMaskUtilityWindow |
        NSWindowStyleMaskNonactivatingPanel;
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:frame
                                                styleMask:style
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    panel.title = @"Medisale Measurement";
    panel.releasedWhenClosed = NO;
    panel.floatingPanel = YES;
    panel.becomesKeyOnlyIfNeeded = YES;
    panel.hidesOnDeactivate = YES;
    panel.level = NSNormalWindowLevel;
    panel.collectionBehavior = NSWindowCollectionBehaviorTransient;
    panel.delegate = self;

    NSView *content = [[NSView alloc] initWithFrame:frame];
    panel.contentView = content;

    NSTextField *heading = [NSTextField labelWithString:@"Transient measurement"];
    heading.font = [NSFont systemFontOfSize:15.0 weight:NSFontWeightSemibold];
    self.pointAField = [NSTextField labelWithString:@""];
    self.pointBField = [NSTextField labelWithString:@""];
    self.distanceField = [NSTextField labelWithString:@""];
    self.stateField = [NSTextField labelWithString:@""];
    self.bindingField = [NSTextField labelWithString:@""];
    self.bindingField.textColor = NSColor.secondaryLabelColor;
    NSTextField *shortHeading = [NSTextField labelWithString:@"Quick instructions"];
    shortHeading.font = [NSFont systemFontOfSize:13.0 weight:NSFontWeightSemibold];
    self.shortInstructionsField = [NSTextField labelWithString:@""];
    self.shortInstructionsField.lineBreakMode = NSLineBreakByWordWrapping;
    self.shortInstructionsField.maximumNumberOfLines = 0;
    self.detailedGuideToggle = [NSButton
        checkboxWithTitle:@"Show detailed guide"
                    target:self
                    action:@selector(detailedGuideToggled:)];
    self.detailedInstructionsField = [NSTextField labelWithString:@""];
    self.detailedInstructionsField.textColor = NSColor.secondaryLabelColor;
    self.detailedInstructionsField.lineBreakMode = NSLineBreakByWordWrapping;
    self.detailedInstructionsField.maximumNumberOfLines = 0;

    NSArray<NSTextField *> *fields = @[
        heading, self.pointAField, self.pointBField,
        self.distanceField, self.stateField, self.bindingField,
        shortHeading, self.shortInstructionsField, self.detailedInstructionsField
    ];
    for (NSTextField *field in fields) {
        field.translatesAutoresizingMaskIntoConstraints = NO;
        field.lineBreakMode = NSLineBreakByTruncatingTail;
        [content addSubview:field];
    }
    self.detailedGuideToggle.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:self.detailedGuideToggle];
    self.pointAField.font = [NSFont monospacedDigitSystemFontOfSize:13.0
                                                             weight:NSFontWeightRegular];
    self.pointBField.font = self.pointAField.font;
    self.distanceField.font = self.pointAField.font;

    [NSLayoutConstraint activateConstraints:@[
        [heading.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18.0],
        [heading.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-18.0],
        [heading.topAnchor constraintEqualToAnchor:content.topAnchor constant:18.0],
        [self.pointAField.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.pointAField.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.pointAField.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:18.0],
        [self.pointBField.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.pointBField.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.pointBField.topAnchor constraintEqualToAnchor:self.pointAField.bottomAnchor constant:10.0],
        [self.distanceField.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.distanceField.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.distanceField.topAnchor constraintEqualToAnchor:self.pointBField.bottomAnchor constant:10.0],
        [self.stateField.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.stateField.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.stateField.topAnchor constraintEqualToAnchor:self.distanceField.bottomAnchor constant:16.0],
        [self.bindingField.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.bindingField.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.bindingField.topAnchor constraintEqualToAnchor:self.stateField.bottomAnchor constant:10.0],
        [shortHeading.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [shortHeading.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [shortHeading.topAnchor constraintEqualToAnchor:self.bindingField.bottomAnchor constant:18.0],
        [self.shortInstructionsField.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.shortInstructionsField.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.shortInstructionsField.topAnchor constraintEqualToAnchor:shortHeading.bottomAnchor constant:8.0],
        [self.detailedGuideToggle.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.detailedGuideToggle.trailingAnchor constraintLessThanOrEqualToAnchor:heading.trailingAnchor],
        [self.detailedGuideToggle.topAnchor constraintEqualToAnchor:self.shortInstructionsField.bottomAnchor constant:16.0],
        [self.detailedInstructionsField.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.detailedInstructionsField.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.detailedInstructionsField.topAnchor constraintEqualToAnchor:self.detailedGuideToggle.bottomAnchor constant:8.0],
        [self.detailedInstructionsField.bottomAnchor constraintLessThanOrEqualToAnchor:content.bottomAnchor constant:-18.0],
    ]];
    self.panel = panel;
}

- (void)installObserversForViewerWindow:(NSWindow *)viewerWindow
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    __weak typeof(self) weakSelf = self;
    [self.observers addObject:[center
        addObserverForName:LineOverlayModelDidChangeNotification
        object:self.model
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf updateFields];
        }]];
    [self.observers addObject:[center
        addObserverForName:GuideEngineDidChangeNotification
        object:self.guideEngine
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf updateGuideFields];
        }]];
    NSArray<NSNotificationName> *followNotifications = @[
        NSWindowDidMoveNotification, NSWindowDidResizeNotification,
        NSWindowDidChangeScreenNotification
    ];
    for (NSNotificationName name in followNotifications) {
        [self.observers addObject:[center
            addObserverForName:name object:viewerWindow queue:[NSOperationQueue mainQueue]
            usingBlock:^(NSNotification *notification) {
                (void)notification;
                [weakSelf followViewerWindow];
            }]];
    }
    [self.observers addObject:[center
        addObserverForName:NSWindowDidBecomeKeyNotification
        object:viewerWindow
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            typeof(self) self = weakSelf;
            if (self != nil && self.bound && !self.userClosed) {
                [self followViewerWindow];
                [self.panel orderFront:nil];
            }
        }]];
    [self.observers addObject:[center
        addObserverForName:NSWindowDidResignKeyNotification
        object:viewerWindow
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf.panel orderOut:nil];
        }]];
    [self.observers addObject:[center
        addObserverForName:NSWindowWillCloseNotification
        object:viewerWindow
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf invalidate];
        }]];
}

- (void)updateFields
{
    LineOverlayModel *model = self.model;
    if (model == nil || self.panel == nil) {
        return;
    }
    self.pointAField.stringValue = [NSString stringWithFormat:
        @"Endpoint A   %.2f, %.2f", model.pointA.x, model.pointA.y];
    self.pointBField.stringValue = [NSString stringWithFormat:
        @"Endpoint B   %.2f, %.2f", model.pointB.x, model.pointB.y];
    self.distanceField.stringValue = [NSString stringWithFormat:
        @"Pixel distance   %.2f px", model.pixelDistance];
    self.stateField.stringValue = [NSString stringWithFormat:
        @"Input state   %@", MedisaleInputStateText(model.inputState)];
    self.bindingField.stringValue = self.bound
        ? @"Binding   owning Viewer / current synthetic image"
        : @"Binding   unbound";
    [self updateGuideFields];
}

- (void)updateGuideFields
{
    GuideEngine *guideEngine = self.guideEngine;
    if (guideEngine == nil || self.panel == nil) {
        return;
    }
    self.shortInstructionsField.stringValue = guideEngine.shortInstructionsText;
    BOOL enabled = guideEngine.isDetailedGuideEnabled;
    self.detailedGuideToggle.state = enabled
        ? NSControlStateValueOn : NSControlStateValueOff;
    self.detailedInstructionsField.stringValue = guideEngine.detailedInstructionsText;
    self.detailedInstructionsField.hidden = !enabled;
}

- (void)detailedGuideToggled:(NSButton *)sender
{
    BOOL enabled = sender.state == NSControlStateValueOn;
    NSError *error = nil;
    if (![self.guideEngine setDetailedGuideEnabled:enabled error:&error]) {
        (void)error;
        NSBeep();
    }
    [self updateGuideFields];
}

- (void)followViewerWindow
{
    NSWindow *viewerWindow = self.viewer.window;
    NSPanel *panel = self.panel;
    if (viewerWindow == nil || panel == nil) {
        return;
    }
    NSRect viewerFrame = viewerWindow.frame;
    NSScreen *screen = viewerWindow.screen ?: NSScreen.mainScreen;
    NSRect visibleFrame = screen.visibleFrame;
    NSSize panelSize = panel.frame.size;
    CGFloat x = NSMaxX(viewerFrame) + 8.0;
    if (x + panelSize.width > NSMaxX(visibleFrame)) {
        x = MAX(NSMinX(visibleFrame), NSMaxX(viewerFrame) - panelSize.width - 12.0);
    }
    CGFloat y = NSMaxY(viewerFrame) - panelSize.height;
    y = MIN(MAX(y, NSMinY(visibleFrame)), NSMaxY(visibleFrame) - panelSize.height);
    [panel setFrameOrigin:NSMakePoint(x, y)];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if (notification.object == self.panel && self.bound) {
        self.userClosed = YES;
    }
}

- (void)invalidate
{
    if (!self.bound && self.panel == nil && self.observers.count == 0 &&
        self.model == nil && self.viewer == nil) {
        return;
    }
    self.bound = NO;
    [self updateFields];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    for (id observer in self.observers) {
        [center removeObserver:observer];
    }
    [self.observers removeAllObjects];
    self.panel.delegate = nil;
    [self.panel close];
    self.panel = nil;
    self.pointAField = nil;
    self.pointBField = nil;
    self.distanceField = nil;
    self.stateField = nil;
    self.bindingField = nil;
    self.shortInstructionsField = nil;
    self.detailedGuideToggle = nil;
    self.detailedInstructionsField = nil;
    self.model = nil;
    self.guideEngine = nil;
    self.viewer = nil;

    MedisalePanelHostInvalidation invalidation = self.invalidation;
    self.invalidation = nil;
    if (invalidation != nil) {
        invalidation();
    }
}

- (void)dealloc
{
    [self invalidate];
}

@end
