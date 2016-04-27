//
//  NSString+SW.m
//  HYChatProject
//
//  Created by erpapa on 15/7/30.
//  Copyright (c) 2015年 erpapa. All rights reserved.
//

#import "NSString+SW.h"

@implementation NSString (SW)

#pragma mark - 日期字符串转换
- (CGSize)sizeWithFont:(UIFont *)font
{
    return [self sizeWithFont:font maxSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)sizeWithFont:(UIFont *)font maxSize:(CGSize)maxSize
{
    NSDictionary *attrs = @{NSFontAttributeName:font};
    return [self boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

#pragma mark - 日期字符串转换

- (NSString *)timeStringForExpress
{
    NSDictionary *dic = [self timeIntervalFromString:self];
    NSInteger years = [[dic objectForKey:@"years"] integerValue];
    //    NSInteger months = [[dic objectForKey:@"keyMonths"] integerValue];
    NSInteger days = [[dic objectForKey:@"days"] integerValue];
    NSInteger hours = [[dic objectForKey:@"hours"] integerValue];
    NSInteger minutes = [[dic objectForKey:@"minutes"] integerValue];
    
    NSDate *date = [self dateFromCreateAt:self];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (minutes < 1) {
        return @"刚刚";
    } else if (minutes < 60) {
        return [NSString stringWithFormat:@"%ld分钟前", (long)minutes];
    } else if (hours < 24 && days == 0) {
        [dateFormatter setDateFormat:@"HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (hours < 48 && days == 1) {
        [dateFormatter setDateFormat:@"昨天 HH:mm"];
        return [dateFormatter stringFromDate:date];
    } else if (years < 1){
        [dateFormatter setDateFormat:@"MM-dd"];
        return [dateFormatter stringFromDate:date];
    } else {
        [dateFormatter setDateFormat:@"yy-MM-dd"];
        return [dateFormatter stringFromDate:date];
    }
}
- (NSString *)timeStringForExpress1
{
    NSDictionary *dic = [self timeIntervalFromString:self];
    NSInteger years = [[dic objectForKey:@"years"] integerValue];
    //    NSInteger months = [[dic objectForKey:@"keyMonths"] integerValue];
    NSInteger days = [[dic objectForKey:@"days"] integerValue];
    NSInteger hours = [[dic objectForKey:@"hours"] integerValue];
    //    NSInteger minutes = [[dic objectForKey:@"minutes"] integerValue];
    
    NSDate *date = [self dateFromCreateAt:self];
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

- (NSDate *)dateFromCreateAt:(NSString *)dateStr
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    return [dateFormatter dateFromString:dateStr];
}

- (NSDictionary *)timeIntervalFromString:(NSString *)dateStr
{
    NSDate *date = [self dateFromCreateAt:dateStr];
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

- (NSString *)weekDayFromDate:(NSDate *)date
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

@end
