#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLMArray (Utilities)

- (void)addObjectNonGeneric:(RLMObject *)object;

- (NSArray<RLMObject *> *)allObjects;

@end

NS_ASSUME_NONNULL_END
