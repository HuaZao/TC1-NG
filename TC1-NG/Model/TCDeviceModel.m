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


+ (NSString *)getPrimaryKey{
    return @"mac";
}

@end
