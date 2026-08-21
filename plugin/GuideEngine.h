#import <Foundation/Foundation.h>

@protocol GuidePreferenceStore;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const GuideEngineDidChangeNotification;

@interface GuideEngine : NSObject

@property(nonatomic, copy, readonly) NSString *shortInstructionsText;
@property(nonatomic, copy, readonly) NSString *detailedInstructionsText;
@property(nonatomic, readonly, getter=isDetailedGuideEnabled) BOOL detailedGuideEnabled;

- (instancetype)initWithPreferenceStore:(id<GuidePreferenceStore>)preferenceStore
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)setDetailedGuideEnabled:(BOOL)enabled error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
