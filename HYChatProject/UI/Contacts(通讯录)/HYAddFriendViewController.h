//
//  HYAddFriendViewController.h
//  HYChatProject
//
//  Created by erpapa on 16/5/1.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HYAddFriendType) {
    HYAddFriendTypeFriend,
    HYAddFriendTypeGroup,
    HYAddFriendTypeCreateGroup
};

@interface HYAddFriendViewController : UIViewController

@property (nonatomic, assign) HYAddFriendType type;

@end
