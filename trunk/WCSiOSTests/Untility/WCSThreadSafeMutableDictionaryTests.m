//
//  WCSThreadSafeMutableDictionaryTests.m
//  WCSiOS
//
//  Created by mato on 16/3/24.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WCSThreadSafeMutableDictionary.h"

@interface WCSThreadSafeMutableDictionaryTests : XCTestCase

@property (nonatomic, strong) WCSThreadSafeMutableDictionary *threadSafeMutableDictionary;

@end

@implementation WCSThreadSafeMutableDictionaryTests

- (void)setUp {
  [super setUp];
  self.threadSafeMutableDictionary = [[WCSThreadSafeMutableDictionary alloc] init];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testSetObject {
  WCSThreadSafeMutableDictionary *threadSafeMutableDictionary = [[WCSThreadSafeMutableDictionary alloc] init];
  [threadSafeMutableDictionary setObject:@"object" forKey:@"key"];
  XCTAssert([[threadSafeMutableDictionary objectForKey:@"key"] isEqualToString:@"object"]);
}

- (void)testInitWithObjects {
  WCSThreadSafeMutableDictionary *threadSafeMutableDictionary = [[WCSThreadSafeMutableDictionary alloc] initWithObjects:@[@"1", @"2"] forKeys:@[@"key1", @"key2"]];
  XCTAssert([[threadSafeMutableDictionary objectForKey:@"key1"] isEqualToString:@"1"]);
}

- (void)testPerformanceExample {
  [self measureBlock:^{
  }];
}

@end
