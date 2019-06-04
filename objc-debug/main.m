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
#import "NSObject.h"
#import <malloc/malloc.h>
//#import "hashtable2.h"

@interface XXObject : NSObject

@end

@implementation XXObject

+ (void)load{
    NSLog(@"XXObject load");
}

@end

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

@interface Person : NSObject
{
@public
    int _age1;
}
//@property (nonatomic, assign) int height;
@end

@implementation Person

@end

@interface Student : Person
{
@public
    int _no;
    int _age;
    
}

@end

@implementation Student

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        //测试Pointer Tagger
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
//
        

//        NSMutableString *mutable = [NSMutableString string];
//        NSString *immutable;
//        char c = 'a';
//        do {
//            [mutable appendFormat: @"%c", c++];
//            immutable = [mutable copy];
//           NSLog(@"0x%016lx %@ %@", immutable, immutable, object_getClass(immutable));
//        } while(((uintptr_t)immutable & 1) == 1);
        
//##########################################################################################
        //测试运行时
//        Son *sonObject = [[Son alloc]init];
//        sonObject.name = @"测试resizeClass方法";
//        [sonObject speak];
//        NSLog(@"测试[self class] 与[super class]:%@",sonObject);
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
        
//##########################################################################################
        //测试NXHashTable的性能
        
//        NSArray<NSNumber *> *capacities = @[
//                                            @100,
//                                            @1000,
//                                            @10000,
//                                            @100000,
//                                            @1000000,
//                                            @2000000,
//                                            @3000000,
//                                            @5000000,
//                                            @10000000
//                                            ];
//        
//        for (NSNumber *capacity in capacities) {
//            NXHashTable *hashTable = NXCreateHashTable(NXPtrPrototype, 0, NULL);
//            NSDate *methodStart = [NSDate date];
//            for (NSInteger i = 0; i < capacity.integerValue; i++) {
//                NSString *value = [NSString stringWithFormat:@"%ld", (long)i];
//                NXHashInsert(hashTable, (__bridge void *)value);
//            }
//            NSDate *methodFinish = [NSDate date];
//            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
//            NSLog(@"Capacities: %@, executionTime = %f, meanTime = %.10f", capacity, executionTime, executionTime / capacity.integerValue);
//            
//            free(hashTable);
//        }
        //但是上面在算法上面会有点问题，就是每次遍历的时候，传入的参数capacity都是0，这样会带来很多的Rehash，会影响性能呢，既然这种情况下，我们知道数组的capacities里面的数量，我们可以在init创建的hashTable的时候，直接传入capacity.integer,这样在一定的程度上面应该会提高性能的
//##########################################################################################
        //整个 objc/runtime 中，作为私有的数据结构 NXHashTable，直接使用了它的就是存储所有类或者元类的哈希表（在这里会忽略对元类的存储，因为实现几乎完全相同）：
//        unsigned int outCount;
//        Class *cls = objc_copyClassList(&outCount);
//        for (NSInteger i = 0; i < outCount; i++) {
//            Class currentClass = cls[i];
//            NSLog(@"%p:%@",currentClass,NSStringFromClass(currentClass));
//        }
 //##########################################################################################
        //测试关联对象
//        NSObject *obj = [NSObject new];
//        objc_setAssociatedObject(obj, @selector(hello), @"Hello", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
         //##########################################################################################
        
        //测试objc_autoreleasePoolPop 传入非哨兵对象，测试一下这个方法的行为
//        NSString *s = @"fengsonglin";
//        [s stringByAppendingString:@"-Test"];
  //##########################################################################################
        //测试ARC的优化方法 https://www.jianshu.com/p/2f05060fa377 https://blog.sunnyxx.com/2014/10/15/behind-autorelease/
//        TestObject *testObject = [TestObject createTestObject];
//        NSArray *array = [NSArray array];
      //##########################################################################################
        //测试load方法 设置一个Symbolic Breakpoint ,然后在Symbol这一行上面输入了+[XXObject load],然后Comand + r运行，查看左边的堆栈信息，可以发现load方法的调用栈是
//        11_dyld_start dyld 是 the dynamic link editor 的缩写，它是苹果的动态链接器。
//        4 dyld::notifiSingle(dyld_image_states,ImageLoader const*)
//        3 load_images,每次有新的镜像加载之后，都会执行load_images这个方法进行回调，这里的回调是在整个运行时初始化时_objc_init 注册的 dyld_register_image_state_change_handler(dyld_image_state_dependents_initialized, 0/*not batch*/, &load_images);
//        2 call_load_methods()
//        1 call_class_loads()
//        0 +[XXObject load]
//        问题：load方法是如何被调用的？
//        当 Objective-C 运行时初始化的时候，会通过 dyld_register_image_state_change_handler 在每次有新的镜像加入运行时的时候，进行回调。执行 load_images 将所有包含 load 方法的文件加入列表 loadable_classes ，然后从这个列表中找到对应的 load 方法的实现，调用 load 方法
        
//        add_class_to_loadable_list 方法负责将类加入 loadable_classes 集合，而 call_class_loads 负责消费集合中的元素
    }
    
    Student *stu = [[Student alloc] init];
    stu->_age1 = 9;
    stu->_no = 4;
    stu->_age = 5;
    NSLog(@"stu - %zd", class_getInstanceSize([Student class]));
    NSLog(@"stu - %zd", malloc_size((__bridge const void *)stu));
    
    getchar();
    return 0;
}
