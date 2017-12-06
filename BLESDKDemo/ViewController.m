//
//  ViewController.m
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "ViewController.h"
#import "YMZPrinterManager.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) YMZPrinterManager *printerManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.printerManager = [[YMZPrinterManager alloc]init];
    
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<YMZBLEDeviceProtocol> printer = self.printerManager.didDiscoverPeripherals[indexPath.row];
    __weak typeof(tableView) weakTableview = tableView;
    if (printer.peripheral.state == CBPeripheralStateConnected) {
        [printer disConnectWithResultBlock:^(BOOL success, NSString * _Nullable errorDescription) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakTableview reloadData];
            });
        }];
    }else if(printer.peripheral.state == CBPeripheralStateDisconnected){
        [printer connectWithResultBlock:^(BOOL success, NSString * _Nullable errorDescription) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakTableview reloadData];
            });
        }];
    }
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
