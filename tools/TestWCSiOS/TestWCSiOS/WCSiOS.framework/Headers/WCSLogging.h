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

#import <Foundation/Foundation.h>


#define WCSLogFormat @"%@ line:%d | %s | "

#define WCSLogError(fmt, ...)    [[WCSLogger defaultLogger] log:WCSLogLevelError format:(WCSLogFormat fmt), [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]
#define WCSLogWarn(fmt, ...)    [[WCSLogger defaultLogger] log:WCSLogLevelWarn format:(WCSLogFormat fmt), [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]
#define WCSLogInfo(fmt, ...)    [[WCSLogger defaultLogger] log:WCSLogLevelInfo format:(WCSLogFormat fmt), [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]
#define WCSLogDebug(fmt, ...)    [[WCSLogger defaultLogger] log:WCSLogLevelDebug format:(WCSLogFormat fmt), [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]
#define WCSLogVerbose(fmt, ...)    [[WCSLogger defaultLogger] log:WCSLogLevelVerbose format:(WCSLogFormat fmt), [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]


typedef NS_ENUM(NSInteger, WCSLogLevel) {
    WCSLogLevelUnknown = -1,
    WCSLogLevelNone = 0,
    WCSLogLevelError = 1,
    WCSLogLevelWarn = 2,
    WCSLogLevelInfo = 3,
    WCSLogLevelDebug = 4,
    WCSLogLevelVerbose = 5
};

/**
 WCSLogger is an utility class that handles logging to the console. Changing log levels during development may make debugging easier. You can change the log level by importing `WCSCore.h` and calling:

 *Swift*

     WCSLogger.defaultLogger().logLevel = .Verbose

 The following logging level options are available:

     .None
     .Error (This is the default. Only error logs are printed to the console.)
     .Warn
     .Info
     .Debug
     .Verbose

 *Objective-C*

     [WCSLogger defaultLogger].logLevel = WCSLogLevelVerbose;

 The following logging level options are available:

     WCSLogLevelNone
     WCSLogLevelError (This is the default. Only error logs are printed to the console.)
     WCSLogLevelWarn
     WCSLogLevelInfo
     WCSLogLevelDebug
     WCSLogLevelVerbose

 */
@interface WCSLogger : NSObject

/**
 The log level setting. The default is WCSLogLevelError.
 */
@property (atomic, assign) WCSLogLevel logLevel;

/**
 Returns the shared logger object.

 @return The shared logger object.
 */
+ (instancetype _Nonnull)defaultLogger;

/**
 Prints out the formatted logs to the console. You can use the following predefined shorthand methods instead:

     WCSLogError(fmt, ...)
     WCSLogWarn(fmt, ...)
     WCSLogInfo(fmt, ...)
     WCSLogDebug(fmt, ...)
     WCSLogVerbose(fmt, ...)

 @param logLevel The level of this log.
 @param fmt      The formatted string to log.
 */
- (void)log:(WCSLogLevel)logLevel
     format:(NSString * _Nonnull)fmt, ... NS_FORMAT_FUNCTION(2, 3);

@end
