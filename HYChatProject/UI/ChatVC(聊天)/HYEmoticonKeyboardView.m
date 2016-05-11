//
//  HYEmoticonKeyboardView.m
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYEmoticonKeyboardView.h"
#import "HYEmoticonCollectionView.h"
#import "HYEmoticonTool.h"

#define kViewHeight 216
#define kToolbarHeight 37
#define kOneEmoticonHeight 50
#define kOnePageCount 20

static NSString *kEmoticonCellIdentifier = @"kEmoticonCellIdentifier";
@interface HYEmoticonKeyboardView()<UICollectionViewDataSource,HYEmoticonCollectionViewDelegate>
@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) HYEmoticonCollectionView *collectionView;
@property (nonatomic, strong) UIView *pageControl;
@property (nonatomic, strong) NSArray<UIButton *> *toolbarButtons;
@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) NSArray<NSArray *>  *emoticonGroups;
@property (nonatomic, strong) NSArray<NSNumber *> *emoticonGroupPageIndexs;
@property (nonatomic, strong) NSArray<NSNumber *> *emoticonGroupPageCounts;
@property (nonatomic, assign) NSInteger emoticonGroupTotalPageCount;
@property (nonatomic, assign) NSInteger currentPageIndex;
@end

@implementation HYEmoticonKeyboardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = COLOR(245, 245, 245, 1.0f);
        _currentPageIndex = NSNotFound;
        [self initEmoticonGroups];
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView
{
    // 1.topLine
    self.topLine = [[UIView alloc] init];
    self.topLine.backgroundColor = [UIColor colorWithRed:222/255.0f green:222/255.0f blue:222/255.0f alpha:1.0f];
    self.topLine.frame = CGRectMake(0, 0, kScreenW, 1);
    [self addSubview:self.topLine];
    
    // 2.collectionView
    [self initCollectionView];
    // 3.pageControl
    self.pageControl = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.collectionView.frame), kScreenW, 20)];
    self.pageControl.userInteractionEnabled = NO;
    [self addSubview:self.pageControl];
    // 4.toolBar
    [self initToolBar];
    [self toolBarButtonClick:self.toolbarButtons.firstObject];
}

/**
 *  处理表情，将所有表情放到一个collectionView里边
 */
- (void)initEmoticonGroups
{
    _emoticonGroups = [HYEmoticonTool sharedInstance].emoticonArray;
    NSMutableArray *indexs = [NSMutableArray new];
    NSUInteger index = 0;
    for (NSArray *group in _emoticonGroups) {
        [indexs addObject:@(index)];
        NSUInteger count = ceil(group.count / (float)kOnePageCount);
        if (count == 0) count = 1;
        index += count;
    }
    _emoticonGroupPageIndexs = indexs;
    
    NSMutableArray *pageCounts = [NSMutableArray new];
    _emoticonGroupTotalPageCount = 0;
    for (NSArray *group in _emoticonGroups) {
        NSUInteger pageCount = ceil(group.count / (float)kOnePageCount);
        if (pageCount == 0) pageCount = 1;
        [pageCounts addObject:@(pageCount)];
        _emoticonGroupTotalPageCount += pageCount;
    }
    _emoticonGroupPageCounts = pageCounts;
}

- (void)initCollectionView
{
    CGFloat itemWidth = (kScreenW - 10 * 2) / 7.0;
    CGFloat padding = (kScreenW - 7 * itemWidth) / 2.0;
    CGFloat paddingLeft = padding;
    CGFloat paddingRight = kScreenW - paddingLeft - itemWidth * 7;
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(itemWidth, kOneEmoticonHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.sectionInset = UIEdgeInsetsMake(0, paddingLeft, 0, paddingRight);
    
    _collectionView = [[HYEmoticonCollectionView alloc] initWithFrame:CGRectMake(0, 6, kScreenW, kOneEmoticonHeight * 3) collectionViewLayout:layout];
    [_collectionView registerClass:[HYEmoticonCell class] forCellWithReuseIdentifier:kEmoticonCellIdentifier];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor clearColor];
    [self addSubview:_collectionView];
}

- (void)initToolBar
{
    self.toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, kViewHeight - kToolbarHeight, kScreenW, kToolbarHeight)];
    self.toolBar.backgroundColor = COLOR(241, 241, 241, 1.0f);
    [self addSubview:self.toolBar];
    
    CGFloat sendButtonW = 72;
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.toolBar.bounds) - sendButtonW, 0, sendButtonW, kToolbarHeight)];
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    [self.sendButton setBackgroundColor:COLOR(90, 200, 255, 1.0f)];
    [self.sendButton addTarget:self action:@selector(sendButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar addSubview:self.sendButton];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenW - sendButtonW, kToolbarHeight)];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.contentSize = scrollView.bounds.size;
    [self.toolBar addSubview:scrollView];
    
    NSMutableArray *btns = [NSMutableArray array];
    CGFloat buttonWidth = 60;
    for (NSUInteger i = 0; i < _emoticonGroups.count; i++) {
        NSArray *arr = [_emoticonGroups objectAtIndex:i];
        NSString *imageName = [[[arr firstObject] allValues] firstObject];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(buttonWidth * i, 0, buttonWidth, kToolbarHeight)];
        UIImage *image = [UIImage imageWithContentsOfFile:[[HYEmoticonTool sharedInstance] imagePathForkey:imageName]];
        [btn setImage:image forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(toolBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithColor:COLOR(222, 222, 222, 1.0f)] forState:UIControlStateSelected];
        btn.tag = i;
        [scrollView addSubview:btn];
        [btns addObject:btn];
    }
    _toolbarButtons = btns;
}

