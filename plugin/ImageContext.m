#import "ImageContext.h"

@implementation ImageContext

- (instancetype)initWithStudyInstanceUID:(NSString *)studyInstanceUID
                       seriesInstanceUID:(NSString *)seriesInstanceUID
                          sopInstanceUID:(NSString *)sopInstanceUID
                             frameNumber:(NSInteger)frameNumber
                              pixelWidth:(NSInteger)pixelWidth
                             pixelHeight:(NSInteger)pixelHeight
                           pixelSpacingX:(double)pixelSpacingX
                           pixelSpacingY:(double)pixelSpacingY
{
    self = [super init];
    if (self) {
        _studyInstanceUID = [studyInstanceUID copy];
        _seriesInstanceUID = [seriesInstanceUID copy];
        _sopInstanceUID = [sopInstanceUID copy];
        _frameNumber = frameNumber;
        _pixelWidth = pixelWidth;
        _pixelHeight = pixelHeight;
        _pixelSpacingX = pixelSpacingX;
        _pixelSpacingY = pixelSpacingY;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
