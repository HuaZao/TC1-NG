//
//  MQTTModel.m
//  TC1-NG
//
//  Created by QAQ on 2019/4/25.
//  Copyright © 2019 TC1. All rights reserved.
//

#import "MQTTModel.h"
#import "LKDBHelper.h"

@implementation MQTTModel

+ (NSString *)getPrimaryKey{
    return @"clientId";
}

@end
