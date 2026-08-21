#import <Foundation/Foundation.h>

@class MeasurementRecord;
@class ImageContext;

NS_ASSUME_NONNULL_BEGIN

@protocol MeasurementPersistenceStore <NSObject>

- (BOOL)saveMeasurement:(MeasurementRecord *)measurement
                   error:(NSError * _Nullable * _Nullable)error;

- (nullable MeasurementRecord *)latestMeasurementForImageContext:
    (ImageContext *)imageContext
    error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
