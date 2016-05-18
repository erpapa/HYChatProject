//
//  HYMeViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/4/27.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kMeViewCellHeight 76.0

@class XMPPvCardTemp;
@interface HYMeViewCell : UITableViewCell
@property (nonatomic, strong) XMPPvCardTemp *vCard;
@property (nonatomic, strong) UIImageView *QRView; // 二维码
@end
