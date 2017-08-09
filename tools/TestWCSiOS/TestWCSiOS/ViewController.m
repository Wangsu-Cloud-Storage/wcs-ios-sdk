//
//  ViewController.m
//  TestWCSiOS
//
//  Created by mato on 16/5/6.
//  Copyright © 2016年 CNC. All rights reserved.
//   代码调用范例

#import "ViewController.h"
//#import <AFNetworking/AFNetworking.h>可有可无 可以不要
#import <WCSiOS/WCSClient.h>
#import <CoreImage/CoreImage.h>

static NSString * const kNormalTokan = @"";


static NSString * const kCustomParamsToken = @"";

@interface ViewController ()

@property (nonatomic, strong) WCSClient *client;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSURL *sliceFileURL;
@property (nonatomic, strong) NSArray *fileNameArray;
@property (nonatomic, strong) NSArray *fileSizeArray;

@end

@implementation ViewController

- (NSString *)getDocumentDirectory {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fileNameArray = @[@"file100k", @"file1m", @"file10m", @"file50m", @"file100m", @"file500m"];
    self.fileSizeArray = @[@102400, @1024000, @10240000, @51200000, @102400000, @512000000];
    self.client = [[WCSClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://apitestuser.up0.v1.wcsapi.com"] andTimeout:30];
    self.fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"exif.jpg"]];
    self.sliceFileURL = [NSURL URLWithString:[[self getDocumentDirectory] stringByAppendingPathComponent:@"file10m"]];
    [WCSLogger defaultLogger].logLevel = WCSLogLevelVerbose;
    NSLog(@"slice file URL : %@", self.sliceFileURL);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// 普通上传
- (IBAction)testUpload:(id)sender {
    WCSUploadObjectRequest *uploadRequest = [[WCSUploadObjectRequest alloc] init];
    uploadRequest.token = kNormalTokan;
    uploadRequest.key = @"exif2.jpg";
    uploadRequest.fileName = @"exif.jpg";
    uploadRequest.fileURL = self.fileURL;
    [uploadRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"=== %@ %@", @(totalBytesSent), @(totalBytesExpectedToSend));
    }];
    
//    [[self.client uploadRequestRaw:uploadRequest] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectStringResult *> * _Nonnull task) {
//        NSLog(@"%@", task.error.localizedDescription);
//        if (task.error) {
//            NSLog(@"%@", task.error);
//        } else {
//            NSLog(@"%@", task.result.resultString);
//        }
//        return nil;
//    }];
    
    [[self.client uploadRequest:uploadRequest] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
        if (task.error) {
            NSLog(@"===ERROR===\r\n%@", task.error);
        } else {
            NSLog(@"%@", task.result.results);
        }
        return nil;
    }];
}

// 普通上传-自定义变量
- (IBAction)testCustom:(id)sender {
    NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"exif.jpg"]];
    WCSUploadObjectRequest *uploadRequest = [[WCSUploadObjectRequest alloc] init];
    uploadRequest.token = kCustomParamsToken;
    uploadRequest.key = @"exifCustom.jpg";
    uploadRequest.fileName = @"exif.jpg";
    uploadRequest.fileURL = fileURL;
    // 自定义变量
    uploadRequest.customParams = @{@"x:test" : @"customParams"};
    [uploadRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%@ %@", @(totalBytesSent), @(totalBytesExpectedToSend));
    }];
    
    [[self.client uploadRequest:uploadRequest] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
        if (task.error) {
            NSLog(@"%@", task.error);
        } else {
            NSLog(@"%@", task.result.results);
        }
        return nil;
    }];
}

// 普通上传-取消
- (IBAction)testCancel:(id)sender {
    NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"exif.jpg"]];
    WCSUploadObjectRequest *uploadRequest = [[WCSUploadObjectRequest alloc] init];
    uploadRequest.token = kNormalTokan;
    uploadRequest.key = @"exifCustom.jpg";
    uploadRequest.fileName = @"exif.jpg";
    uploadRequest.fileURL = fileURL;
    // 自定义变量
    uploadRequest.customParams = @{@"x:test" : @"customParams"};
    [uploadRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%@ %@", @(totalBytesSent), @(totalBytesExpectedToSend));
    }];
    
    [[self.client uploadRequest:uploadRequest] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [uploadRequest cancel];
    });
}

- (IBAction)testChunked:(id)sender {
    WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
    blockRequest.fileKey = @"sliceFileURL";
    blockRequest.fileURL = self.sliceFileURL;
    blockRequest.uploadToken = kNormalTokan;
//    blockRequest.blockSize = 100 * 1024 * 1024;
//    blockRequest.chunkSize = 1024 * 512;
    [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"=========== %@ %@", @(totalBytesSent), @(totalBytesExpectedToSend));
    }];
    
    [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
        if (task.error) {
            NSLog(@"error %@ %@", task.error.localizedDescription, task.error.userInfo);
        } else {
            NSLog(@"results %@", task.result.results);
        }
        return nil;
    }];
}

- (IBAction)cancelChunkUpload:(UIButton *)sender {
    WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
    blockRequest.fileKey = @"sliceFileURL";
    blockRequest.fileURL = self.sliceFileURL;
    blockRequest.uploadToken = kNormalTokan;
    [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"=========== %@ %@", @(totalBytesSent), @(totalBytesExpectedToSend));
    }];
    
    [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
        if (task.error) {
            NSLog(@"error %@", task.error.localizedDescription);
        } else {
            NSLog(@"results %@", task.result.results);
        }
        return nil;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"************ cancelled blockRequest");
        [blockRequest cancel];
    });
}

- (IBAction)initialFiles:(UIButton *)sender {
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * mainDir = [self getDocumentDirectory];
    
    
    for (int i = 0; i < [self.fileNameArray count]; i++) {
        NSMutableData * basePart = [NSMutableData dataWithCapacity:1024];
        for (int j = 0; j < 1024/4; j++) {
            u_int32_t randomBit = j;// arc4random();
            [basePart appendBytes:(void*)&randomBit length:4];
        }
        NSString * name = [self.fileNameArray objectAtIndex:i];
        long size = [[self.fileSizeArray objectAtIndex:i] longValue];
        NSString * newFilePath = [mainDir stringByAppendingPathComponent:name];
        if ([fm fileExistsAtPath:newFilePath]) {
            NSLog(@"file exists %@", newFilePath);
            continue;
        }
        [fm createFileAtPath:newFilePath contents:nil attributes:nil];
        NSFileHandle * f = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
        for (int k = 0; k < size/1024; k++) {
            [f writeData:basePart];
        }
        [f closeFile];
        NSLog(@"initial file : %@", newFilePath);
    }
    NSLog(@"initial file DONE.");
}

@end
