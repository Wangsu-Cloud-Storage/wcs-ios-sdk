//
//  WCSUploadObjectResultTest.m
//  WCSiOS
//
//  Created by wangwayhome on 2017/5/9.
//  Copyright © 2017年 CNC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WCSUploadObjectResult.h"

@interface WCSUploadObjectResultTest : XCTestCase

@end

@implementation WCSUploadObjectResultTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testResultRsp {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  NSData * data = [[NSData alloc]init];
  NSDictionary *headDic = [[NSDictionary alloc]init];
  NSHTTPURLResponse * rsp = [[NSHTTPURLResponse alloc]initWithURL:[NSURL URLWithString:@"11"] statusCode:100 HTTPVersion:@"1.1" headerFields:headDic];
  NSError  *error;

  WCSUploadObjectResult *result = [[WCSUploadObjectResult alloc]initWithResponseData:data HTTPResponse:rsp error:&error];
  
  XCTAssert([error.userInfo  isEqualToDictionary:@{WCSErrorKey : @"Decode as JSON failed."}]);
  XCTAssert(result);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