#pragma mark - collectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return _emoticonGroupTotalPageCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return kOnePageCount + 1; // 每页21个（包括删除图标）
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HYEmoticonCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kEmoticonCellIdentifier forIndexPath:indexPath];
    if (indexPath.item == kOnePageCount) { // 最后一个是删除
        cell.emoticonDict = @{@"":@"emotion_delete"};
        cell.isDelete = YES;
    } else {
        cell.emoticonDict = [self emoticonKeyForIndexPath:indexPath];
        cell.isDelete = NO;
    }
    return cell;
}

/**
 *  选中cell
 */
- (void)emoticonCollectionView:(HYEmoticonCollectionView *)collectionView didTapCell:(HYEmoticonCell *)cell
{
    if (!cell.emoticonDict) return;
    if (cell.isDelete) { // 删除
        if ([self.delegate respondsToSelector:@selector(emoticonKeyboardDidTapBackspace)]) {
            [self.delegate emoticonKeyboardDidTapBackspace];
        }
    } else { // 选中表情
        if ([self.delegate respondsToSelector:@selector(emoticonKeyboardDidTapText:)]) {
            NSString *imageKey = [[cell.emoticonDict allKeys] firstObject];
            [self.delegate emoticonKeyboardDidTapText:imageKey];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark UICollectionViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger page = round(scrollView.contentOffset.x / scrollView.bounds.size.width);
    if (page < 0) page = 0;
    else if (page >= _emoticonGroupTotalPageCount) page = _emoticonGroupTotalPageCount - 1;
    if (page == _currentPageIndex) return;
    _currentPageIndex = page;
    NSInteger curGroupIndex = 0, curGroupPageIndex = 0, curGroupPageCount = 0;
    for (NSInteger i = _emoticonGroupPageIndexs.count - 1; i >= 0; i--) {
        NSNumber *pageIndex = _emoticonGroupPageIndexs[i];
        if (page >= pageIndex.unsignedIntegerValue) {
            curGroupIndex = i;
            curGroupPageIndex = ((NSNumber *)_emoticonGroupPageIndexs[i]).integerValue;
            curGroupPageCount = ((NSNumber *)_emoticonGroupPageCounts[i]).integerValue;
            break;
        }
    }
    // 移除所有layer
    while (self.pageControl.layer.sublayers.count) {
        [self.pageControl.layer.sublayers.lastObject removeFromSuperlayer];
    }
    CGFloat padding = 5, width = 6, height = 2;
    CGFloat pageControlWidth = (width + 2 * padding) * curGroupPageCount;
    for (NSInteger i = 0; i < curGroupPageCount; i++) {
        CALayer *layer = [CALayer layer];
        if (page - curGroupPageIndex == i) {
            layer.backgroundColor = ColorFromHex(0xfd8225).CGColor;
        } else {
            layer.backgroundColor = ColorFromHex(0xdedede).CGColor;
        }
        CGFloat layerX = (self.pageControl.bounds.size.width - pageControlWidth) / 2 + i * (width + 2 * padding) + padding;
        layer.frame = CGRectMake(layerX, (self.pageControl.bounds.size.height - height) * 0.5, width, height);
        layer.cornerRadius = 1;
        [self.pageControl.layer addSublayer:layer];
    }
    [_toolbarButtons enumerateObjectsUsingBlock:^(UIButton *btn, NSUInteger idx, BOOL *stop) {
        btn.selected = (idx == curGroupIndex);
    }];
}

- (NSDictionary *)emoticonKeyForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    for (NSInteger i = _emoticonGroupPageIndexs.count - 1; i >= 0; i--) {
        NSNumber *pageIndex = _emoticonGroupPageIndexs[i];
        if (section >= pageIndex.unsignedIntegerValue) {
            NSArray *group = _emoticonGroups[i];
            NSUInteger page = section - pageIndex.unsignedIntegerValue;
            NSUInteger index = page * kOnePageCount + indexPath.row;
            
            // transpose line/row
            NSUInteger ip = index / kOnePageCount;
            NSUInteger ii = index % kOnePageCount;
            NSUInteger reIndex = (ii % 3) * 7 + (ii / 3);
            index = reIndex + ip * kOnePageCount;
            
            if (index < group.count) {
                return group[index];
            } else {
                return nil;
            }
        }
    }
    return nil;
}

#pragma mark - 发送
- (void)sendButtonClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(emoticonKeyboardDidTapSendButton)]) {
        [self.delegate emoticonKeyboardDidTapSendButton];
    }
}

#pragma mark - 表情button
- (void)toolBarButtonClick:(UIButton *)sender
{
    NSInteger groupIndex = sender.tag;
    NSInteger page = ((NSNumber *)_emoticonGroupPageIndexs[groupIndex]).integerValue;
    CGRect rect = CGRectMake(page * _collectionView.bounds.size.width, 0, _collectionView.bounds.size.width, _collectionView.bounds.size.height);
    [_collectionView scrollRectToVisible:rect animated:NO];
    [self scrollViewDidScroll:_collectionView];
}

@end
