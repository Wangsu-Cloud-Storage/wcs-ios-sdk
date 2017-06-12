/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "WCSCancellationTokenSource.h"

#import "WCSCancellationToken.h"

@interface WCSCancellationToken (WCSCancellationTokenSource)

- (void)cancel;
- (void)cancelAfterDelay:(int)millis;

- (void)dispose;
- (void)throwIfDisposed;

@end

@implementation WCSCancellationTokenSource

#pragma mark - Initializer

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _token = [WCSCancellationToken new];

    return self;
}

+ (instancetype)cancellationTokenSource {
    return [WCSCancellationTokenSource new];
}

#pragma mark - Custom Setters/Getters

- (BOOL)isCancellationRequested {
    return _token.isCancellationRequested;
}

- (void)cancel {
    [_token cancel];
}

- (void)cancelAfterDelay:(int)millis {
    [_token cancelAfterDelay:millis];
}

- (void)dispose {
    [_token dispose];
}

@end
