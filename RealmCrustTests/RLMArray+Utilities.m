#import "RLMArray+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RLMArray (Utilities)

- (void)addObjectNonGeneric:(RLMObject *)object
{
    [self addObject:object];
}

- (NSArray<RLMObject *> *)allObjects
{
    NSMutableArray *objects = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < self.count; i++)
    {
        [objects addObject:[self objectAtIndex:i]];
    }
    
    return objects;
}

@end

NS_ASSUME_NONNULL_END
