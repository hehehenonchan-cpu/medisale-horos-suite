#import "MeasurementContextConsumer.h"
#import "ImageContext.h"

NSString *MedisaleMeasurementSummary(ImageContext *context)
{
    return [NSString stringWithFormat:
        @"Study UID: %@\nSeries UID: %@\nSOP UID: %@\nFrame: %ld\nPixels: %ld x %ld\nSpacing: %.6g x %.6g",
        context.studyInstanceUID,
        context.seriesInstanceUID,
        context.sopInstanceUID,
        (long)context.frameNumber,
        (long)context.pixelWidth,
        (long)context.pixelHeight,
        context.pixelSpacingX,
        context.pixelSpacingY];
}
