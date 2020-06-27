//
//  SteganographyUtil.m
//  TestLSB
//
//  Created by hongqiang dong on 2020/6/27.
//  Copyright © 2020 hongqiang dong. All rights reserved.
//
#define MAX_TEXT_LENGTH  10000
#define MIN_IMAGE_SIZE  10000
int const BYTES_PER_PIXEL = 4;
int const BITS_PER_COMPONENT = 8;

int const k4BYTES_PER_INT = 4;
int const k8BITS_PER_BYTE = 8;

int const TOTAL_BIT_LENGTH = k4BYTES_PER_INT*k8BITS_PER_BYTE;


#import "SteganographyUtil.h"

@implementation SteganographyUtil

+(void)encryptDataWithImage:(UIImage *)image encryptText:(NSString *)encryptText completionBlock:(StegoDecoderCompletionBlock)completionBlock{
    NSData *data = [encryptText dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Text =  [data base64EncodedStringWithOptions:0];
    image =  [image fixOrientation];
    if(encryptText.length>MAX_TEXT_LENGTH){
        completionBlock(2, nil);//数据太长
        return;
    }

    CGImageRef inputCGImage = image.CGImage;
    NSUInteger width = CGImageGetWidth(inputCGImage)/image.scale;
    NSUInteger height = CGImageGetHeight(inputCGImage)/image.scale;
    
    NSUInteger size = height * width;
    
    if(size<MIN_IMAGE_SIZE){
        completionBlock(2, nil);// 图片太小 放不下加密数据
        return;
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
    
    [self handleAppendText:base64Text pixels:pixels pixelsLength:size];
    
    
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
    CGImageRelease(newCGImage);
    
    completionBlock(1,processedImage);
    
}
+(void)parseModelWithImage:(UIImage *)image completionBlock:(StegoEncoderCompletionBlock)completionBlock{
    CGImageRef inputCGImage = image.CGImage;
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    NSUInteger size = height * width;
    
    if(size<MIN_IMAGE_SIZE){
        completionBlock(2, nil);//
    }
    
    
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

    NSInteger dataBlockLength =  [self dataBlockLength:pixels];// 获取长度
    //
    if(dataBlockLength == -1){
        
        if(completionBlock){
            completionBlock(2, nil);
        }
        return ;
    }
    
    UInt32 pixelPosition = k4BYTES_PER_INT*k8BITS_PER_BYTE;
    Byte * dataBytes =calloc(dataBlockLength, sizeof(Byte));
    
    UInt32 index = 0;
    
    while (pixelPosition < (dataBlockLength*k8BITS_PER_BYTE+k4BYTES_PER_INT*k8BITS_PER_BYTE)) {
        
        Byte b =  [self extractByte:pixels fromPosition:pixelPosition];
        dataBytes[index]=b;
        index++;
        pixelPosition = pixelPosition + k8BITS_PER_BYTE ;
        
    }
    
    NSData *data = [NSData dataWithBytes:dataBytes length:dataBlockLength];
    NSInteger offset = 0;
    
    NSData *textData = [data subdataWithRange:NSMakeRange(offset, dataBlockLength-offset)];
    NSString *text = [[NSString alloc] initWithData:textData encoding:NSASCIIStringEncoding];
    
    if(completionBlock){
        completionBlock(1, text);
    }
    CGColorSpaceRelease(colorSpace);
    
    CGContextRelease(context);
}

+(NSData *) buildStringData:(NSString *)string{
    return  [string dataUsingEncoding:NSASCIIStringEncoding];
    
}
+(Byte *)bitBytes:(NSData *)asciiData{
    
    
    int byteLength = (int)asciiData.length;
    Byte *dataBytes = (Byte *)asciiData.bytes;
    int bitLength = byteLength * k8BITS_PER_BYTE;
    
    Byte *bitDataBytes = [self converBitBytes:dataBytes byteLength:byteLength bitLength:bitLength];
    
    
    
    return bitDataBytes;
    
}
+(BOOL)handleAppendText:(NSString *)text  pixels:(UInt32 *)pixels pixelsLength:(NSUInteger)pixelsLength{
    
    NSData *textData = [text dataUsingEncoding:NSASCIIStringEncoding];
    int textBitDataLength =(int) textData.length * k8BITS_PER_BYTE;
    Byte *textBitData = [self bitBytes:textData];
    
    
    int total = textBitDataLength;
    NSData *totalData = [self buildIntData:total/k8BITS_PER_BYTE];
    int totalBitDataLength =(int) totalData.length * k8BITS_PER_BYTE;
    Byte *totalBitData = [self bitBytes:totalData];
    
    NSMutableData *intactData = [NSMutableData data];
    [intactData appendBytes:totalBitData length:totalBitDataLength];
    [intactData appendBytes:textBitData length:textBitDataLength];
    
    const Byte *intactBytes =  intactData.bytes;
    NSInteger intactByteLength =  intactData.length;
    if(totalBitDataLength>pixelsLength){
        return NO;
    }
    UInt32 pixelPosition = 0;
    
    while (pixelPosition < pixelsLength) {
        UInt32 v = pixels[pixelPosition];
        Byte bit =    intactBytes[pixelPosition];
        if(pixelPosition<=intactByteLength){
            v = v & 0xFFFFFFFE; // 获取除了最低位的数据
            v = v | bit; // 插入最低位
            pixels[pixelPosition] = v ;
            
        }
        pixelPosition++;
    }
    
    return YES;
}
+(Byte *)converBitBytes:(Byte *)dataBytes byteLength:(NSInteger) byteLength bitLength:(NSInteger)bitLength{
    Byte *bitDataBytes = (Byte *) calloc(bitLength, sizeof(Byte));
    
    UInt32 byteCursor = 0;
    
    while (byteCursor < byteLength) {
        
        Byte v = (Byte)dataBytes[byteCursor];
        int8_t bitCursor = k8BITS_PER_BYTE-1;
        for (int i=0; i<k8BITS_PER_BYTE; i++) {
            uint8_t lastbit =  (v >> bitCursor) & 1;
            bitDataBytes[byteCursor*k8BITS_PER_BYTE+i] = lastbit;
            
            bitCursor=bitCursor-1;
        }
        byteCursor++;
    }
    
    return bitDataBytes;
    
}
+(NSData *) buildIntData:(int)value{
    int value1 =  ntohl(value);  //高低位转换    不然1 的结果是 1 0 0 0
    return  [NSData dataWithBytes: &value1 length: sizeof(int)];
    
}
+(int)dataBlockLength:(UInt32 *)pixels{
    
    int blockLength =  [self extractInt32:pixels fromPosition:0];
    return blockLength;
}
+(int)extractInt32:(UInt32 *)pixels fromPosition:(NSUInteger)position{
    
    int resut = 0;
    for (int i=0;  i<k4BYTES_PER_INT*k8BITS_PER_BYTE;i++) {
        UInt32 v = pixels[position+i];
        Byte b = v & 0x1;
        resut = resut | (b<<((k4BYTES_PER_INT*k8BITS_PER_BYTE-1)-i));
    }
    
    return resut;
  
}
+(Byte)extractByte:(UInt32 *)pixels fromPosition:(int)position{
    
    
    Byte b = 0;
    for (int i=0;  i<k8BITS_PER_BYTE;i++) {
        UInt32 v = pixels[position+i];
        Byte lastBit = v & 0x1;
        b = b | (lastBit<<((k8BITS_PER_BYTE-1)-i));
    }
    
    return b;
   
}

@end

@implementation UIImage (fixOrientation)




- (UIImage *)fixOrientation
{
    if (self.imageOrientation == UIImageOrientationUp)
        return self;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end
