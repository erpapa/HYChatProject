//
//  NSDictionary+format.m
//  08-NSValue
//
//  Created by erpapa on 15/6/29.
//  Copyright (c) 2015年 erpapa. All rights reserved.
//

#import "NSDictionary+format.h"

@implementation NSDictionary (NSDictionary_format)
- (NSString *)descriptionWithLocale:(id)locale
{
    NSArray *allKeys = [self allKeys];
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"{\t\n "];
    for (NSString *key in allKeys) {
        id value= self[key];
        [str appendFormat:@"\t \"%@\" = %@,\n",key, value];
    }
    [str appendString:@"}"];
    return str;
}
@end
