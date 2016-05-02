//
//  HYSearchBar.m
//  HYChatProject
//
//  Created by erpapa on 16/4/27.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYSearchBar.h"

@interface HYSearchBar()

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation HYSearchBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView
{
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"搜索";
    self.searchBar.backgroundImage = [UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(kScreenW, 44.0)]; // 设置背景
    UITextField *searchField = [self.searchBar valueForKey:@"_searchField"];
    searchField.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self addSubview:self.searchBar];
    self.button = [[UIButton alloc] init];
    [self.button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.button];
}

- (void)buttonClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(searchBarDidClicked:)]) {
        [self.delegate searchBarDidClicked:self];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.searchBar.frame = self.bounds;
    self.button.frame = self.bounds;
}

@end
