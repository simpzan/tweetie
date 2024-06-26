// See http://iphonedevwiki.net/index.php/Logos

#import <UIKit/UIKit.h>


@interface BHCustomTabBarUtility: NSObject
+ (NSArray<NSString *> *)getHiddenTabBars;
@end
%hook BHCustomTabBarUtility
+ (NSArray<NSString *> *)getHiddenTabBars {
    NSArray *immutableArray = %orig;
    NSMutableArray *mutableArray = [immutableArray mutableCopy];
    [mutableArray addObject:@"grok"];
    return mutableArray;
}
%end


%hook NSURLSessionTask
- (void)resume {
    NSURLRequest *request = self.originalRequest;
    if ([request.URL.lastPathComponent isEqualToString:@"HomeTimeline"]) {
        static NSDate *lastTime = [NSDate dateWithTimeIntervalSince1970:0];
        NSDate *currentDate = [NSDate date];
        if ([currentDate timeIntervalSinceDate:lastTime] >= 6 * 60 * 60) {
            lastTime = currentDate;
            %orig;
        } else {
            NSLog(@"[sam] skip %@", request.URL);
        }
    } else {
        %orig;
    }
}
%end


@interface CustomViewController

@property (nonatomic, copy) NSString* newProperty;

+ (void)classMethod;

- (NSString*)getMyName;

- (void)newMethod:(NSString*) output;

@end

%hook CustomViewController

+ (void)classMethod
{
	%log;

	%orig;
}

%new
-(void)newMethod:(NSString*) output{
    NSLog(@"This is a new method : %@", output);
}

%new
- (id)newProperty {
    return objc_getAssociatedObject(self, @selector(newProperty));
}

%new
- (void)setNewProperty:(id)value {
    objc_setAssociatedObject(self, @selector(newProperty), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*)getMyName
{
	%log;
    
    NSString* password = MSHookIvar<NSString*>(self,"_password");
    
    NSLog(@"password:%@", password);
    
    [%c(CustomViewController) classMethod];
    
    [self newMethod:@"output"];
    
    self.newProperty = @"newProperty";
    
    NSLog(@"newProperty : %@", self.newProperty);

	return %orig();
}

%end
