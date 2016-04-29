//
//  HYEmoticonTool.h
//  HYChatProject
//
//  Created by erpapa on 16/4/29.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYEmoticonTool : NSObject

@property (nonatomic, strong) NSDictionary *emoticonDict;
@property (nonatomic, strong) NSArray *emoticonArray;
@property (nonatomic, strong) NSRegularExpression *emoticonRegex;

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
