//
//  HYEmoticonCollectionView.m
//  HYChatProject
//
//  Created by erpapa on 16/5/7.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYEmoticonCollectionView.h"
#import "HYEmoticonTool.h"
#import "UIView+SW.h"

@implementation HYEmoticonCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

/**
 *  emoticonDict --> {@"[微笑]",@"001"}
 */
- (void)setEmoticonDict:(NSDictionary *)emoticonDict
{
    _emoticonDict = emoticonDict;
    if (emoticonDict) {
        NSString *imageName = [[emoticonDict allValues] firstObject];
        NSString *imagePath = [[HYEmoticonTool sharedInstance] imagePathForkey:imageName];
        self.imageView.image = [UIImage imageWithContentsOfFile:imagePath];
    } else {
        self.imageView.image = nil;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat imageViewW = 32;
    self.imageView.frame = CGRectMake((CGRectGetWidth(self.bounds) - 32) * 0.5, (CGRectGetHeight(self.bounds) - 32) * 0.5, imageViewW, imageViewW);
}

@end


@implementation HYEmoticonCollectionView{
    NSTimeInterval *_touchBeganTime;
    BOOL _touchMoved;
    UIImageView *_magnifier;
    UIImageView *_magnifierContent;
    __weak HYEmoticonCell *_currentMagnifierCell;
    NSTimer *_backspaceTimer;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.pagingEnabled = YES;
        self.clipsToBounds = NO;
        self.canCancelContentTouches = NO;
        self.multipleTouchEnabled = NO;
        _magnifier = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emoticon_keyboard_magnifier"]];
        _magnifierContent = [[UIImageView alloc] initWithFrame:CGRectMake((_magnifier.bounds.size.width - 40) * 0.5, 10, 40, 40)];
        [_magnifier addSubview:_magnifierContent];
        _magnifier.hidden = YES;
        [self addSubview:_magnifier];
    }
    return self;
}

- (void)dealloc {
    [self endBackspaceTimer];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchMoved = NO;
    HYEmoticonCell *cell = [self cellForTouches:touches];
    _currentMagnifierCell = cell;
    [self showMagnifierForCell:_currentMagnifierCell];
    
    if (cell.isDelete) {
        [self endBackspaceTimer];
        [self performSelector:@selector(startBackspaceTimer) withObject:nil afterDelay:0.5];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchMoved = YES;
    if (_currentMagnifierCell && _currentMagnifierCell.isDelete) return;
    
    HYEmoticonCell *cell = [self cellForTouches:touches];
    if (cell != _currentMagnifierCell) {
        if (!_currentMagnifierCell.isDelete && !cell.isDelete) {
            _currentMagnifierCell = cell;
        }
        [self showMagnifierForCell:cell];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    HYEmoticonCell *cell = [self cellForTouches:touches];
    if ((!_currentMagnifierCell.isDelete && cell.emoticonDict) || (!_touchMoved && cell.isDelete)) {
        if ([self.delegate respondsToSelector:@selector(emoticonCollectionView: didTapCell:)]) {
            [((id<HYEmoticonCollectionViewDelegate>) self.delegate) emoticonCollectionView:self didTapCell:cell];
        }
    }
    [self hideMagnifier];
    [self endBackspaceTimer];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self hideMagnifier];
    [self endBackspaceTimer];
}

- (HYEmoticonCell *)cellForTouches:(NSSet<UITouch *> *)touches {
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:point];
    if (indexPath) {
        HYEmoticonCell *cell = (id)[self cellForItemAtIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (void)showMagnifierForCell:(HYEmoticonCell *)cell {
    if (cell.isDelete || !cell.imageView.image) {
        [self hideMagnifier];
        return;
    }
    CGRect rect = [cell convertRect:cell.bounds toView:self];
    _magnifier.centerX = CGRectGetMidX(rect);
    _magnifier.bottom = CGRectGetMaxY(rect) - 9;
    _magnifier.hidden = NO;
    
    _magnifierContent.image = cell.imageView.image;
    _magnifierContent.top = 20;
    
    [_magnifierContent.layer removeAllAnimations];
    NSTimeInterval dur = 0.1;
    [UIView animateWithDuration:dur delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _magnifierContent.top = 3;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:dur delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _magnifierContent.top = 6;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:dur delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                _magnifierContent.top = 5;
            } completion:^(BOOL finished) {
            }];
        }];
    }];
}

- (void)hideMagnifier {
    _magnifier.hidden = YES;
}

- (void)startBackspaceTimer { // 0.1s循环调用删除功能
    [self endBackspaceTimer];
    _backspaceTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(backspace) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_backspaceTimer forMode:NSRunLoopCommonModes];
}

- (void)backspace
{
    HYEmoticonCell *cell = self->_currentMagnifierCell;
    if (cell.isDelete) {
        if ([self.delegate respondsToSelector:@selector(emoticonCollectionView:didTapCell:)]) {
            [((id<HYEmoticonCollectionViewDelegate>) self.delegate) emoticonCollectionView:self didTapCell:cell];
        }
    }
}

- (void)endBackspaceTimer {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startBackspaceTimer) object:nil];
    [_backspaceTimer invalidate];
    _backspaceTimer = nil;
}

@end
