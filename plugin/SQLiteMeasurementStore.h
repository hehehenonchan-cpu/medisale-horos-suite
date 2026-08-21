#import <Foundation/Foundation.h>

#import "MeasurementPersistenceStore.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const MedisaleMeasurementPersistenceErrorDomain;

typedef NS_ENUM(NSInteger, MedisaleSQLiteFailureInjection) {
    MedisaleSQLiteFailureInjectionNone = 0,
    MedisaleSQLiteFailureInjectionConstraint,
    MedisaleSQLiteFailureInjectionStatement,
    MedisaleSQLiteFailureInjectionBeforeCommit,
    MedisaleSQLiteFailureInjectionInterruptedSave,
};

@interface SQLiteMeasurementStore : NSObject <MeasurementPersistenceStore>

@property(nonatomic, readonly) NSURL *databaseURL;
@property(nonatomic) MedisaleSQLiteFailureInjection failureInjection;

+ (nullable instancetype)pluginOwnedStoreWithError:
    (NSError * _Nullable * _Nullable)error;
- (nullable instancetype)initWithDatabaseURL:(NSURL *)databaseURL
                                       error:(NSError * _Nullable * _Nullable)error
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
