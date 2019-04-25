//
//  MQTTModel.h
//  TC1-NG
//
//  Created by QAQ on 2019/4/25.
//  Copyright © 2019 TC1. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MQTTModel : NSObject

@property (nonatomic,copy) NSString *clientId;
@property (nonatomic,copy) NSString *host;
@property (nonatomic,assign) NSInteger port;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;

@end

NS_ASSUME_NONNULL_END
