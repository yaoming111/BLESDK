//
//  ChatViewController.m
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/7.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "ChatViewController.h"

@interface ChatViewController ()
@property (weak, nonatomic) IBOutlet UITextField *tf;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (IBAction)connect:(id)sender {
    [self.printer connectWithResultBlock:^(BOOL success, NSString * _Nullable errorDescription) {
 
    }];
}
- (IBAction)disconnect:(id)sender {
    [self.printer disConnectWithResultBlock:^(BOOL success, NSString * _Nullable errorDescription) {
        
    }];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (IBAction)sendMesage:(id)sender {
    [self.printer subcontractWriteValue:[self.tf.text dataUsingEncoding:NSUTF8StringEncoding] writeDataBlock:^(BOOL success, NSError * _Nullable error) {
        
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
