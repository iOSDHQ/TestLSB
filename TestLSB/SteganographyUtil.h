//
//  SteganographyUtil.h
//  TestLSB
//
//  Created by hongqiang dong on 2020/6/27.
//  Copyright © 2020 hongqiang dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 解密结果回调 code: 1 = 成功  2 = 失败
 */
typedef void(^StegoDecoderCompletionBlock)(int code, UIImage * _Nullable image);
/**
 解密后回调block  result为解密数据 code: 1 = 成功 2 = 失败
*/
typedef void (^StegoEncoderCompletionBlock)(int code, NSString * _Nullable result);

NS_ASSUME_NONNULL_BEGIN

@interface SteganographyUtil : NSObject
/**

*/
+(void)encryptDataWithImage:(UIImage *)image encryptText:(NSString *)encryptText completionBlock:(StegoDecoderCompletionBlock)completionBlock;
/**

*/
+(void)parseModelWithImage:(UIImage *)image completionBlock:(StegoEncoderCompletionBlock)completionBlock;
@end
@interface UIImage (fixOrientation)

- (UIImage *)fixOrientation;

@end

NS_ASSUME_NONNULL_END
