#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageContext : NSObject <NSCopying>

@property(nonatomic, copy, readonly) NSString *studyInstanceUID;
@property(nonatomic, copy, readonly) NSString *seriesInstanceUID;
@property(nonatomic, copy, readonly) NSString *sopInstanceUID;
@property(nonatomic, readonly) NSInteger frameNumber;
@property(nonatomic, readonly) NSInteger pixelWidth;
@property(nonatomic, readonly) NSInteger pixelHeight;
@property(nonatomic, readonly) double pixelSpacingX;
@property(nonatomic, readonly) double pixelSpacingY;

- (instancetype)initWithStudyInstanceUID:(NSString *)studyInstanceUID
                       seriesInstanceUID:(NSString *)seriesInstanceUID
                          sopInstanceUID:(NSString *)sopInstanceUID
                             frameNumber:(NSInteger)frameNumber
                              pixelWidth:(NSInteger)pixelWidth
                             pixelHeight:(NSInteger)pixelHeight
                           pixelSpacingX:(double)pixelSpacingX
                           pixelSpacingY:(double)pixelSpacingY NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
