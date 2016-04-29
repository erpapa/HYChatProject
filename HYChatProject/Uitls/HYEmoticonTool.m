//
//  HYEmoticonTool.m
//  HYChatProject
//
//  Created by erpapa on 16/4/29.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYEmoticonTool.h"

@implementation HYEmoticonTool
static HYEmoticonTool *instance;

+ (id)allocWithZone:(struct _NSZone *)zone
{
    // dispatch_once是线程安全的，onceToken默认为0
    static dispatch_once_t onceToken;
    // dispatch_once宏可以保证块代码中的指令只被执行一次
    dispatch_once(&onceToken, ^{
        // 在多线程环境下，永远只会被执行一次，instance只会被实例化一次
        instance = [super allocWithZone:zone];
    });
    
    return instance;
}

/**
 *  单例
 */
+ (instancetype)sharedInstance
{
    if (instance == nil) {
        instance = [[self alloc] init];
        NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
        NSArray *infoArray = [self loadInfoArray];
        NSMutableArray *tempArray = [NSMutableArray array];
        [infoArray enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            [tempDict addEntriesFromDictionary:dict];
            [tempArray addObjectsFromArray:[dict allValues]];
        }];
        instance.emoticonDict = tempDict;
        instance.emoticonArray = tempArray;
        instance.emoticonRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[[^ \\[\\]]+?\\]" options:kNilOptions error:NULL];
    }
    return instance;
}

- (NSString *)imagePathForkey:(NSString *)key
{
    NSString *imageName = [NSString stringWithFormat:@"%@@2x.png",key];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EmoticonQQ" ofType:@"bundle"];
    NSString *imagePath = [bundlePath stringByAppendingPathComponent:imageName];
    return imagePath;
}

- (NSString *)gifPathForKey:(NSString *)key
{
    NSString *gifName = [NSString stringWithFormat:@"%@@2x.gif",key];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EmoticonQQ" ofType:@"bundle"];
    NSString *gifPath = [bundlePath stringByAppendingPathComponent:gifName];
    return gifPath;
}

+ (NSArray *)loadInfoArray
{
    //使用bundle取出EmoticonQQ.bundle里边的info.plist数据
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EmoticonQQ" ofType:@"bundle"];
    NSString *plistPath = [bundlePath stringByAppendingPathComponent:@"info.plist"];
    NSArray *array=[[NSArray alloc] initWithContentsOfFile:plistPath];
    return array;
}
@end
