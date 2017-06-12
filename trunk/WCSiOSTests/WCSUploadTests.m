//
//  WCSUploadTests.m
//  WCSiOS
//
//  Created by mato on 16/3/30.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WCSLogging.h"
#import "WCSClient.h"
#import "NSDictionary+WCSDictionarySafeExtensions.h"

#define RESOURCE_PATH [[NSBundle bundleForClass:[self class]] resourcePath]

@interface WCSUploadTests : XCTestCase

@property (nonatomic, strong) WCSClient *client;

@end

@implementation WCSUploadTests

- (void)setUp {
  [super setUp];
  [WCSLogger defaultLogger].logLevel = WCSLogLevelVerbose;
  self.client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testNormalUpload {
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  
  // TOKEN FOR TEST !!!
  // scope:images, overwrite:1, returnBody:bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key),
  request.token = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YzI1ZmQ3YmVjZmQ3ZGQzOGVkZDdiNGEyNzQ0MTNmY2U3YTk0MDk5NA==:eyJzY29wZSI6ImltYWdlcyIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  
  request.fileName = @"image.gif";
  request.key = @"testimage.gif";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"image.gif"]];
  request.fileData = fileData;
  request.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%lld bytes sent, %lld total bytes sent, %lld total byte exptected", bytesSent, totalBytesSent, totalBytesExpectedToSend);
  };
  
  XCTestExpectation *expection = [self expectationWithDescription:@"testest"];
  
  [[self.client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    if (task.error) {
      XCTAssertNil(task.error, @"The request failed. error: [%@]", task.error);
    } else {
      WCSUploadObjectResult *putResult = task.result;
      NSDictionary *responseResult = putResult.results;
      XCTAssert([@"testimage.gif" isEqualToString:[responseResult safeStringForKey:@"key"]]);
      XCTAssertNotNil([responseResult safeStringForKey:@"bucket"]);
      XCTAssertNotNil([responseResult safeStringForKey:@"fsize"]);
      XCTAssertNotNil([responseResult safeStringForKey:@"hash"]);
    }
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
    NSLog(@"finished.");
  }];
}

- (void)testCanceledRequest {
  // TOKEN FOR TEST !!!
  // scope:images:test1, overwrite:1, returnBody:bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)&test=$(x:test),
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.customParams = @{@"x:test" : @"customParams"};
  request.token = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YjJhZTgwYTQxNmRkZTZhMWYxNTAyMTJhZmQ4Y2QzOTgzOGJlMGU0MQ==:eyJzY29wZSI6ImltYWdlczp0ZXN0MSIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpJnRlc3Q9JCh4OnRlc3QpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  request.fileName = @"test1";
  request.key = @"test1";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"image.gif"]];
  request.fileData = fileData;
  request.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%lld bytes sent, %lld total bytes sent, %lld total byte exptected", bytesSent, totalBytesSent, totalBytesExpectedToSend);
  };
  XCTestExpectation *expection = [self expectationWithDescription:@"testest"];
  
  [[self.client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    XCTAssertTrue(task.error.code == NSURLErrorCancelled, @"Cancel failed %@", task.error);
    [expection fulfill];
    return nil;
  }];
  [NSThread sleepForTimeInterval:0.1];
  [request cancel];
  [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
    NSLog(@"finished.");
  }];
}

- (void)testCustomReturnBody {
  // TOKEN FOR TEST !!!
  // scope:images:test1, overwrite:1, returnBody:bucket=$(bucket)&fsize=$(fsize)&hash=$(hash)&key=$(key)&test=$(x:test),
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.customParams = @{@"x:test" : @"customParams"};
  request.token = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YjJhZTgwYTQxNmRkZTZhMWYxNTAyMTJhZmQ4Y2QzOTgzOGJlMGU0MQ==:eyJzY29wZSI6ImltYWdlczp0ZXN0MSIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpJnRlc3Q9JCh4OnRlc3QpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  request.fileName = @"test1";
  request.key = @"test1";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"LiveWallpapersPicker.apk"]];
  request.fileData = fileData;
  request.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSLog(@"%lld bytes sent, %lld total bytes sent, %lld total byte exptected", bytesSent, totalBytesSent, totalBytesExpectedToSend);
  };
  XCTestExpectation *expection = [self expectationWithDescription:@"testest"];
  
  [[self.client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    if (task.error) {
      XCTAssertNil(task.error, @"The request failed. error: [%@]", task.error);
    } else {
      WCSUploadObjectResult *putResult = task.result;
      XCTAssert([@"customParams" isEqualToString:[putResult.results safeStringForKey:@"test"]]);
    }
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
    NSLog(@"finished.");
  }];
}

- (void)testInvalidateToken {
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.token = @"fjkdslajfkldsjkflsd";
  request.fileName = @"test1";
  request.key = @"test1";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"LiveWallpapersPicker.apk"]];
  request.fileData = fileData;
  XCTestExpectation *expection = [self expectationWithDescription:@"testest"];
  [[self.client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    NSLog(@"Test invalidate token error [%@]", task.error);
    XCTAssert(task.error);
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
    NSLog(@"finished.");
  }];
}

- (void)testNilToken {
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.token = @"";
  request.fileName = @"test1";
  request.key = @"test1";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"LiveWallpapersPicker.apk"]];
  request.fileData = fileData;
  XCTestExpectation *expection = [self expectationWithDescription:@"testest"];
  [[self.client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    NSLog(@"Test nil token error [%@]", task.error);
    XCTAssert(task.error);
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
    NSLog(@"finished.");
  }];
}

- (void)testNilFileName {
  WCSUploadObjectRequest *request = [[WCSUploadObjectRequest alloc] init];
  request.token = @"86622e227a50d49d858c2494a935bc2e4ac543a7:YjJhZTgwYTQxNmRkZTZhMWYxNTAyMTJhZmQ4Y2QzOTgzOGJlMGU0MQ==:eyJzY29wZSI6ImltYWdlczp0ZXN0MSIsImRlYWRsaW5lIjoiNDA3MDg4MDAwMDAwMCIsInJldHVybkJvZHkiOiJidWNrZXQ9JChidWNrZXQpJmZzaXplPSQoZnNpemUpJmhhc2g9JChoYXNoKSZrZXk9JChrZXkpJnRlc3Q9JCh4OnRlc3QpIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
  request.key = @"test1";
  NSData* fileData = [[NSFileManager defaultManager] contentsAtPath:[RESOURCE_PATH stringByAppendingPathComponent:@"LiveWallpapersPicker.apk"]];
  request.fileData = fileData;
  XCTestExpectation *expection = [self expectationWithDescription:@"testest"];
  [[self.client uploadRequest:request] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    NSLog(@"Test nil fileName error [%@]", task.error);
    XCTAssert(task.error);
    [expection fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
    NSLog(@"finished.");
  }];
}

@end
