//
//  ViewController.m
//  TestLSB
//
//  Created by hongqiang dong on 2020/6/25.
//  Copyright © 2020 hongqiang dong. All rights reserved.
//

#import "ViewController.h"
//#import "IMSteganographyService.h"
#import "SteganographyUtil.h"
#import "SteganographyHelper.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *encryptBtn;
@property (weak, nonatomic) IBOutlet UIButton *deencryptBtn;
@property (weak, nonatomic) IBOutlet UIImageView *showImageView;
@property (weak, nonatomic) IBOutlet UITextField *signTextField;
@property (weak, nonatomic) IBOutlet UILabel *encryptText;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.showImageView.image = [UIImage imageNamed:@"test.png"];
    
//    UIImage *img = [UIImage imageNamed:@"test.png"];
//       UIImage *img1 = [SteganographyHelper incorporateTextWithUIImage:img text:@"中华人民共和国"];
//       
//       NSString *result = [SteganographyHelper extractTextFromUIImage:img1];
//       
//       NSLog(@"result = %@" , result);
}
- (IBAction)encryptAction:(id)sender {
//    __weak typeof(self) weakSelf = self;
//    [SteganographyUtil encryptDataWithImage:[UIImage imageNamed:@"test.png"] encryptText:self.signTextField.text completionBlock:^(int code, UIImage *image) {
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        NSLog(@"encrypt code = %d", code);
//        if (code == 1) {
//            strongSelf.showImageView.image = image;
//        }
//    }];
    self.showImageView.image = [SteganographyHelper incorporateTextWithUIImage:[UIImage imageNamed:@"test.png"] text:self.signTextField.text];

}
- (IBAction)deencryptAction:(id)sender {
//    __weak typeof(self) weakSelf = self;
//    [SteganographyUtil parseModelWithImage:self.showImageView.image completionBlock:^(int code, NSString *result) {
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        NSLog(@"dencrypt code = %d", code);
//        if (code == 1) {
//            NSData *data = [[NSData alloc] initWithBase64EncodedString:result options:NSDataBase64DecodingIgnoreUnknownCharacters];
//            NSString *string =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            strongSelf.encryptText.text = string;
//        }
//    }];

    self.encryptText.text = [SteganographyHelper extractTextFromUIImage:self.showImageView.image];
}


@end
