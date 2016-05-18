//
//  HYVideosViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/16.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVideosViewController.h"
#import "HYVideoViewCell.h"
#import "HYQNAuthPolicy.h"
#import "YYImageCache.h"
#import "HYUtils.h"
#import "HYVideoPlayController.h"

static NSString *kVideoViewCellIdentifier = @"kVideoViewCellIdentifier";
@interface HYVideosViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation HYVideosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"视频";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupColectionView];
    [self setupVideosSource];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.dataSource.count == 0) {
        [HYUtils alertWithNormalMsg:@"没有视频"];
    }
}

- (void)setupColectionView
{
    // 1.流水布局
    CGFloat margin = 10;
    CGFloat itemWidth = (CGRectGetWidth(self.view.bounds) - margin * 3) * 0.5;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(itemWidth,itemWidth);
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    // 2.实例化collectionView
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    // 3.注册cell(告诉collectionView将来创建怎样的cell)
    [self.collectionView registerClass:[HYVideoViewCell class] forCellWithReuseIdentifier:kVideoViewCellIdentifier];
    // 4.设置背景色和代理
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
 
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 1.获得cell
    HYVideoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kVideoViewCellIdentifier forIndexPath:indexPath];
    NSDictionary *dict = [self.dataSource objectAtIndex:indexPath.item];
    NSString *imageName = [dict objectForKey:@"imageName"];
    NSData *imageData = [[YYImageCache sharedCache] getImageDataForKey:QN_FullURL(imageName)];
    cell.thumImageView.image = [UIImage imageWithData:imageData];
    cell.timeLabel.text = [dict objectForKey:@"time"];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = [self.dataSource objectAtIndex:indexPath.item];
    NSString *filePath = [dict objectForKey:@"filePath"];
    HYVideoPlayController *videoPlayVC = [[HYVideoPlayController alloc] initWithPath:filePath];
    [self presentViewController:videoPlayVC animated:YES completion:nil];
}


- (void)setupVideosSource
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *videoCache = [NSString stringWithFormat:@"%@/videoCache",document];
    //枚举，获得项目的集合
    NSEnumerator *filesEnumerator = [manager enumeratorAtPath:videoCache];
    for (NSString *fileName in filesEnumerator) {
        NSString* fileAbsolutePath = [videoCache stringByAppendingPathComponent:fileName];
        NSDictionary *fileAttributes = [manager attributesOfItemAtPath:fileAbsolutePath error:nil];
        NSDate *fileCreateDate = [fileAttributes objectForKey:NSFileCreationDate];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@" MM月dd日 HH:mm:ss"];
        NSString *dateString = [dateFormatter stringFromDate:fileCreateDate];
        NSString *imageName = [NSString stringWithFormat:@"%@.jpg",[fileName stringByDeletingPathExtension]];
        NSString *filePath = [videoCache stringByAppendingPathComponent:fileName];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:filePath,@"filePath",imageName,@"imageName",dateString,@"time", nil];
        [self.dataSource addObject:dict];
    }
}

- (NSMutableArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
