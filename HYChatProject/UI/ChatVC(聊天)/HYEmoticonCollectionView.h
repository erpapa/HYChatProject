//
//  HYEmoticonCollectionView.h
//  HYChatProject
//
//  Created by erpapa on 16/5/7.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYEmoticonCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSDictionary *emoticonDict;
@property (nonatomic, assign) BOOL isDelete;
@end

@class HYEmoticonCollectionView;
@protocol HYEmoticonCollectionViewDelegate <UICollectionViewDelegate>
- (void)emoticonCollectionView:(HYEmoticonCollectionView *)collectionView didTapCell:(HYEmoticonCell *)cell;
@end

@interface HYEmoticonCollectionView : UICollectionView

@end
