- [准备](#开发准备)
- [工程介绍](#工程介绍)
- [安装](#安装说明)
- [初始化](#初始化说明)
- [使用指南](#使用指南)
  - [普通上传](#普通上传)
  - [分片上传](#分片上传)
- [常见问题](#常见问题)

## 开发准备
* 账号要求：已开通网宿云存储，并获取上传密钥，上传域名等
* 系统要求：iOS7及以上

## 工程介绍
1. [wcs-ios-sdk下载链接](http://wcsd.chinanetcenter.com/sdk/wcs-ios-sdk-2.2.5.zip)
2. [工程源码](https://github.com/Wangsu-Cloud-Storage/wcs-ios-sdk/tree/master/trunk)
3. [demo&例子](https://github.com/Wangsu-Cloud-Storage/wcs-ios-sdk/tree/master/tools/TestWCSiOS)

## 安装说明
一、移动端开发环境准备
1)工程的发布SDK设置为iOS7或iOS7以上
2)将WCSiOS.framework添加到工程环境下，并确认WCSiOS.framework已经被添加到工程所使用的Target下的 Build Phases -> Link Binary With Libraries下
3)SDK依赖的系统库如下，请确保将以下系统库添加到Link Binary With Libraries下

```objective-c
MobileCoreServices.framework
libz.dylib(libz.tbd for Xcode7+)
```

4)工程编译环境
SDK的framework包含Category，所以需要添加-ObjC选项，否则在使用过程中会出现selector无法识别的异常，如：
-[__NSCFDictionary safeStringForKey:]: unrecognized selector sent to instance 0x7f8c51d3c260
![添加-objc](https://wcs.chinanetcenter.com/indexNew/image/wcs/wcs-ios-sdk2.png)

二、服务端开发环境准备
服务端开发环境请参考wcs-Java-SDK: https://github.com/Wangsu-Cloud-Storage/wcs-java-sdk


## 初始化说明
* 用户接入网宿云存储时，需要使用一对有效的AK和SK进行签名认证。为保证ak，sk的安全性，推荐客户通过自己的服务端下发鉴权凭证。
* 配置上传域名&超时时间
```
self.client = [[WCSClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://yourUploadDomain.com"] andTimeout:30];
```

## 使用指南

### 普通上传
* 表单上传时可开启returnurl进行页面跳转，其他情况下建议不设置returnurl。
* 若文件大小超过20M，建议使用分片上传
* 云存储提供的上传域名为普通域名，若对上传速度较为敏感，有要求的客户建议采用网宿上传加速服务。

1. 普通上传
**范例：**

```objective-c
- (void)normalUpload {
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.token = @"上传的token，由服务端提供";
  request.fileName = @"上传的文件名";
  request.key = @"上传到云端的文件名，不填云端则以fileName命名";
  request.fileData = fileData; // 要上传的文件
  request.mimeType = @"文件contentType"; // 无特殊需求可不配置，由系统匹配content-type
  request.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%lld bytes sent, %lld total bytes sent, %lld total byte exptected", bytesSent, totalBytesSent, totalBytesExpectedToSend);
  };
  // 建议复用WCSClient
  WCSClient *client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
  
  // 注：如使用callback回调上传，需要使用uploadRequestRaw方法，避免多一次不必要的base64解析导致异常
  [[client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
    if (task.error) {
      NSLog(@"The request failed. error: [%@]", task.error);
} else {
  // 请求成功，以下为服务端返回的内容
      NSDictionary *responseResult = task.result.results;
    }
    return nil;
  }];
}
```

2.取消正在上传的请求
**范例：**

```objective-c
- (void)normalUploadCancelled {
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.token = @"上传的token，由服务端提供";
  request.fileName = @"上传的文件名";
  request.key = @"上传到云端的文件名，不填云端则以fileName命名";
  request.fileData = fileData; // 要上传的文件
  request.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%lld bytes sent, %lld total bytes sent, %lld total byte exptected", bytesSent, totalBytesSent, totalBytesExpectedToSend);
  };
  // 建议复用WCSClient
  WCSClient *client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
  [[client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
    if (task.error) {
      // 请求被取消。
      if (task.error.code == NSURLErrorCancelled) {
        NSLog(@"request cancelled.");
      } else {
        NSLog(@"%@", task.error);
      }
    } else {
      NSLog(@"%@", task.result.results);
}
return nil;
  }];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),   dispatch_get_main_queue(), ^{
    [uploadRequest cancel];
  });
}
```

3.自定义变量上传(POST方式)

**范例：**

```objective-c
- (void)normalUpload {
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.token = @"上传的token，由服务端提供";
  // 自定义变量，自定义变量会在上传成功后返回给客户端。
  // 更多关于自定义变量请参考：
  // https://wcs.chinanetcenter.com/document/API/Terminology#自定义替换变量
  request.customParams = @{@"x:test" : @"customParams"};
  request.fileName = @"上传的文件名";
  request.key = @"上传到云端的文件名，不填云端则以fileName命名";
  request.fileData = fileData; // 要上传的文件
  request.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%lld bytes sent, %lld total bytes sent, %lld total byte exptected", bytesSent, totalBytesSent, totalBytesExpectedToSend);
  };
  // 建议复用WCSClient
  WCSClient *client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
  
  // 注：如使用callback回调上传，需要使用uploadRequestRaw方法，避免多一次不必要的base64解析导致异常
  [[client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
    if (task.error) {
      NSLog(@"The request failed. error: [%@]", task.error);
} else {
  // 请求成功，以下为服务端返回的内容
      NSDictionary *responseResult = task.result.results;
    }
    return nil;
  }];
}
```

### 分片上传
* 移动端上传大文件需要耗费较长时间，一旦在传输过程中出现异常，文件内容需全部重传，影响用户体验，为避免这个问题，引进分片上传机制。
* 分片上传机制是将一个大文件切分成多个自定义大小的块，然后将这些块并行上传，一旦某个块上传失败，客户端只需要重新上传这个块即可。
*注意：每个块的最大大小不能超过100M，最小不能小于4M。*

**范例**

```objective-c
- (void)chunkedUpload {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"上传到云端的文件名，不填则以原文件名命名";
  blockRequest.fileURL = fileURL; // 文件的URL
  blockRequest.token = @"上传的token，由服务端提供";
  blockRequest.mimeType = @"文件contentType"; // 无特殊需求可不配置，由系统匹配content-type
  blockRequest.chunkSize = 256 * 1024; // 注意：片的大小必须是64K的倍数，最大不能超过块的大小。
  blockRequest.blockSize = 4 * 1024 * 1024; // 注意：块的大小必须是4M的倍数，最大不能超过100M
  [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%@ %@", @(totalBytesSent), @(totalBytesExpectedToSend));
  }];
  // 建议复用WCSClient
  WCSClient *client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
  
  // 注：如使用callback回调上传，需要使用blockUploadRequestRaw方法，避免多一次不必要的base64解析导致异常
  [[client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    if (task.error) {
      NSLog(@"error %@", task.error.localizedDescription);
} else {
  // 上传成功，打印返回的参数。
      NSLog(@"results %@", task.result.results);
    }
    return nil;
  }];
```

### 常见问题
1）方法无法被识别，如：-[__NSCFDictionary safeStringForKey:]: unrecognized selector sent to instance 0x7f8c51d3c260。
请确认已在Other Linker Flags添加-ObjC

2）链接_crc32异常
请添加libz.tbd到工程中

3）链接_UTTypeCopyPreferredTagWithClass异常
请添加MobileCoreServices.framework到工程中

4）nslog信息本地保存
请参照demo的 AppDelegate.m 里面 [self redirectNSLogToDocumentFolder];
