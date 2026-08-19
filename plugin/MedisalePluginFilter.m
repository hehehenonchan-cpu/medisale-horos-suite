#import <Cocoa/Cocoa.h>
#import <PluginFilter.h>

@interface MedisalePluginFilter : PluginFilter
@end

@implementation MedisalePluginFilter

- (long)filterImage:(NSString *)menuName
{
    (void)menuName;

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Medisale Plugin OK";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];

    return 0;
}

- (BOOL)isCertifiedForMedicalImaging
{
    return NO;
}

@end
