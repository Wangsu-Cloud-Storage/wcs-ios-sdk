//
//  WCSBatchUploadTests.m
//  WCSiOS
//
//  Created by mato on 16/4/13.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WCSClient.h"

#define RESOURCE_PATH [[NSBundle bundleForClass:[self class]] resourcePath]

@interface WCSBatchUploadTests : XCTestCase

@end

@implementation WCSBatchUploadTests

- (void)setUp {
  [super setUp];
  [WCSLogger defaultLogger].logLevel = WCSLogLevelVerbose;
}

- (void)tearDown {
  [super tearDown];
}

@end
