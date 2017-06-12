//
//  WCSBlockUploadTests.m
//  WCSiOS
//
//  Created by mato on 16/4/27.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WCSClient.h"
#import "WCSLogging.h"
#import "NSData+WCSCommonAlgorithm.h"

#define RESOURCE_PATH [[NSBundle bundleForClass:[self class]] resourcePath]

static NSString * const kNormalTokan = @"db17ab5d18c137f786b67c490187317a0738f94a:NTg4OTQxNWNkNTYwNzJiMGQwMTkxNWI5M2NjYzY1MTNjNjllMGRkZA==:eyJzY29wZSI6ImltYWdlczp5c3l0ZXN0IiwiZGVhZGxpbmUiOiI0MDcwODgwMDAwMDAwIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowLCJpbnN0YW50IjowLCJzZXBhcmF0ZSI6MH0=";

@interface WCSChunkUploadTests : XCTestCase

@property (nonatomic, strong) WCSClient *client;
@property (nonatomic, copy) NSArray *fileNameArray;
@property (nonatomic, copy) NSArray *fileSizeArray;

@end

@implementation WCSChunkUploadTests

- (void)setUp {
  [super setUp];
  [WCSLogger defaultLogger].logLevel = WCSLogLevelVerbose;
  self.client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
  self.fileNameArray = @[@"file100k", @"file1m", @"file10m", @"file50m", @"file100m", @"file500m"];
  self.fileSizeArray = @[@102400, @1024000, @10240000, @51200000, @102400000, @512000000];
  [self initialFiles];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testNotExistFileURL {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"image.gif";
  blockRequest.fileURL = [NSURL URLWithString:[RESOURCE_PATH stringByAppendingPathComponent:@"image"]];
  blockRequest.uploadToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YzI1ZmQ3YmVjZmQ3ZGQzOGVkZDdiNGEyNzQ0MTNmY2U3YTk0MDk5NA==:eyJzY29wZSI6ImltYWdlcyIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  XCTestExpectation *expection = [self expectationWithDescription:@"testNotExistFileURL for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    XCTAssertNotNil(task.error);
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testInvalidateToken {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"image.gif";
  blockRequest.fileURL = [NSURL URLWithString:[RESOURCE_PATH stringByAppendingPathComponent:@"image.gif"]];
  blockRequest.uploadToken = @"fdsjaklfjdksl";

  XCTestExpectation *expection = [self expectationWithDescription:@"testInvalidateToken for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    XCTAssertNotNil(task.error);
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testSingleChunk {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"LiveWallpapersPicker2.apk";
  blockRequest.fileURL = [NSURL URLWithString:[RESOURCE_PATH stringByAppendingPathComponent:@"LiveWallpapersPicker.apk"]];
  // Token from {"scope":"images","deadline":"4070880000000","returnBody":"bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)","overwrite":1,"fsizeLimit":0}
  blockRequest.uploadToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YzI1ZmQ3YmVjZmQ3ZGQzOGVkZDdiNGEyNzQ0MTNmY2U3YTk0MDk5NA==:eyJzY29wZSI6ImltYWdlcyIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  
  XCTestExpectation *expection = [self expectationWithDescription:@"testSingleChunk for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    XCTAssertNil(task.error, @"unexpected error %@", task.error);
    XCTAssert(task.result);
    WCSBlockUploadResult *blockUploadResult = task.result;
    XCTAssert(blockUploadResult.results);
    XCTAssert([[blockUploadResult.results objectForKey:@"key"] isEqualToString:@"LiveWallpapersPicker2.apk"]);
    NSLog(@"results %@", blockUploadResult.results);
    
    [expection fulfill];
    return nil;
  }];
  
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testCanceledRequestAndResume {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"file50m";
  blockRequest.fileURL = [NSURL URLWithString:[[self getDocumentDirectory] stringByAppendingPathComponent:@"file50m"]];
  // Token from {"scope":"images","deadline":"4070880000000","returnBody":"bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)&test=$(x:test)&desc=$(x:desc)","overwrite":1,"fsizeLimit":0}
  blockRequest.uploadToken = kNormalTokan;
  
  XCTestExpectation *expection = [self expectationWithDescription:@"testNormal for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    XCTAssert(task.error.code == NSURLErrorCancelled, @"unexpected error %@", task.error);
    [expection fulfill];
    return nil;
  }];
  [NSThread sleepForTimeInterval:1];
  [blockRequest cancel];
  [self waitForExpectationsWithTimeout:60 handler:nil];
  
  // Try resume chunks
  WCSBlockUploadRequest *resumeRequest = [WCSBlockUploadRequest new];
  resumeRequest.fileKey = @"file50m";
  resumeRequest.fileURL = [NSURL URLWithString:[[self getDocumentDirectory] stringByAppendingPathComponent:@"file50m"]];
  resumeRequest.uploadToken = kNormalTokan;
  [resumeRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"resume total bytes sent %@ total bytes expected %@", @(totalBytesSent), @(totalBytesExpectedToSend));
  }];

  XCTestExpectation *resumeExpection = [self expectationWithDescription:@"testNormal for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:resumeRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    XCTAssertNil(task.error, @"unexpected error %@", task.error);
    XCTAssert(task.result);
    [resumeExpection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testCustomParams {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"oschina32211";
  blockRequest.fileURL = [NSURL URLWithString:[RESOURCE_PATH stringByAppendingPathComponent:@"oschina"]];
  // Token from {"scope":"images","deadline":"4070880000000","returnBody":"bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)&test=$(x:test)&desc=$(x:desc)","overwrite":1,"fsizeLimit":0}
  blockRequest.uploadToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YTg2ZDU5ZGNmZjc4MGFkZDhhNjMwY2Y0MTUyZjNlZmVlZDY0NTg4OQ==:eyJzY29wZSI6ImltYWdlcyIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpJnRlc3Q9JCh4OnRlc3QpJmRlc2M9JCh4OmRlc2MpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  blockRequest.customParams = @{@"x:test" : @"test", @"x:desc" : @"fdsfd"};
  [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"total bytes sent %@ total bytes expected %@", @(totalBytesSent), @(totalBytesExpectedToSend));
  }];
  
  XCTestExpectation *expection = [self expectationWithDescription:@"testNormal for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    WCSBlockUploadResult *blockUploadResult = task.result;
    XCTAssertNil(task.error, @"unexpected error %@", task.error);
    XCTAssert(task.result);
    XCTAssert(blockUploadResult.results);
    XCTAssertTrue([[blockUploadResult.results objectForKey:@"key"] isEqualToString:@"oschina32211"]);
    XCTAssertTrue([[blockUploadResult.results objectForKey:@"test"] isEqualToString:@"test"]);
    XCTAssertTrue([[blockUploadResult.results objectForKey:@"desc"] isEqualToString:@"fdsfd"]);
    NSLog(@"results %@", blockUploadResult.results);
    
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testNormal {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"image.gif";
  blockRequest.fileURL = [NSURL URLWithString:[RESOURCE_PATH stringByAppendingPathComponent:@"image.gif"]];
  // Token from {"scope":"images","deadline":"4070880000000","returnBody":"bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)","overwrite":1,"fsizeLimit":0}
  blockRequest.uploadToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YzI1ZmQ3YmVjZmQ3ZGQzOGVkZDdiNGEyNzQ0MTNmY2U3YTk0MDk5NA==:eyJzY29wZSI6ImltYWdlcyIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  
  XCTestExpectation *expection = [self expectationWithDescription:@"testNormal for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    if (task.error) {
      NSLog(@"error %@", task.error.localizedDescription);
    }
    XCTAssertNil(task.error);
    XCTAssert(task.result);
    WCSBlockUploadResult *blockUploadResult = task.result;
    XCTAssert(blockUploadResult.results);
    XCTAssert([[blockUploadResult.results objectForKey:@"key"] isEqualToString:@"image.gif"]);
    NSLog(@"results %@", blockUploadResult.results);
    
    [expection fulfill];
    return nil;
  }];
  
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testChunkSize {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"file50m";
  blockRequest.fileURL = [NSURL URLWithString:[[self getDocumentDirectory] stringByAppendingPathComponent:@"file50m"]];
  blockRequest.chunkSize = 4 * 1024 * 1024;
  // Token from {"scope":"images","deadline":"4070880000000","returnBody":"bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)","overwrite":1,"fsizeLimit":0}
  blockRequest.uploadToken = kNormalTokan;
  
  [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"progressing : (%lld, %lld)", totalBytesSent, totalBytesExpectedToSend);
  }];
  
  XCTestExpectation *expection = [self expectationWithDescription:@"testNormal for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    if (task.error) {
      NSLog(@"error %@", task.error.localizedDescription);
    }
    XCTAssertNil(task.error);
    XCTAssert(task.result);
    WCSBlockUploadResult *blockUploadResult = task.result;
    XCTAssert(blockUploadResult.results);
    NSLog(@"results %@", blockUploadResult.results);
    
    [expection fulfill];
    return nil;
  }];
  
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testBlockSize {
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = @"file50m";
  blockRequest.fileURL = [NSURL URLWithString:[[self getDocumentDirectory] stringByAppendingPathComponent:@"file50m"]];
  blockRequest.blockSize = 8 * 1024 * 1024;
  blockRequest.chunkSize = 64 * 1024;
  // Token from {"scope":"images","deadline":"4070880000000","returnBody":"bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)","overwrite":1,"fsizeLimit":0}
  blockRequest.uploadToken = kNormalTokan;
  
  XCTestExpectation *expection = [self expectationWithDescription:@"testNormal for WCSBlockUploadRequest"];
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    if (task.error) {
      NSLog(@"error %@", task.error.localizedDescription);
    }
    XCTAssertNil(task.error);
    XCTAssert(task.result);
    WCSBlockUploadResult *blockUploadResult = task.result;
    XCTAssert(blockUploadResult.results);
    NSLog(@"results %@", blockUploadResult.results);
    
    [expection fulfill];
    return nil;
  }];
  
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)initialFiles {
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

- (NSString *)getDocumentDirectory {
  NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString * documentsDirectory = [paths objectAtIndex:0];
  return documentsDirectory;
}

@end
