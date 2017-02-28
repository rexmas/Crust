#import <Realm/Realm.h>

@class Company;

NS_ASSUME_NONNULL_BEGIN

@interface Employee : RLMObject

@property (nullable) NSString *uuid;
@property (nullable) NSString *name;
@property (nullable) NSDate *joinDate;
@property (nullable) NSNumber<RLMInt> *salary;
@property (nullable) NSNumber<RLMBool> *isEmployeeOfMonth;
@property (nullable) NSNumber<RLMDouble> *percentYearlyRaise;
@property (nullable) Company *employer;

@end
RLM_ARRAY_TYPE(Employee)

@interface Company : RLMObject

@property (nullable) NSString *uuid;
@property (nullable) NSString *name;
@property (nullable) NSDate *foundingDate;
@property (nullable) NSNumber<RLMInt> *pendingLawsuits;
@property (nullable) Employee *founder;
@property RLMArray<Employee *><Employee> *employees;

@end

@class PrimaryObj1;

@interface PrimaryObj2 : RLMObject

@property (nullable) NSString *uuid;
@property (nullable) PrimaryObj1 *class1;

@end
RLM_ARRAY_TYPE(PrimaryObj2)

@interface PrimaryObj1 : RLMObject

@property (nullable) NSString *uuid;
@property RLMArray<PrimaryObj2 *><PrimaryObj2> *class2s;

@end

NS_ASSUME_NONNULL_END

@interface DatePrimaryObj : RLMObject

@property (nullable) NSNumber<RLMInt> *remoteId;
@property (nullable) NSDate *date;
@property (nullable) NSString *junk;

@end
