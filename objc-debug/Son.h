//
//  Son.h
//  objc-debug
//
//  Created by admin on 2018/12/27.
//

#import "Father.h"


@protocol SonDelegate <NSObject>

- (void)test;

@end

NS_ASSUME_NONNULL_BEGIN

@interface Son : Father

@property (nonatomic, copy) NSString *name;

- (void)speak;

+ (void)run;

@end

NS_ASSUME_NONNULL_END
