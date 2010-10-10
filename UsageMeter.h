#import <Foundation/Foundation.h>
#import <CoreFoundation/CFDate.h>

@interface UsageMeter : NSObject {
}

- (NSString *) refresh:(NSString*)username withPassword:(NSString*)password;

- (unsigned long) usageMB;
- (unsigned long) bandwMB;
- (unsigned long) freeMB;
- (unsigned long) billppercent;
- (unsigned long) billpday;
- (unsigned long) billpdaysleft;
- (unsigned long) percent;
- (int) printjson;
@end
