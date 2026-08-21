#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const MedisaleGuidePreferenceApplicationIdentifier;
FOUNDATION_EXPORT NSString *const MedisaleDetailedGuidePreferenceKey;

@protocol GuidePreferenceStore <NSObject>

@property(nonatomic, readonly, getter=isDetailedGuideEnabled) BOOL detailedGuideEnabled;

- (BOOL)setDetailedGuideEnabled:(BOOL)enabled error:(NSError **)error;

@end

@interface CFPreferencesGuidePreferenceStore : NSObject <GuidePreferenceStore>

- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                                           key:(NSString *)key
                                  defaultValue:(BOOL)defaultValue NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
