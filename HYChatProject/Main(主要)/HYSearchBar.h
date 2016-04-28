//
//  HYSearchBar.h
//  HYChatProject
//
//  Created by erpapa on 16/4/27.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HYSearchBar;
@protocol HYSearchBarDelegate <NSObject>
@optional
- (void)searchBarDidClicked:(HYSearchBar *)searchBar;

@end

@interface HYSearchBar : UIView
@property (nonatomic, weak) id<HYSearchBarDelegate> delegate;
@end
