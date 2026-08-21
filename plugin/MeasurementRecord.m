#import "MeasurementRecord.h"

#import "ImageContext.h"

const NSInteger MedisaleMeasurementSchemaVersion = 1;

@implementation MeasurementRecord

- (instancetype)initWithMeasurementID:(NSString *)measurementID
                          imageContext:(ImageContext *)imageContext
                             endpointAX:(double)endpointAX
                             endpointAY:(double)endpointAY
                             endpointBX:(double)endpointBX
                             endpointBY:(double)endpointBY
                           pixelDistance:(double)pixelDistance
                           schemaVersion:(NSInteger)schemaVersion
                               createdAt:(NSDate *)createdAt
                               updatedAt:(NSDate *)updatedAt
{
    self = [super init];
    if (self) {
        _measurementID = [measurementID copy];
        _imageContext = [imageContext copy];
        _endpointAX = endpointAX;
        _endpointAY = endpointAY;
        _endpointBX = endpointBX;
        _endpointBY = endpointBY;
        _pixelDistance = pixelDistance;
        _schemaVersion = schemaVersion;
        _createdAt = [createdAt copy];
        _updatedAt = [updatedAt copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
