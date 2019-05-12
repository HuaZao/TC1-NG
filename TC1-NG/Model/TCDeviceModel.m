//
//  TCDeviceModel.m
//  TC1-NG
//
//  Created by QAQ on 2019/4/24.
//  Copyright © 2019 TC1. All rights reserved.
//

#import "TCDeviceModel.h"
#import "LKDBHelper.h"

@implementation TCDeviceModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = @"1";
        self.type_name = @"zTC1";
    }
    return self;
}

+ (NSString *)getPrimaryKey{
    return @"mac";
}

@end
