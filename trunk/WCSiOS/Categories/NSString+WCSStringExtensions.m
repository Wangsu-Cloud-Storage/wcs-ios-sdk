//
//  NSString+WCSStringExtensions.m
//  WCS
//
//  Created by mato on 14-8-20.
//  Copyright (c) 2014年 DFP. All rights reserved.
//

#import "NSString+WCSStringExtensions.h"

@implementation NSString (WCSStringExtensions)

- (BOOL)isEmpty {
	NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSString *trimmed = [self stringByTrimmingCharactersInSet:charSet];
	return [trimmed isEqualToString:@""];
}

- (NSString *)escapeHTML {
	NSMutableString *result = [[NSMutableString alloc] initWithString:self];
	[result replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@"'" withString:@"&#39;" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	return result;
}

// Taken from https://gist.github.com/1256354
- (NSString *)stringByEscapingForURLArgument {
	// Encode all the reserved characters, per RFC 3986 (<http://www.ietf.org/rfc/rfc3986.txt>)
	NSString *escapedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                    (CFStringRef)self,
                                                                                                    NULL,
                                                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[] ",
                                                                                                    kCFStringEncodingUTF8));
	return escapedString;
}

-(NSString *) stringByStrippingHTML {
    NSRange r;
    NSString *s = [self copy] ;
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

@end
