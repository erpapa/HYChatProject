//
//  HYSearchDisplayController.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYSearchController.h"

@interface HYSearchController ()

@end

@implementation HYSearchController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initSearchBar];
    }
    return self;
}

- (instancetype)initWithSearchResultsController:(UIViewController *)searchResultsController
{
    self = [super initWithSearchResultsController:searchResultsController];
    if (self) {
        [self initSearchBar];
    }
    return self;
}

- (void)initSearchBar
{
    UISearchBar *searchBar = self.searchBar;
    searchBar.placeholder = @"搜索";
    searchBar.backgroundImage = [UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(kScreenW, 44.0)]; // 设置背景
    UITextField *searchField = [searchBar valueForKey:@"_searchField"];
    searchField.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
}

@end
