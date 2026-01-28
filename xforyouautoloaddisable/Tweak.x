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

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = @"xforyouautoloaddisable_lastTime";
    static NSDate *lastTime = NULL;
    if (!lastTime) {
        NSTimeInterval lastTimestamp = [defaults doubleForKey:key];
        lastTime = [NSDate dateWithTimeIntervalSince1970:lastTimestamp];
    }
    NSDate *currentDate = [NSDate date];
    BOOL shouldSkip = [currentDate timeIntervalSinceDate:lastTime] < 3 * 60 * 60;
    if (shouldSkip) return YES;

    lastTime = currentDate;
    [defaults setDouble:[currentDate timeIntervalSince1970] forKey:key];
    return NO;
}
%hook NSURLSessionTask
- (void)resume {
    NSURLRequest *request = self.originalRequest;
    NSURL *url = request.URL;
    BOOL shouldSkip = shouldSkipRequest(url);
    NSString *action = shouldSkip ? @"skip" : @"resume";
    if (!shouldSkip) {
        %orig;
        return;
    }
    NSLog(@"[sam] %@ %@", action, url);
}
%end
