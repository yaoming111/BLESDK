
# BLESDK
**BLE 蓝牙低功耗  灵活好用的SDK**

## 特点
- 能快速集成到现有工程
- 容易理解
- 代码很少
- 非单例设计（多种不同类型的外设分开处理，简化逻辑便于维护）
- 想要的功能随自己扩展（只需继承下已提供外设基类）


## 中心设备（客户端）
### 功能

##### 搜索蓝牙BLE外设
- 可选指定特殊服务ID搜索
- 可选指定外设名称子串搜索
- 记录所有已搜索的设备便于展示

##### 长数据发送分包发送（不分包会发送失败）
- 可指定分包长度

##### 可靠地发送结果回调
- 发送成功回调
- 发送失败回调

##### 命令发送（同一特征值，不支持在没拿到返回时继续发送另一个命令）
- 对外设发送无返回命令
- 对外设发送有返回命令，并拿到返回值

##### 读取指定特征值
- block直接返回特征值

##### 可选设置异常断开重连

##### 中心设备接入指南
一、自定义外设管理器

推荐创建一个单例类并持有一个中心设备管理器`YMZBLEManager`对象，以下均按这种思路设计，当然最终实现看自己的想法

**已demo为例:**
```
@interface YMZPrinterManager()<CHDBLEManagerDelegate, CHDBLEManagerDatasource>
@property (nonatomic, strong) YMZBLEManager *manager;

@end
```

YMZPrinterManager持有YMZBLEManager对象并遵守 CHDBLEManagerDelegate、 CHDBLEManagerDatasource协议
```
@protocol CHDBLEManagerDelegate <NSObject>
@required
//central.state == CBManagerStatePoweredOn 才能发起搜索
- (void)BLEManager:(YMZBLEManager *)BLEManager centralManagerDidUpdateState:(CBCentralManager *)central;

- (void)BLEManager:(YMZBLEManager *)BLEManager didDiscoverDevice:(id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)device;
@optional

@end

@protocol CHDBLEManagerDatasource <NSObject>
@required
/*! 在这里返回 遵守CHDDeviceProtocol,CBPeripheralDelegate 协议的外设对象*/
- (id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)BLEManager:(YMZBLEManager *)BLEManager conversionCustomDeviceInstanceWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;

@optional

/*! 设备名称包含的字符数组 设备名称包含 数组指定的其中一个子串才能放进已搜索设备*/
- (NSArray<NSString *> *)deviceNameContainSubStringArray;
/*! 搜索服务的UUID数组*/
- (NSArray<CBUUID *> *)deviceServiceUUIDs:(id<YMZBLEDeviceProtocol>)device;

- (NSArray<CBUUID *> *)discoverCharacteristics:(CBService *)service;

/*! 有新的设备已连接*/
- (void)BLEManager:(YMZBLEManager *)BLEManager didConnictedDevice:(id<YMZBLEDeviceProtocol>)device;
@end
```
实现必须实现的`required`协议方法
实现非必须`optional`协议方法扩展功能

二、自定义外设对象
自定义外设对象`YMZPrinter`继承自`YMZBaseBLEDevice`

**已demo为例：**

实现几个实用方法
```
@interface YMZPrinter : YMZBaseBLEDevice
/**
 分包发送数据
 
 @param data 要发的数据
 @param writeDataBlock 写数据完成、失败回调
 */
- (void)subcontractWriteValue:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock;

/**
 发送带返回值的命令
 
 @param command 命令数据
 @param writeDataBlock 写命令完成、失败回调
 @param responseBlock 硬件响应信息
 */
- (void)writeCommand:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock;

/**
 读数据

 @param responseBlock 响应信息
 */
- (void)readDataWithResponseBlock:(YMZResponseBlock _Nullable )responseBlock;
@end
```

三、接入
1、创建YMZPrinterManager实例
```
///创建并强引用一个YMZPrinterManager实例，如果你设计的是单例就不用强引用了
self.printerManager = [[YMZPrinterManager alloc]initWithDelegate:self];
```
2、实现代理方法 当有新设备被搜到时被调用
```
- (void)printerManager:(YMZPrinterManager *)printerManager didDiscoverDevice:(id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)device {
	dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
```
2、实现
已经接好了！！
##### 中心设备API使用

1、基本属性和方法 以协议方式给出
```
@protocol YMZBLEDeviceProtocol <NSObject>

NS_ASSUME_NONNULL_BEGIN
@required
@property (nonatomic, strong)   CBPeripheral *peripheral;
/*! 对中心设备的一个引用*/
@property (nonatomic, weak)     CBCentralManager *centralManager;
NS_ASSUME_NONNULL_END
/*! 异常断开重连 默认 NO  手动断开时请先赋值为NO防止断开后重新连接   ⚠️：手动调用断开时会被置为NO，如需保持自动重连请在连接前赋值YES*/
@property (nonatomic, assign) BOOL reconnect;
@optional
/*! 发起连接*/
- (void)connectWithResultBlock:(ConnectBlock _Nullable )resultBlock;
/*! 断开连接*/
- (void)disConnectWithResultBlock:(DisconnectBlock _Nullable )resultBlock;
/*! 配置需要的特征 必须实现并正确配置*/
- (void)configCharacteristicsWithService:(CBService *_Nonnull)service;
/*! 连接成功*/
- (void)didConnected;
/*! 连接失败*/
- (void)didFailToConnect;
/*! 已断开*/
- (void)didDisConnected;
/*! 已接收到characteristic属性更新的数据*/
- (void)didUpdateValueForCharacteristic:(CBCharacteristic *_Nonnull)characteristic error:(NSError *_Nullable)error;

- (NSArray<CBUUID *> *_Nullable)servicesUUID;
@end

```
2、设备基类`YMZBaseBLEDevice`扩展方法
```
@interface YMZBaseBLEDevice : NSObject<YMZBLEDeviceProtocol, CBPeripheralDelegate>

/**
 分包发送数据

 @param characteristic 指定的特征
 @param data 要发的数据
 @param writeDataBlock 写数据完成、失败回调  回调在非UI线程 需要刷新UI请切换UI线程
 */
- (void)subcontractWriteValueToCharacteristic:(CBCharacteristic *_Nonnull)characteristic value:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock;

/**
 发送带返回值的命令

 @param characteristic 指定的特征
 @param command 命令数据
 @param writeDataBlock 写命令完成、失败回调     回调在非UI线程 需要刷新UI请切换UI线程
 @param responseBlock 硬件响应信息            回调在非UI线程 需要刷新UI请切换UI线程
 */
- (void)writeCommandToCharacteristic:(CBCharacteristic *_Nonnull)characteristic command:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock;
/*! */
/**
 读指定特征的值

 @param characteristic 指定的特征
 @param responseBlock 读到值的回调
 */
- (void)readValueForCharacteristic:(CBCharacteristic *_Nonnull)characteristic responseBlock:(YMZResponseBlock _Nullable )responseBlock;
@end

```

## 外设（服务端）



