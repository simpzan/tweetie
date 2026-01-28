// See http://iphonedevwiki.net/index.php/Logos

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <UIKit/UIKit.h>


// static NSMutableDictionary *activeBackgroundTasks = nil;
// static NSLock *activeBackgroundTasksLock = nil;
// static void initBackgroundTasksTracking() {
//     static dispatch_once_t onceToken;
//     dispatch_once(&onceToken, ^{
//         activeBackgroundTasks = [[NSMutableDictionary alloc] init];
//         activeBackgroundTasksLock = [[NSLock alloc] init];
//     });
// }
// static void dumpActiveBackgroundTasks() {
//     NSLog(@"[sam] Active background tasks (%lu total):", (unsigned long)activeBackgroundTasks.count);
//     for (NSNumber *taskId in activeBackgroundTasks) {
//         NSDictionary *taskInfo = activeBackgroundTasks[taskId];
//         NSLog(@"[sam]   Task ID %@: %@", taskId, taskInfo);
//     }
// }
// %hook UIApplication
// - (UIBackgroundTaskIdentifier)beginBackgroundTaskWithName:(NSString *)taskName expirationHandler:(void (^)(void))handler {
//     UIBackgroundTaskIdentifier taskId = %orig;

//     initBackgroundTasksTracking();
//     [activeBackgroundTasksLock lock];
//     id task = activeBackgroundTasks[@(taskId)] = [@{
//         @"taskId": @(taskId),
//         @"name": taskName,
//         @"startTime": [NSDate date],
//         @"backgroundTimeRemaining": @([self backgroundTimeRemaining]),
//     } mutableCopy];
//     NSLog(@"[sam] + %@", task);
//     [activeBackgroundTasksLock unlock];

//     return taskId;
// }
// - (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
//     [activeBackgroundTasksLock lock];
//     dumpActiveBackgroundTasks();
//     NSNumber *taskIdKey = @(identifier);
//     NSMutableDictionary *taskInfo = activeBackgroundTasks[taskIdKey];
//     [activeBackgroundTasks removeObjectForKey:taskIdKey];

//     NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:taskInfo[@"startTime"]];
//     taskInfo[@"duration"] = @(duration);
//     taskInfo[@"state"] = @"stopped";

//     NSLog(@"[sam] - %@", taskInfo);
//     [activeBackgroundTasksLock unlock];

//     %orig;
// }
// %end

%hook UIApplication
- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithName:(NSString *)taskName
            expirationHandler:(void (^)(void))handler {
    if ([self backgroundTimeRemaining] < 3) {
        NSLog(@"[sam] bg time < 3s, return invalid");
        return UIBackgroundTaskInvalid;
    }
    return %orig;
}
%end

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
