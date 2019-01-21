//
//  Son.m
//  objc-debug
//
//  Created by admin on 2018/12/27.
//

#import "Son.h"

@interface Son()


@end


@implementation Son

- (instancetype)init{
    self = [super init];
    if (self) {
//        NSLog(@"%@",NSStringFromClass([self class]));
//        NSLog(@"%@",NSStringFromClass([super class]));
        
        
    
    }
    return self;
}


- (void)speak {
    NSLog(@"my name is %@",self.name);
}
@end
