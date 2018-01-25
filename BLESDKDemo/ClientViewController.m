//
//  ClientViewController.m
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/7.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "ClientViewController.h"
#import "YMZPrinterManager.h"
#import "ChatViewController.h"

@interface ClientViewController ()<UITableViewDelegate, UITableViewDataSource, YMZPrinterManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) YMZPrinterManager *printerManager;

@end

@implementation ClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.printerManager = [[YMZPrinterManager alloc]initWithDelegate:self];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (void)printerManager:(YMZPrinterManager *)printerManager didDiscoverDevice:(id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)device {
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<YMZBLEDeviceProtocol> printer = self.printerManager.didDiscoverPeripherals[indexPath.row];

    ChatViewController *chatVC = [[ChatViewController alloc] init];
    chatVC.printer = (YMZPrinter *)printer;
    [self presentViewController:chatVC animated:YES completion:^{
        
    }];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.printerManager.didDiscoverPeripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    id<YMZBLEDeviceProtocol> printer = self.printerManager.didDiscoverPeripherals[indexPath.row];
    cell.textLabel.text = printer.peripheral.name;
    if (printer.peripheral.state == CBPeripheralStateConnected) {
        cell.textLabel.textColor = [UIColor greenColor];
    }else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    return cell;
}


@end
