//
//  HYForwardingViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/5/14.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kForwardingViewCellHeight 54.0
#define kForwardingHeaderViewHeight 24.0

@class HYContactsModel;
@interface HYForwardingViewCell : UITableViewCell
@property (nonatomic, strong) HYContactsModel *chatModel;
@end



@interface HYForwardingHeaderView : UITableViewHeaderFooterView
@property (nonatomic, strong) UILabel *titleLabel;
@end

@interface HYForwardingIconViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) HYContactsModel *chatModel;
@end

