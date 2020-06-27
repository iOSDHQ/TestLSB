//
//  SteganographyHelper.h
//  TestLSB
//
//  Created by hongqiang dong on 2020/6/27.
//  Copyright © 2020 hongqiang dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface SteganographyHelper : NSObject
/**
  本方法读取图片像素保存数据：
*/
+(NSString *)extractTextFromUIImage:(UIImage *)image;
/**
   本方法使用图片像素保存数据：
   1. 每像素仅最后一个二进制位用来保存数据
   2. 由于使用位来存储数据，对类型占用位数敏感
   3. 头32个像素即一个无符号整型用来保存字节长度
   4. 此保存数据是按顺序进行写入，晋级写法通过规律图形算法，按算法规律写入。
*/

+(UIImage *)incorporateTextWithUIImage:(UIImage *)image text:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
