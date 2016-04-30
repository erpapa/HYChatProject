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
        [instance setupData]; // 初始化数据
    }
    return instance;
}

- (void)setupData
{
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    _emoticonArray = [self loadInfoArray];
    for (NSInteger index = 0; index < _emoticonArray.count; index++) {
        NSArray *array = [_emoticonArray objectAtIndex:index];
        [array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            [tempDict addEntriesFromDictionary:dict]; // 将所有数据添加进字典
        }];
    }
    _emoticonDict = tempDict;
    _emoticonRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[[^ \\[\\]]+?\\]" options:kNilOptions error:NULL];
}

- (NSString *)imagePathForkey:(NSString *)key
{
    NSString *imageName = [NSString stringWithFormat:@"%@@2x.png",key];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Emoticon" ofType:@"bundle"];
    NSString *imagePath = [bundlePath stringByAppendingPathComponent:imageName];
    return imagePath;
}

- (NSString *)gifPathForKey:(NSString *)key
{
    NSString *gifName = [NSString stringWithFormat:@"%@@2x.gif",key];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Emoticon" ofType:@"bundle"];
    NSString *gifPath = [bundlePath stringByAppendingPathComponent:gifName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:gifPath]) { // 如果gif文件不存在，就返回imagePath
        return [self imagePathForkey:key];
    }
    return gifPath;
}

- (NSArray *)loadInfoArray
{
    //使用bundle取出Emoticon.bundle里边的plist数据
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Emoticon" ofType:@"bundle"];
    NSString *qqPlistPath = [bundlePath stringByAppendingPathComponent:@"qq.plist"];
    NSArray *qqArray=[[NSArray alloc] initWithContentsOfFile:qqPlistPath];
    
    NSString *weiboPlistPath = [bundlePath stringByAppendingPathComponent:@"weibo.plist"];
    NSArray *weiboArray=[[NSArray alloc] initWithContentsOfFile:weiboPlistPath];
    
    NSArray *allArray = @[qqArray,weiboArray];
    return allArray;
}
@end
