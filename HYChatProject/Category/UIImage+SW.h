//
//  UIImage+MJ.h
//  ItcastWeibo
//
//  Created by apple on 14-5-5.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (SW)

/**
 *  返回一张自由拉伸的图片
 */
+ (UIImage *)resizedImageWithName:(NSString *)name;

+ (UIImage *)resizedImageWithName:(NSString *)name left:(CGFloat)left top:(CGFloat)top;
/**
 *  颜色转换为背景图片
 */
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
/**
 *  缩放图片
 */
+ (UIImage*)imageFromOrigin:(UIImage *)image scaleToSize:(CGSize)size;
/**
 *  改变图片颜色
 */
- (UIImage *)imageWithMaskColor:(UIColor *)color;

- (UIImage *)imageWithMaskColor:(UIColor *)color rect:(CGRect)rect;
/**
 *  返回圆形图片
 */
- (UIImage *)circleImage;
+ (UIImage *)circleImageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)createRoundedRectImage:(UIImage *)image withSize:(CGSize)size radius:(NSInteger)radius;
/**
 *  旋转图片
 */
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
/**
 *  返回正确方向的图片
 */
+ (UIImage *)fixrotation:(UIImage *)image;

/**
 *  将view截图
 */
+ (UIImage *)captureWithView:(UIView *)view;

/**
 *  生成二维码(默认300x300)
 */
+ (UIImage *)createQRCodeWithString:(NSString *)string;
/**
 *  从CIImage生成UIImage
 */
+ (UIImage *)imageWithCIImage:(CIImage *)image fixedSize:(CGSize)size;
/**
 *  不失真放大
 */
- (UIImage *)fixedSize:(CGSize)size;
/**
 *  调整大小
 */
- (UIImage *)resizeWithRate:(CGFloat)rate quality:(CGInterpolationQuality)quality;
/**
 *  替换白色背景
 */
- (UIImage *)changeColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;
/**
 *  添加图片
 */
- (UIImage *)addIconImage:(UIImage *)iconImage withScale:(CGFloat)scale;
@end
