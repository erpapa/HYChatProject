//
//  HYUtils.m
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYUtils.h"
#import "HYLoginInfo.h"
#import "HYChatMessageFrame.h"
#import "XMPPvCardTemp.h"
#import "NSFileManager+SW.h"
#import "SVProgressHUD.h"
#import "HYQNAuthPolicy.h"
#import "HYFirstLoginViewController.h"
#import "HYCurrentLoginViewController.h"
#import "HYTabBarController.h"

@implementation HYUtils
/**
 *  切换控制器
 */
+ (void)initRootViewController
{
    // 1.从沙盒里加载用户的数据到单例
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    if (loginInfo.user.length) {
        // 2.判断用户的登录状态,logon == YES 直接来到主界面
        if(loginInfo.logon){
            // 2.1. 设置根控制器
            [UIApplication sharedApplication].delegate.window.rootViewController = [[HYTabBarController alloc] init];
        }else{
            [UIApplication sharedApplication].delegate.window.rootViewController = [HYCurrentLoginViewController currentLoginViewController];
        }
    } else { // 没有用户信息
        [UIApplication sharedApplication].delegate.window.rootViewController = [HYFirstLoginViewController firstLoginViewController];
    }
    
    
}
/**
 *  获取当前用户的vCard
 */
+ (XMPPvCardTemp *)currentUservCard
{
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[[HYLoginInfo sharedInstance].jid full]];
    if (data.length) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return nil;
}

/**
 *  保存当前用户的vCard
 */
+ (void)saveCurrentUservCard:(XMPPvCardTemp *)vCard
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:vCard];
    if (data.length) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:[[HYLoginInfo sharedInstance].jid full]];
    }
    
}
/**
 *  hud
 */
+ (void)showWaitingMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [self initProgressHUD];
    }
    [SVProgressHUD showWithStatus:msg];
}

+ (void)clearWaitingMsg
{
    [SVProgressHUD dismiss];
}

+ (void)clearWaitingMsgWithDelay:(float)delay
{
    [SVProgressHUD dismissWithDelay:delay];
}

+ (void)alertWithSuccessMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [self initProgressHUD];
    }
    [SVProgressHUD showSuccessWithStatus:msg];
}

+ (void)alertWithErrorMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [self initProgressHUD];
    }
    [SVProgressHUD showErrorWithStatus:msg];
}

+ (void)alertWithTitle:(NSString *)title
{
    if ([SVProgressHUD isVisible] == YES) {
        [HYUtils clearWaitingMsg]; // 隐藏
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

+ (void)alertWithNormalMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [self initProgressHUD];
    }
    [SVProgressHUD showInfoWithStatus:msg];
}

+ (void)initProgressHUD
{
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeNative];
    [SVProgressHUD setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.6]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
 
}
/**
 *  颜色
 */
+ (NSString *)stringFromColor:(UIColor*)aColor
{
    if (!aColor)
    {
        return nil;
    }
    CGFloat r , g, b, a;
    [aColor getRed:&r green:&g blue:&b alpha:&a];
    int rI = r*255;
    int gI = g*255;
    int bI = b*255;
    int aI = a*255;
    long colorInt = aI<<24|rI<<16|gI<<8|bI;
    NSString* str = [NSString stringWithFormat:@"%ld",colorInt];
    return str;
}

+ (UIColor *)colorFromString:(NSString*)aString
{
    if(!aString){
        return nil;
    }
    long long value = [aString longLongValue];
    int a = (int)(value>>24 & 0xFF);
    int r = (int)(value>>16 & 0xFF);
    int g = (int)(value>>8 & 0xFF);
    int b = (int)(value & 0xFF);
    UIColor* color = COLOR(r, g, b, a*1.0/255);
    return color;
}

/**
 *  路径
 */
+ (NSString *)localPath:(NSString *)key
{
    return [[NSFileManager defaultManager] localPath:key];
}

+ (NSString *)bundlePath:(NSString *)fileName
{
    return [[NSFileManager defaultManager] bundlePath:fileName];
}

+ (NSString *)audioTempEncodeFilePath:(NSString *)key
{
    return [self audioCachePath:key];
}

+ (NSString *)audioCachePath:(NSString *)key
{
    NSString *dirPath = [self localPath:@"audioCache"];
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSString stringWithFormat:@"%@/%@",dirPath,key];
}

