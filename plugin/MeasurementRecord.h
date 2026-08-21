#import <Foundation/Foundation.h>

@class ImageContext;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const NSInteger MedisaleMeasurementSchemaVersion;

@interface MeasurementRecord : NSObject <NSCopying>

@property(nonatomic, copy, readonly) NSString *measurementID;
@property(nonatomic, copy, readonly) ImageContext *imageContext;
@property(nonatomic, readonly) double endpointAX;
@property(nonatomic, readonly) double endpointAY;
@property(nonatomic, readonly) double endpointBX;
@property(nonatomic, readonly) double endpointBY;
@property(nonatomic, readonly) double pixelDistance;
@property(nonatomic, readonly) NSInteger schemaVersion;
@property(nonatomic, copy, readonly) NSDate *createdAt;
@property(nonatomic, copy, readonly) NSDate *updatedAt;

- (instancetype)initWithMeasurementID:(NSString *)measurementID
                          imageContext:(ImageContext *)imageContext
                             endpointAX:(double)endpointAX
                             endpointAY:(double)endpointAY
                             endpointBX:(double)endpointBX
                             endpointBY:(double)endpointBY
                           pixelDistance:(double)pixelDistance
                           schemaVersion:(NSInteger)schemaVersion
                               createdAt:(NSDate *)createdAt
                               updatedAt:(NSDate *)updatedAt NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
