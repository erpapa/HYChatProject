//
//  HYMYvCardViewController.h
//  HYChatProject
//
//  Created by erpapa on 16/5/6.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYMyvCardViewController : UIViewController

@end


@class HYSexSelectioViewController;
@protocol HYSexSelectioViewControllerDelegate <NSObject>
@optional
- (void)sexSelectioDidFinished:(HYSexSelectioViewController *)sexSelectioVC;
@end

@interface HYSexSelectioViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, weak) id<HYSexSelectioViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *sex;
@property (nonatomic, strong) UITableView *tableView;
@end