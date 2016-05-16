//
//  HYChatProjectTests.m
//  HYChatProjectTests
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImage+SW.h"

@interface HYChatProjectTests : XCTestCase

@end

@implementation HYChatProjectTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    UIImage *QRImage = [UIImage createQRCodeWithString:@"admin@erpapa.cn" size:CGSizeMake(300, 300)];
    UIImage *iconImage = [UIImage imageNamed:@"defaultHead"];
    UIImage *newImage = [QRImage addIconImage:iconImage withScale:0.2];
    NSLog(@"%@",newImage);
}

- (void)testExample1 {
    NSLog(@"%f",[NSDate timeIntervalSinceReferenceDate]); // 2000.1.1
    NSLog(@"%f",[[NSDate date] timeIntervalSince1970]); // 1970.1.1
    
    NSMutableArray *array = [NSMutableArray arrayWithObjects:@"1",@"2", nil];
    [array removeObject:@"0"];
    NSLog(@"%@",array);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
