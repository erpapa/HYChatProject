//
//  HYQNAuthPolicy.h
//  HYChatProject
//
//  Created by erpapa on 16/5/9.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

// Qiniu
#define QN_AK @"TRT89r9Z4-kTdaQyO2ptrTr67I2GkP4aVHWg43ds"
#define QN_SK @"Ynl7RZbbfk-S9vdGwJtRpcQmKsb1GwDT8XBXmqPy"
#define QN_SCOPE @"erpapa"
#define QN_UploadHost @"http://upload.qiniu.com"
#define QN_FullURL(key) [NSString stringWithFormat:@"http://7xpppr.com1.z0.glb.clouddn.com/%@", key]
#define QN_STATUS_CODE_SUCCESS 200

@interface HYQNAuthPolicy : NSObject

@property (nonatomic, copy) NSString *scope;
@property (nonatomic, copy) NSString *callbackUrl;
@property (nonatomic, copy) NSString *callbackBodyType;
@property (nonatomic, copy) NSString *customer;
@property (nonatomic, assign) long long expires;
@property (nonatomic, assign) long long escape;

+ (NSString *)defaultToken;
+ (NSString *)tokenWithScope:(NSString *)scope;
- (NSString *)makeToken:(NSString *)accessKey secretKey:(NSString *)secretKey;

@end
