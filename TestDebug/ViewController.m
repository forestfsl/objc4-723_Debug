//
//  ViewController.m
//  TestDebug
//
//  Created by admin on 2018/9/4.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    @autoreleasepool {
//        id __strong obj = [[NSObject alloc] init];
//        _objc_autoreleasePoolPrint();
//        id __weak o = obj;
//        NSLog(@"before using __weak: retain count = %d", _objc_rootRetainCount(obj));
//        NSLog(@"class = %@", [o class]); //根据书中描述，访问weak 变量，其引用对象被自动加入autoreleasepool
//        NSLog(@"after using __weak: retain count = %d", _objc_rootRetainCount(o));//如果obj 被加入autoreleasepool 那么此时引用计数应该是2
//        _objc_autoreleasePoolPrint();//这里应该显示 obj对象已被加入了当前的autoreleasepool，但是并没有。
//    }
    
    // Do any additional setup after loading the view.
//     NSString *string = [NSString stringWithFormat:@"leichunfeng"];
//    NSLog(@"########retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(string)));
    NSObject *obj1 = [[NSObject alloc] init];
//    _objc_autoreleasePoolPrint();
    id __weak obj = obj1; //用block不会多次注册到autoreleasepool中去
//    id tmp = obj;
    NSLog(@"1 %@",obj);
    NSLog(@"2 %@",obj);
    NSLog(@"3 %@",obj);
    NSLog(@"4 %@",obj);
    NSLog(@"5 %@",obj);
//    _objc_autoreleasePoolPrint();
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
