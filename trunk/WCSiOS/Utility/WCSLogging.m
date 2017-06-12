//
// Copyright 2010-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import "WCSLogging.h"

@implementation WCSLogger

- (instancetype)init {
    if (self = [super init]) {
        _logLevel = WCSLogLevelNone;
    }

    return self;
}

+ (instancetype)defaultLogger {
    static WCSLogger *_defaultLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultLogger = [WCSLogger new];
        _defaultLogger.logLevel = WCSLogLevelError; //set default logLevel
    });

    return _defaultLogger;
}

- (void)log:(WCSLogLevel)logLevel format:(NSString *)fmt, ... NS_FORMAT_FUNCTION(2, 3) {
    if(self.logLevel >= logLevel) {
        va_list args;
        va_start(args, fmt);
        NSLog(@"WCSiOSSDKv2 [%@] %@", [self logLevelLabel:logLevel], [[NSString alloc] initWithFormat:fmt arguments:args]);
        va_end(args);
    }
}

- (NSString *)logLevelLabel:(WCSLogLevel)logLevel {
    switch (logLevel) {
        case WCSLogLevelError:
            return @"Error";

        case WCSLogLevelWarn:
            return @"Warn";

        case WCSLogLevelInfo:
            return @"Info";

        case WCSLogLevelDebug:
            return @"Debug";

        case WCSLogLevelVerbose:
            return @"Verbose";

        case WCSLogLevelUnknown:
        case WCSLogLevelNone:
        default:
            return @"?";
    }
}

@end
