/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "WCSBoltsVersion.h"
#import "WCSCancellationToken.h"
#import "WCSCancellationTokenRegistration.h"
#import "WCSCancellationTokenSource.h"
#import "WCSExecutor.h"
#import "WCSTask.h"
#import "WCSTaskCompletionSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WCSBolts : NSObject

/*!
 Returns the version of the Bolts Framework as an NSString.
 @returns The NSString representation of the current version.
 */
+ (NSString *)version;

@end

NS_ASSUME_NONNULL_END
