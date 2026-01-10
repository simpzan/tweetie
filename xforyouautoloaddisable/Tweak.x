// See http://iphonedevwiki.net/index.php/Logos

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <UIKit/UIKit.h>


static int shouldSkipRequest(NSURL *url) {
    BOOL isHomeTimeline = [url.lastPathComponent isEqualToString:@"HomeTimeline"];
    if (!isHomeTimeline) return NO;

    BOOL hasCursorKey = [url.query rangeOfString:@"%22cursor%22%3A%22"].location != NSNotFound;
    if (!hasCursorKey) return NO;

    static NSDate *lastTime = NULL;
    if (!lastTime) lastTime = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate *currentDate = [NSDate date];
    BOOL shouldSkip = [currentDate timeIntervalSinceDate:lastTime] < 6 * 60 * 60;
    if (shouldSkip) return YES;

    lastTime = currentDate;
    return NO;
}
%hook NSURLSessionTask
- (void)resume {
    NSURLRequest *request = self.originalRequest;
    NSURL *url = request.URL;
    BOOL shouldSkip = shouldSkipRequest(url);
//    NSString *action = shouldSkip ? @"skip" : @"resume";
//    NSLog(@"[sam] %@ %@", action, url);
    if (!shouldSkip) %orig;
}
%end
