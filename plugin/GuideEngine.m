#import "GuideEngine.h"

#import "GuidePreferenceStore.h"

NSNotificationName const GuideEngineDidChangeNotification =
    @"MedisaleGuideEngineDidChangeNotification";

@interface GuideEngine ()
@property(nonatomic, strong) id<GuidePreferenceStore> preferenceStore;
@property(nonatomic, copy, readwrite) NSString *shortInstructionsText;
@property(nonatomic, copy, readwrite) NSString *detailedInstructionsText;
@property(nonatomic, readwrite, getter=isDetailedGuideEnabled) BOOL detailedGuideEnabled;
@end

@implementation GuideEngine

- (instancetype)initWithPreferenceStore:(id<GuidePreferenceStore>)preferenceStore
{
    self = [super init];
    if (self) {
        _preferenceStore = preferenceStore;
        _shortInstructionsText =
            @"1. Select two points.\n"
             "2. Drag an endpoint to adjust it.\n"
             "3. Press Escape to cancel the current operation.";
        _detailedInstructionsText =
            @"Select points inside the displayed image.\n"
             "Drag only a highlighted endpoint; other drags remain available to the active Horos tool.\n"
             "The guide setting applies to every measurement inspector for this user.";
        _detailedGuideEnabled = preferenceStore.isDetailedGuideEnabled;
    }
    return self;
}

- (BOOL)setDetailedGuideEnabled:(BOOL)enabled error:(NSError **)error
{
    if (self.detailedGuideEnabled == enabled) {
        return YES;
    }
    if (![self.preferenceStore setDetailedGuideEnabled:enabled error:error]) {
        return NO;
    }
    self.detailedGuideEnabled = self.preferenceStore.isDetailedGuideEnabled;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:GuideEngineDidChangeNotification object:self];
    return YES;
}

@end
