//
//  WCSManagerTests.m
//  WCSiOS
//
//  Created by mato on 16/5/3.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WCSClient.h"

@interface WCSManagerTests : XCTestCase

@property (nonatomic, strong) WCSClient *client;

@end

@implementation WCSManagerTests

- (void)setUp {
  [super setUp];
  self.client = [[WCSClient alloc] initWithTimeout:30];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testFileStat {
  WCSFileStatRequest *fileStatRequest = [[WCSFileStatRequest alloc] init];
  fileStatRequest.fileKey = @"test333";
  fileStatRequest.bucket = @"images";
  fileStatRequest.accessToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:MjkxNTg5YjUzYmM0Mzc1YzBiMGI3NzI3YWYxYmRlZmJjODRmYWUzMQ==";
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testFileStat"];
  [[self.client fileStat:fileStatRequest] continueWithBlock:^id _Nullable(WCSTask<WCSFileStatResult *> * _Nonnull task) {
    XCTAssertNil(task.error, @"unexpected error %@", task.error);
    XCTAssert(task.result);
    WCSFileStatResult *statResult = task.result;
    XCTAssert(statResult.fileHash);
    XCTAssert(statResult.fileSize > 0);
    XCTAssert(statResult.successful);
    
    [expectation fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testDeleteFile {
  WCSDeleteFileRequest *deleteFileRequest = [[WCSDeleteFileRequest alloc] init];
  deleteFileRequest.bucket = @"images";
  deleteFileRequest.fileKey = @"exif.jpg";
  deleteFileRequest.accessToken = @"86622e227a50d49d858c2494a935bc2e4ac543a7:NGRhMGQxMjBlNDc2OGZiZGQ5YjE1ZTY1ZjA0MzU4ZjUyOGFlY2YxYg==";
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testDeleteFile"];
  [[self.client deleteFile:deleteFileRequest] continueWithBlock:^id _Nullable(WCSTask<WCSDeleteFileResult *> * _Nonnull task) {
    XCTAssertNil(task.error, @"unexpected error %@", task.error);
    [expectation fulfill];
    return nil;
  }];
  [self waitForExpectationsWithTimeout:60 handler:nil];
}

@end
