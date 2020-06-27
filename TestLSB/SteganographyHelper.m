//
//  SteganographyHelper.m
//  TestLSB
//
//  Created by hongqiang dong on 2020/6/27.
//  Copyright © 2020 hongqiang dong. All rights reserved.
//

#import "SteganographyHelper.h"
#define MAX_TEXT_LENGTH  1024*10
#define BYTES_PER_PIXEL  4
#define BITS_PER_COMPONENT  8
#define k4BYTES_PER_INT  4
#define k8BITS_PER_BYTE  8

UInt32 const kMIN_PIC_SIZE_LIMIT = 1024*1024;
UInt32 const kMAX_TEXT_LENGTH = kMIN_PIC_SIZE_LIMIT;

@implementation SteganographyHelper

+(Byte)extractByteFromPixels:(UInt32 *)pixels fromPosition:(int)position{
    
    Byte b = 0;
    for (int i=0;  i<k8BITS_PER_BYTE;i++) {
        UInt32 v = pixels[position+i];
        Byte lastBit = v & 0x1;
        b = b | (lastBit<<((k8BITS_PER_BYTE-1)-i));
    }
    
    return b;
   
}

+(NSData *)bitDatas:(NSData *)data{
    
    Byte *dataBytes = (Byte *)data.bytes;
    UInt32 rawDataLength = (UInt32)data.length;
    UInt32 bitLength = (UInt32)rawDataLength * k8BITS_PER_BYTE;
    Byte *bitDataBytes = (Byte *) calloc(bitLength, sizeof(Byte));
    UInt32 byteCursor = 0;
    while (byteCursor < rawDataLength) {
        Byte v = (Byte)dataBytes[byteCursor];
        int8_t bitCursor = k8BITS_PER_BYTE-1;
        for (int i=0; i<k8BITS_PER_BYTE; i++) {
            uint8_t lastbit =  (v >> bitCursor) & 1;
            bitDataBytes[byteCursor*k8BITS_PER_BYTE+i] = lastbit;
            bitCursor=bitCursor-1;
        }
        byteCursor++;
    }
    NSData *resut = [NSData dataWithBytes:bitDataBytes length:bitLength];
    free(bitDataBytes);
    bitDataBytes = NULL;
    return resut;

}

/*
本方法读取图片像素保存数据：
*/


+(NSString *)extractTextFromUIImage:(UIImage *)image{
    
    CGImageRef inputCGImage = image.CGImage;
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    NSUInteger size = height * width;
    UInt32 *pixels = (UInt32 *) calloc(size, sizeof(UInt32));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 BITS_PER_COMPONENT,
                                                 BYTES_PER_PIXEL * width,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
  
    
   UInt32 pixelPosition = 0;

    //读取 头32位 获取后面数据长度
    UInt32 dataLength = 0;
    UInt32 dataLengthBitCount = 32;
    for (int i=0;  i < dataLengthBitCount ;i++) {
         UInt32 v = pixels[pixelPosition+i];
         Byte b = v & 0x1;
         dataLength = dataLength | (b<<((dataLengthBitCount-1)-i));
     }
    
    //大小头转换，以获取正确的数据长度，
    dataLength = CFSwapInt32BigToHost(dataLength);
    
    //* 8 是因为保存的是字节长度需要转成位长度
    UInt32 dataBitLength = dataLength * 8;
     
    //读取数据 循环从32位开始，
    pixelPosition = dataLengthBitCount;
    Byte * rawDataBytes = calloc(dataLength, sizeof(Byte));
 
    UInt32 index = 0;
   
    while (pixelPosition < dataBitLength + dataLengthBitCount) {
             
             Byte b =  [self extractByteFromPixels:pixels fromPosition:pixelPosition];
             rawDataBytes[index++] = b;
             pixelPosition +=8 ;
             
    }
    
    NSData *data = [NSData dataWithBytes:rawDataBytes length:dataLength];

    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    free(rawDataBytes);
    rawDataBytes = NULL;
    return result;
       
    
}

/*
 本方法使用图片像素保存数据：
 1. 每像素仅最后一个二进制位用来保存数据
 2. 由于使用位来存储数据，对类型占用位数敏感
 3. 头32个像素即一个无符号整型用来保存字节长度
 4. 此保存数据是按顺序进行写入，晋级写法通过规律图形算法，按算法规律写入。
 */

+(UIImage *)incorporateTextWithUIImage:(UIImage *)image text:(NSString *)text{
    
    if (image == nil || text == nil) {
        return nil;
    }
    
    NSData *rawData = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    CGImageRef inputCGImage = image.CGImage;
    NSUInteger width = CGImageGetWidth(inputCGImage)/image.scale;
    NSUInteger height = CGImageGetHeight(inputCGImage)/image.scale;
    
    NSUInteger size = height * width;
    //用整型32位就够了，太大的数据没有必要用这种方式保存
    UInt32 rawDataLength = (UInt32)rawData.length;


    //可以保存的数据二进制位长度 + 头32个像素 ， 不能超过图片大小
      if(rawData.length * 8 + 32  > size * 8){
          
          return nil;
      }
    
    
    UInt32 *pixels =  (UInt32 *) calloc(size, sizeof(UInt32));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 BITS_PER_COMPONENT,
                                                 BYTES_PER_PIXEL * width,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    
    //把数据长度转成字节,注意:读取时大小头问题
    NSData *lengthData =  [NSData dataWithBytes: &rawDataLength length: sizeof(UInt32)];
    
    //将要写进图片的二进制数据
    NSMutableData *data = [NSMutableData data];
    //首先写入数据长度,bitDatas是把字节数据转成二进制数据
    [data appendData:[self bitDatas:lengthData]];
    //写入数据原始数据
    [data appendData:[self bitDatas:rawData]];
    
    const Byte *intactBytes =  data.bytes;
    
    
    //再次保护避免循环溢出
    if (data.length > size) {
        return nil;
    }
    UInt32 pixelPosition = 0;
    //遍历图片像素,最多遍历到总写入数据二进制位长度即可
    while (pixelPosition < data.length) {
        //取出第一个像素
        UInt32 v = pixels[pixelPosition];
        
        //取出第一个二进制数据
        Byte bit = intactBytes[pixelPosition];
        
        //保护避免超出图片大小，并把数据存入图片像素中
        v = v & 0xFFFFFFFE;
        v = v | bit;
        pixels[pixelPosition] = v ;
            
        pixelPosition++;
    }
    
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:newCGImage];
    CGImageRelease(newCGImage);
    return result;
    
}


@end
