//
//  NSArray+format.m
//  08-NSValue
//
//  Created by erpapa on 15/6/29.
//  Copyright (c) 2015年 erpapa. All rights reserved.
//

#import "NSArray+format.h"

@implementation NSArray (NSArray_format)
- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *str = [NSMutableString stringWithFormat:@"(\n"];
    
    for (id obj in self) {
        [str appendFormat:@"\t%@, \n", obj];
    }
    
    [str appendString:@")"];
    
    return str;
}
@end
