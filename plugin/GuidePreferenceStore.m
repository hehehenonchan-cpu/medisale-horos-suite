#import "GuidePreferenceStore.h"

NSString *const MedisaleGuidePreferenceApplicationIdentifier =
    @"jp.medisale.horos.pluginfilter-spike.guide";
NSString *const MedisaleDetailedGuidePreferenceKey = @"detailedGuideEnabled";

static NSString *const MedisaleGuidePreferenceErrorDomain =
    @"jp.medisale.horos.pluginfilter-spike.guide.error";

@interface CFPreferencesGuidePreferenceStore ()
@property(nonatomic, copy) NSString *applicationIdentifier;
@property(nonatomic, copy) NSString *key;
@property(nonatomic) BOOL defaultValue;
@property(nonatomic, readwrite, getter=isDetailedGuideEnabled) BOOL detailedGuideEnabled;
@end

@implementation CFPreferencesGuidePreferenceStore

- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                                           key:(NSString *)key
                                  defaultValue:(BOOL)defaultValue
{
    self = [super init];
    if (self) {
        _applicationIdentifier = [applicationIdentifier copy];
        _key = [key copy];
        _defaultValue = defaultValue;
        _detailedGuideEnabled = [self readDetailedGuideEnabled];
    }
    return self;
}

- (BOOL)readDetailedGuideEnabled
{
    CFTypeRef value = CFPreferencesCopyValue(
        (__bridge CFStringRef)self.key,
        (__bridge CFStringRef)self.applicationIdentifier,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost);
    BOOL enabled = self.defaultValue;
    if (value != NULL && CFGetTypeID(value) == CFBooleanGetTypeID()) {
        enabled = CFBooleanGetValue((CFBooleanRef)value);
    }
    if (value != NULL) {
        CFRelease(value);
    }
    return enabled;
}

- (BOOL)setDetailedGuideEnabled:(BOOL)enabled error:(NSError **)error
{
    CFPreferencesSetValue(
        (__bridge CFStringRef)self.key,
        enabled ? kCFBooleanTrue : kCFBooleanFalse,
        (__bridge CFStringRef)self.applicationIdentifier,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost);
    BOOL synchronized = CFPreferencesSynchronize(
        (__bridge CFStringRef)self.applicationIdentifier,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost);
    if (!synchronized) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:MedisaleGuidePreferenceErrorDomain
                                         code:1
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"The detailed-guide preference could not be synchronized."
            }];
        }
        return NO;
    }

    BOOL persisted = [self readDetailedGuideEnabled];
    if (persisted != enabled) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:MedisaleGuidePreferenceErrorDomain
                                         code:2
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"The detailed-guide preference could not be verified."
            }];
        }
        return NO;
    }
    self.detailedGuideEnabled = persisted;
    return YES;
}

@end