+ (NSString *)videoCachePath:(NSString *)key
{
    NSString *dirPath = [self localPath:@"videoCache"];
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSString stringWithFormat:@"%@/%@",dirPath,key];
}

/**
 *  badgeValue
 */
+ (NSString *)stringFromUnreadCount:(int)count
{
    NSString *badgeValue = nil;
    if (count == 0) {
        return nil;
    } else if (count > 99) {
        badgeValue = @"99+";
    } else {
        badgeValue = [NSString stringWithFormat:@"%d",count];
    }
    return badgeValue;
}
/**
 *  在线、忙碌、离线
 */
+ (NSString *)stringFromSectionNum:(NSInteger)sectionNum
{
    NSString *sectionStr = @"[在线]";
    switch (sectionNum) {
        case 0:{
            sectionStr = @"[在线]";
            break;
        }
        case 1:{
            sectionStr = @"[忙碌]"; // 隐身/离开
            break;
        }
        case 2:{
            sectionStr = @"[离线]";
            break;
        }
        default:
            break;
    }
    return sectionStr;
}
/**
 *  显示的消息内容
 */
+ (NSString *)bodyFromJsonString:(NSString *)jsonStr
{
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    // NSJSONReadingOptions -> 不可变（NSArray/NSDictionary）
    // NSJSONReadingMutableContainers -> 可变（NSMutableArray/NSMutableDictionary）
    // NSJSONReadingAllowFragments：允许JSON字符串最外层既不是NSArray也不是NSDictionary，但必须是有效的JSON Fragment
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (error) { // 如果解析失败
        return jsonStr;
    }
    HYChatMessageType type = [self typeFromString:dict[@"type"]]; // 默认返回HYChatMessageTypeText
    NSString *bodyString = nil;
    switch (type) {
        case HYChatMessageTypeText:{
            bodyString = dict[@"data"];
            break;
        }
        case HYChatMessageTypeImage:{
            bodyString = @"[图片]";
            break;
        }
        case HYChatMessageTypeAudio:{
            bodyString = @"[语音]";
            break;
        }
        case HYChatMessageTypeVideo:{
            bodyString = @"[视频]";
            break;
        }
        default:
            break;
    }
    return bodyString;
}

+ (HYChatMessageType)typeFromString:(NSString *)string
{
    if ([string isEqualToString:@"image"]) {
        return HYChatMessageTypeImage;
    } else if ([string isEqualToString:@"audio"]) {
        return HYChatMessageTypeAudio;
    } else if ([string isEqualToString:@"video"]) {
        return HYChatMessageTypeVideo;
    }
    return HYChatMessageTypeText;
}

