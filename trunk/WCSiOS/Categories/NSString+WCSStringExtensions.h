//
//  NSString+WCSStringExtensions.h
//  WCS
//
//  Created by mato on 14-8-20.
//  Copyright (c) 2014年 DFP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (WCSStringExtensions)

- (BOOL)isEmpty;
- (NSString *)escapeHTML;
- (NSString *)stringByEscapingForURLArgument;
- (NSString *) stringByStrippingHTML;

@end
