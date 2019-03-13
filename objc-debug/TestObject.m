//
//  TestObject.m
//  objc-debug
//
//  Created by quan on 2018/10/18.
//

#import "TestObject.h"

@interface TestObject()
@property (nonatomic, strong) NSObject *testObj;

@end


@implementation TestObject

+ (instancetype)createTestObject{
    return [self new];
}

- (void)testWeak{
    NSObject *obj1 = [[NSObject alloc] init];
    self.testObj = obj1;
    //    _objc_autoreleasePoolPrint();
//    id __weak obj = obj1; //用block不会多次注册到autoreleasepool中去
    //    id tmp = obj;
    NSLog(@"1 %@",obj1);
}

@end
