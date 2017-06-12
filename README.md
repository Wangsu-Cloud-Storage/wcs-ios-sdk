## wcs-ios-sdk

iOS SDK基于网宿云存储API规范构建，适用于IOS。使用此SDK构建您的移动APP，能让您非常便捷地将数据安全地存储到网宿云平台上。

- [下载链接](https://wcs.chinanetcenter.com/document/SDK/wcs-ios-sdk#下载链接)
- [移动端场景演示](https://wcs.chinanetcenter.com/document/SDK/wcs-ios-sdk#移动端场景演示)
- [使用指南](https://wcs.chinanetcenter.com/document/SDK/wcs-ios-sdk#使用指南) 
  [准备开发环境](https://wcs.chinanetcenter.com/document/SDK/wcs-ios-sdk#准备开发环境)[配置信息](https://wcs.chinanetcenter.com/document/SDK/wcs-ios-sdk#配置信息)[文件上传](https://wcs.chinanetcenter.com/document/SDK/wcs-ios-sdk#文件上传)[常见问题](https://wcs.chinanetcenter.com/document/SDK/wcs-ios-sdk#常见问题)

## 工程介绍

[trunk](https://github.com/Wangsu-Cloud-Storage/wcs-ios-sdk/tree/master/trunk)

工程源码

[TestWCSiOS](https://github.com/Wangsu-Cloud-Storage/wcs-ios-sdk/tree/master/tools/TestWCSiOS)

demo 例子

## 



### 下载链接

[wcs-ios-sdk下载链接](https://wcsd.chinanetcenter.com/sdk/cnc-ios-sdk-wcs.zip)

### 移动端场景演示

1) 移动端向企业自建WEB服务端请求上传凭证 
2) 企业自建WEB服务端将构建好的上传凭证返回移动端 
3) 移动端调用网宿云存储平台提供的接口上传文件 
4) 网宿云存储在检验凭证合法性后，执行移动端请求的接口逻辑，最终返回给移动端处理结果 
![移动端场景演示](https://wcs.chinanetcenter.com/indexNew/image/wcs/wcs-ios-sdk1.png)

### 使用指南

#### 准备开发环境

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
在工程中引入SDK的wcs-java-sdk-x.x.x.jar包，和wcs-java-sdk-x.x.x-dependencies.zip文件中解压出来的第三方jar包（以eclipse为例） 
![服务端开发环境准备](https://wcs.chinanetcenter.com/indexNew/image/wcs/wcs-ios-sdk3.png)

#### 配置信息

用户接入网宿云存储时，需要使用一对有效的AK和SK进行签名认证，并填写“上传域名”进行文件上传。配置信息只需要在整个应用程序中初始化一次即可，具体操作如下：

- 开通网宿云存储平台账户
- 登录网宿云存储平台，在“安全管理”下的“密钥管理”查看AK和SKK，“域名查询”查看上传、管理域名。

在获取到AK和SK等信息之后，您可以按照如下方式进行密钥初始化：

```objective-c
import com.chinanetcenter.api.util.Config;
//1.初始化信息
String ak = "your access key";
String sk = "your secrete key";
String PUT_URL = "your uploadDomain";
Config.init(ak,sk,PUT_URL,"");
```

#### 文件上传

<1>表单上传时可开启returnurl进行页面跳转，其他情况下建议不设置returnurl。 
<2>若文件大小超过2M，建议使用分片上传 
<3>云存储提供的上传域名为普通域名，若对上传速度较为敏感，有要求的客户建议采用网宿上传加速服务。

1.普通上传（POST方式） 
用户在上传后，上传返回结果由云存储平台统一控制，规范统一化。

**范例：**

```objective-c
- (void)normalUpload {
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

4.分片上传（POST方式） 
移动端上传大文件需要耗费较长时间，一旦在传输过程中出现异常，文件内容需全部重传，影响用户体验，为避免这个问题，引进分片上传机制。 
分片上传机制是将一个大文件切分成多个自定义大小的块，然后将这些块并行上传，一旦某个块上传失败，客户端只需要重新上传这个块即可。 
*注意：每个块的最大大小不能超过4M，超过4M的设置，将采用默认最大4M切分；最小不能小于1M，小于1M，将会采用1M去切分。*

**范例**

```objective-c
- (void)chunkedUpload {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"上传到云端的文件名，不填则以原文件名命名";
  blockRequest.fileURL = fileURL; // 文件的URL
  blockRequest.token = @"上传的token，由服务端提供";  
  [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%@ %@", @(totalBytesSent), @(totalBytesExpectedToSend));
  }];
  // 建议复用WCSClient
  WCSClient *client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
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

#### 常见问题

1）方法无法被识别，如：-[__NSCFDictionary safeStringForKey:]: unrecognized selector sent to instance 0x7f8c51d3c260。 
请确认已在Other Linker Flags添加-ObjC

2）链接_crc32异常 
请添加libz.tbd到工程中

3）链接_UTTypeCopyPreferredTagWithClass异常 
请添加MobileCoreServices.framework到工程中