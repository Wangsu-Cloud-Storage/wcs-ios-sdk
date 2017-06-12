/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "WCSCancellationTokenRegistration.h"

#import "WCSCancellationToken.h"

@interface WCSCancellationTokenRegistration ()

@property (nonatomic, weak) WCSCancellationToken *token;
@property (nonatomic, strong) WCSCancellationBlock cancellationObserverBlock;
@property (nonatomic, strong) NSObject *lock;
@property (nonatomic) BOOL disposed;

@end

@interface WCSCancellationToken (WCSCancellationTokenRegistration)

- (void)unregisterRegistration:(WCSCancellationTokenRegistration *)registration;

@end

@implementation WCSCancellationTokenRegistration

+ (instancetype)registrationWithToken:(WCSCancellationToken *)token delegate:(WCSCancellationBlock)delegate {
    WCSCancellationTokenRegistration *registration = [WCSCancellationTokenRegistration new];
    registration.token = token;
    registration.cancellationObserverBlock = delegate;
    return registration;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _lock = [NSObject new];
    
    return self;
}

- (void)dispose {
    @synchronized(self.lock) {
        if (self.disposed) {
            return;
        }
        self.disposed = YES;
    }

    WCSCancellationToken *token = self.token;
    if (token != nil) {
        [token unregisterRegistration:self];
        self.token = nil;
    }
    self.cancellationObserverBlock = nil;
}

- (void)notifyDelegate {
    @synchronized(self.lock) {
        [self throwIfDisposed];
        self.cancellationObserverBlock();
    }
}

- (void)throwIfDisposed {
    NSAssert(!self.disposed, @"Object already disposed");
}

@end
