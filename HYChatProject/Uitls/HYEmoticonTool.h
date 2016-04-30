//
//  HYEmoticonTool.h
//  HYChatProject
//
//  Created by erpapa on 16/4/29.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYEmoticonTool : NSObject

@property (nonatomic, strong, readonly) NSDictionary *emoticonDict;         // 所有表情组成的字典
@property (nonatomic, strong, readonly) NSArray *emoticonArray;             // 表情数组
@property (nonatomic, strong, readonly) NSRegularExpression *emoticonRegex; // 表情正则

+ (instancetype)sharedInstance;
/**
 *  图片路径
 */
- (NSString *)imagePathForkey:(NSString *)key;
/**
 *  gif路径
 */
- (NSString *)gifPathForKey:(NSString *)key;
@end
