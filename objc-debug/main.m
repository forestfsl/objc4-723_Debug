//
//  main.m
//  objc-debug
//
//  Created by quan on 2018/10/18.
//

#import <Foundation/Foundation.h>
#import "TestObject.h"
#import <objc/runtime.h>
#import "Son.h"

NSString *binaryWithInteger(NSUInteger decInt){
    NSString *string = @"";
    NSUInteger x = decInt;
//    NSLog(@"decInt:%lu",(unsigned long)decInt);
    while (x > 0) {
        string = [[NSString stringWithFormat:@"%lu",x&1] stringByAppendingString:string];
//        NSLog(@"string:%@",string);
        x = x >> 1;
//        NSLog(@"➡️移之后的x值:%lu",x);
    }
    return string;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
//        NSNumber *number1 = @1;
//        NSNumber *number2 = @2;
//        NSNumber *number3 = @3;
//        NSNumber *numberFFFF = @(0xFFFF);
//
//        NSLog(@"number1 pointer is %p", number1);
//        NSLog(@"number2 pointer is %p", number2);
//        NSLog(@"number3 pointer is %p", number3);
//        NSLog(@"numberffff pointer is %p", numberFFFF);
//        NSLog(@"Hello, World!");
//        TestObject *obj = [[TestObject alloc] init];
//        [obj isKindOfClass:[NSArray class]];
//        [obj testWeak];
        
//        NSString *a = @"a";
//        NSString *b = [[a mutableCopy] copy];
//        NSLog(@"%p %p %@", a, b, object_getClass(b));
    
//        NSMutableString *mutable = [NSMutableString string];
//        NSString *immutable;
//        char c = 'a';
//        do {
//            [mutable appendFormat: @"%c", c++];
//            immutable = [mutable copy];
//           NSLog(@"0x%016lx %@ %@", immutable, immutable, object_getClass(immutable));
//        } while(((uintptr_t)immutable & 1) == 1);
        
        Son *sonObject = [[Son alloc]init];
        sonObject.name = @"测试resizeClass方法";
        [sonObject speak];
        NSLog(@"测试[self class] 与[super class]:%@",sonObject);
//
//        BOOL res1 = [(id)[NSObject class] isKindOfClass:[NSObject class]];
//        BOOL res2 = [(id)[NSObject class] isMemberOfClass:[NSObject class]];
//
//        BOOL res3 = [(id)[Son class] isKindOfClass:[Son class]];
//        BOOL res4 = [(id)[Son class] isMemberOfClass:[Son class]];
//
//        BOOL res5  =   [(id)sonObject isKindOfClass:[Son class]];
//        NSLog(@"%d %d %d %d %d", res1, res2, res3, res4,res5);
        
//        struct objc_object *object = (__bridge struct objc_object *)([NSObject new]);
//        NSLog(@"yyy%@",binaryWithInteger(object->isa));
//        NSLog(@"xx%@",binaryWithInteger((uintptr_t)[NSObject class]));
        
        
    
    }
    return 0;
}
