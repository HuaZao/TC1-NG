//
//  SocketModel.h
//  TC1-NG
//
//  Created by QAQ on 2019/4/24.
//  Copyright © 2019 TC1. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocketModel : NSObject

@property (nonatomic,copy) NSString *sockeTtitle;
@property (nonatomic,copy) NSString *socketId;
@property (nonatomic,assign) BOOL isOn;
@property (nonatomic,assign) BOOL canEdit;


@end

NS_ASSUME_NONNULL_END
