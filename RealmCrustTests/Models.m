#import "Models.h"

@implementation Employee

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[Employee class]])
    {
        return NO;
    }
    
    return [self isEqualToObject:object];
}

@end

@implementation Company

+ (NSString *)primaryKey {
    return @"uuid";
}

@end

@implementation PrimaryObj1

+ (NSString *)primaryKey {
    return @"uuid";
}

@end

@implementation PrimaryObj2

+ (NSString *)primaryKey {
    return @"uuid";
}

@end

@implementation DatePrimaryObj

+ (NSString *)primaryKey {
    return @"remoteId";
}

@end
