//
//  DisplayViewController.m
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/7.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "DisplayViewController.h"
#import "YMZBLEPeripheralManager.h"
#import "YMZDisplayServiceManager.h"

@interface DisplayViewController ()<YMZDisplayServiceManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *tf;
@property (nonatomic, strong) YMZBLEPeripheralManager *peripheralManager;

@end

@implementation DisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak typeof(self) weakSelf = self;
    self.peripheralManager = [[YMZBLEPeripheralManager alloc]initWithCompletedBlock:^(CBManagerState state) {
        weakSelf.peripheralManager.advertisementDataLocalName = @"你发我什么我就展示什么";
        if (state == CBManagerStatePoweredOn) {
            YMZDisplayServiceManager *displayServiceManager = [[YMZDisplayServiceManager alloc]init];
            displayServiceManager.delegate = self;
            [weakSelf.peripheralManager didAddServiceWithServiceManager:displayServiceManager];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - YMZDisplayServiceManagerDelegate
- (void)didReceiveData:(NSString *)string {
    self.tf.text = string;
}
@end
