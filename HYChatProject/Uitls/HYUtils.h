//
//  HYUtils.h
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XMPPvCardTemp;
@interface HYUtils : NSObject
/**
 *  切换控制器
 */
+ (void)initRootViewController;

/**
 *  当前用户的名片
 */
+ (XMPPvCardTemp *)currentUservCard;
+ (void)saveCurrentUservCard:(XMPPvCardTemp *)vCard;

/**
 *  hud
 */
+ (void)showWaitingMsg:(NSString *)msg;
+ (void)clearWaitingMsg;
+ (void)clearWaitingMsgWithDelay:(float)delay;
+ (void)alertWithTitle:(NSString *)title;
+ (void)alertWithNormalMsg:(NSString *)msg;
+ (void)alertWithSuccessMsg:(NSString *)msg;
+ (void)alertWithErrorMsg:(NSString *)msg;

/**
 *  颜色
 */
+ (NSString *)stringFromColor:(UIColor*)aColor;
+ (UIColor *)colorFromString:(NSString*)aString;

/**
 *  路径
 */
+ (NSString *)localPath:(NSString *)key;
+ (NSString *)bundlePath:(NSString *)fileName;
+ (NSString *)audioTempEncodeFilePath:(NSString *)key;
+ (NSString *)audioCachePath:(NSString *)key;
+ (NSString *)videoCachePath:(NSString *)key;

/**
 *  badgeValue
 */
+ (NSString *)stringFromUnreadCount:(int)count;
/**
 *  在线、忙碌、离线
 */
+ (NSString *)stringFromSectionNum:(NSInteger)sectionNum;
/**
 *  时间
 */
+ (NSString *)sampleTimeStringSince1970:(double)secs;
+ (NSString *)timeStringSince1970:(double)secs;
+ (NSString *)timeStringFromDate:(NSDate *)date;
+ (NSString *)currentTimeStampString;

/**
 *  生成七牛云上传文件key
 */
// keyPrefix_yyyy-MM-dd_HH-mm-ss.jpg
+ (NSString *)generateImageKeyWithPrefix:(NSString *)keyPrefix;

@end
