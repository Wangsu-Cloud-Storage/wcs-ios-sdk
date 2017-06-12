//
//  WCSApiTests.m
//  WCSiOS
//
//  Created by mato on 16/5/6.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WCSApi.h"
#import "WCSLogging.h"

#define RESOURCE_PATH [[NSBundle bundleForClass:[self class]] resourcePath]

@interface WCSApiTests : XCTestCase

@end

@implementation WCSApiTests

- (void)setUp {
  [super setUp];
  [WCSLogger defaultLogger].logLevel = WCSLogLevelVerbose;
}

- (void)tearDown {
  [super tearDown];
}

- (void)testConfigureBaseURL {
  NSString *token = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YjJhZTgwYTQxNmRkZTZhMWYxNTAyMTJhZmQ4Y2QzOTgzOGJlMGU0MQ==:eyJzY29wZSI6ImltYWdlczp0ZXN0MSIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpJnRlc3Q9JCh4OnRlc3QpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"image.gif"]];

  XCTestExpectation *expectation = [self expectationWithDescription:@"testConfigureBaseURL"];
  [WCSApi uploadFileWithUploadToken:token fileData:fileData fileNamed:@"image.gif" fileMimeType:@"image/gif" taskTag:0 callbackBody:nil usingSuccessBlock:^(NSInteger statusCode, NSDictionary *response) {
    [expectation fulfill];
  } progressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    NSLog(@"progressing %@ %@ %@", @(bytesWritten), @(totalBytesWritten), @(totalBytesExpectedToWrite));
  } failuredBlock:^(NSInteger statusCode, NSDictionary *errorMsg) {
    XCTAssert(NO);
    NSLog(@"status code %zd message %@", statusCode, errorMsg);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testCancelRequest {
  NSString *token = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YjJhZTgwYTQxNmRkZTZhMWYxNTAyMTJhZmQ4Y2QzOTgzOGJlMGU0MQ==:eyJzY29wZSI6ImltYWdlczp0ZXN0MSIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpJnRlc3Q9JCh4OnRlc3QpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"image.gif"]];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testConfigureBaseURL"];
  [WCSApi uploadFileWithUploadToken:token fileData:fileData fileNamed:@"image.gif" fileMimeType:@"image/gif" taskTag:10080 callbackBody:nil usingSuccessBlock:^(NSInteger statusCode, NSDictionary *response) {
    XCTAssert(NO);
    [expectation fulfill];
  } progressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    NSLog(@"progressing %@ %@", @(totalBytesWritten), @(totalBytesExpectedToWrite));
  } failuredBlock:^(NSInteger statusCode, NSDictionary *errorMsg) {
    NSLog(@"status code %zd message %@", statusCode, errorMsg);
    [expectation fulfill];
  }];
  [NSThread sleepForTimeInterval:0.1];
  [WCSApi cancelUploadingOperationInTag:10080];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testChunkUpload {
  NSString *fileURLString = [RESOURCE_PATH stringByAppendingPathComponent:@"oschina"];
  // Token from {"scope":"images:oschina3221","deadline":"4070880000000","overwrite":1,"fsizeLimit":0}
  NSString *uploadToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:MjU4NWFkMTk2ZDViNmQ3NjZmNzI3M2U3ZmEwYTg2YzAwYzJiZTAwMg==:eyJzY29wZSI6ImltYWdlczpvc2NoaW5hMzIyMSIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsIm92ZXJ3cml0ZSI6MSwiZnNpemVMaW1pdCI6MH0=";

  XCTestExpectation *expectation = [self expectationWithDescription:@"testChunkUpload for WCSApi"];
  [WCSApi sliceUploadFile:fileURLString token:uploadToken taskTag:0 callbackBody:nil progressBlock:^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    NSLog(@"%@ %@", @(totalBytesWritten), @(totalBytesExpectedToWrite));
  } successBlock:^(NSDictionary *responseDict) {
    [expectation fulfill];
  } failuredBlock:^(NSDictionary *errorMsg) {
    XCTAssert(NO);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testCancelChunkUpload {
  NSString *fileURLString = [RESOURCE_PATH stringByAppendingPathComponent:@"oschina"];
  // Token from {"scope":"images:oschina3221","deadline":"4070880000000","overwrite":1,"fsizeLimit":0}
  NSString *uploadToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:MjU4NWFkMTk2ZDViNmQ3NjZmNzI3M2U3ZmEwYTg2YzAwYzJiZTAwMg==:eyJzY29wZSI6ImltYWdlczpvc2NoaW5hMzIyMSIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsIm92ZXJ3cml0ZSI6MSwiZnNpemVMaW1pdCI6MH0=";
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testChunkUpload for WCSApi"];
  [WCSApi sliceUploadFile:fileURLString token:uploadToken taskTag:10080 callbackBody:nil progressBlock:^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    NSLog(@"%@ %@", @(totalBytesWritten), @(totalBytesExpectedToWrite));
  } successBlock:^(NSDictionary *responseDict) {
    XCTAssert(NO);
    [expectation fulfill];
  } failuredBlock:^(NSDictionary *errorMsg) {
    [expectation fulfill];
  }];
  [NSThread sleepForTimeInterval:0.5];
  [WCSApi cancelUploadingOperationInTag:10080];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

@end