+ (NSString *)sampleTimeStringSince1970:(double)secs
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:secs];
    NSDictionary *dict = [self timeIntervalFromDate:date];
    NSInteger years = [[dict objectForKey:@"years"] integerValue];
    //    NSInteger months = [[dic objectForKey:@"keyMonths"] integerValue];
    NSInteger days = [[dict objectForKey:@"days"] integerValue];
    NSInteger hours = [[dict objectForKey:@"hours"] integerValue];
    //    NSInteger minutes = [[dic objectForKey:@"minutes"] integerValue];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (hours < 24 && days == 0) {
        [dateFormatter setDateFormat:@"HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 48 && days == 1) {
        [dateFormatter setDateFormat:@"昨天"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 72 && days == 2) {
        [dateFormatter setDateFormat:@"前天"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 24 * 7 && days <= 7) { // 周几
        return [self weekDayFromDate:date];
    } else if (years < 1){
        [dateFormatter setDateFormat:@"MM-dd"];
        return [dateFormatter stringFromDate:date];
    } else {
        [dateFormatter setDateFormat:@"yy-MM-dd"];
        return [dateFormatter stringFromDate:date];
    }
}
/**
 *  时间
 */
+ (NSString *)timeStringSince1970:(double)secs
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:secs];
    NSDictionary *dict = [self timeIntervalFromDate:date];
    NSInteger years = [[dict objectForKey:@"years"] integerValue];
    //    NSInteger months = [[dic objectForKey:@"keyMonths"] integerValue];
    NSInteger days = [[dict objectForKey:@"days"] integerValue];
    NSInteger hours = [[dict objectForKey:@"hours"] integerValue];
    //    NSInteger minutes = [[dic objectForKey:@"minutes"] integerValue];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (hours < 24 && days == 0) {
        [dateFormatter setDateFormat:@"HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 48 && days == 1) {
        [dateFormatter setDateFormat:@"昨天 HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 72 && days == 2) {
        [dateFormatter setDateFormat:@"前天 HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 24 * 7 && days <= 7) { // 周几
        return [self weekDayFromDate:date];
    } else if (years < 1){
        [dateFormatter setDateFormat:@"MM-dd"];
        return [dateFormatter stringFromDate:date];
    } else {
        [dateFormatter setDateFormat:@"yy-MM-dd"];
        return [dateFormatter stringFromDate:date];
    }
}

+ (NSString *)timeStringFromDate:(NSDate *)date
{
    NSDictionary *dict = [self timeIntervalFromDate:date];
    NSInteger years = [[dict objectForKey:@"years"] integerValue];
    //    NSInteger months = [[dic objectForKey:@"keyMonths"] integerValue];
    NSInteger days = [[dict objectForKey:@"days"] integerValue];
    NSInteger hours = [[dict objectForKey:@"hours"] integerValue];
    //    NSInteger minutes = [[dic objectForKey:@"minutes"] integerValue];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (hours < 24 && days == 0) {
        [dateFormatter setDateFormat:@"HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 48 && days == 1) {
        [dateFormatter setDateFormat:@"昨天 HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 72 && days == 2) {
        [dateFormatter setDateFormat:@"前天 HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 24 * 7 && days <= 7) { // 周几
        NSString *weekStr = [self weekDayFromDate:date];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"%@ HH:mm",weekStr]];
        return [dateFormatter stringFromDate:date];
    } else if (years < 1){
        [dateFormatter setDateFormat:@"MM-dd"];
        return [dateFormatter stringFromDate:date];
    } else {
        [dateFormatter setDateFormat:@"yy-MM-dd"];
        return [dateFormatter stringFromDate:date];
    }
}

+ (NSDictionary *)timeIntervalFromDate:(NSDate *)date
{
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *compsPast = [calendar components:unitFlags fromDate:date];
    NSDateComponents *compsNow = [calendar components:unitFlags fromDate:[NSDate date]];
    
    NSInteger years = [compsNow year] - [compsPast year];
    NSInteger months = [compsNow month] - [compsPast month] + years * 12;
    NSInteger days = [compsNow day] - [compsPast day] + months * 30;
    NSInteger hours = [compsNow hour] - [compsPast hour] + days * 24;
    NSInteger minutes = [compsNow minute] - [compsPast minute] + hours * 60;
    
    return @{
             @"years":  @(years),
             @"months": @(months),
             @"days":   @(days),
             @"hours":  @(hours),
             @"minutes":@(minutes)
             };
}

/*
 * iOS中规定的就是周日为1，周一为2，周二为3，周三为4，周四为5，周五为6，周六为7，
 * 无法通过某个设置改变这个事实的，只能在使用的时候注意一下这个规则了。
 */

+ (NSString *)weekDayFromDate:(NSDate *)date
{
    NSUInteger unitFlags = NSCalendarUnitWeekday; // weakDay
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *compsPast = [calendar components:unitFlags fromDate:date];
    NSInteger weekDay = [compsPast weekday];
    NSDictionary *weekNameDict = @{
                                   @(1):@"日",
                                   @(2):@"一",
                                   @(3):@"二",
                                   @(4):@"三",
                                   @(5):@"四",
                                   @(6):@"五",
                                   @(7):@"六",
                                   };
    NSString *weekName = [weekNameDict objectForKey:@(weekDay)];
    return [NSString stringWithFormat:@"星期%@",weekName];
}

#pragma mark -  Generate Key

+ (NSString *)generateImageKeyWithPrefix:(NSString *)keyPrefix
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%@_%@.jpg", keyPrefix, timeString];
}


+ (NSString *)currentTimeStampString
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = [now timeIntervalSinceReferenceDate];
    
    NSString *timeString = [NSString stringWithFormat:@"%lf",timeInterval];
    timeString = [timeString stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    return timeString;
    
}
@end
