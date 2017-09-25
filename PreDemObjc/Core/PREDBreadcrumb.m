//
//  PREDBreadcrumb.m
//  Pods
//
//  Created by 王思宇 on 13/09/2017.
//
//

#import "PREDBreadcrumb.h"
#import "PREDHelper.h"

@implementation PREDBreadcrumb

- (instancetype)initWithCategory:(NSString *)category
                            Type:(NSString *)type
                         message:(NSString *)message
                            data:(NSDictionary<NSString *, id> *)data; {
    if (self = [self init]) {
        _category = category;
        _type = type;
        _message = message;
        _data = data;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _timestamp = [NSDate date].timeIntervalSince1970;
    }
    return self;
}

@end