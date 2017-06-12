//
//  WCSCommonAlgorithm.m
//  WCSiOS
//
//  Created by mato on 16/4/28.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSCommonAlgorithm.h"
#import "CommonCrypto/CommonDigest.h"
#import "CommonCrypto/CommonHMAC.h"
#import "WCSGTMStringEncoding.h"

static const NSUInteger kChunkSize = 256 * 1024;

@implementation WCSCommonAlgorithm

+ (unsigned char *)MD5AtFilePath:(NSString *)filePath {
  NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
  if(handle == nil) {
    return nil;
  }
  CC_MD5_CTX md5;
  CC_MD5_Init(&md5);
  BOOL done = NO;
  while(!done) {
    NSData* fileData = [handle readDataOfLength:kChunkSize];
    CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
    if([fileData length] == 0) {
      done = YES;
    }
  }
  unsigned char * digestResult = (unsigned char *)malloc(CC_MD5_DIGEST_LENGTH * sizeof(unsigned char));
  CC_MD5_Final(digestResult, &md5);
  return digestResult;
}

+ (NSString *)MD5StringAtFilePath:(NSString *)filePath {
  unsigned char * MD5Char = [self MD5AtFilePath:filePath];
//  NSString *md5String = nil;
//  if (MD5Char) {
//    md5String = [self convertMD5Bytes2String:MD5Char];
//  }
  free(MD5Char);
  return nil;
}

+ (NSString *)MD5StringFromString:(NSString *)originalString {
  NSData *dataString = [originalString dataUsingEncoding:NSUTF8StringEncoding];
  unsigned char digestArray[CC_MD5_DIGEST_LENGTH];
  CC_MD5([dataString bytes], (CC_LONG)[dataString length], digestArray);
  
  NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [md5String appendFormat:@"%02x", digestArray[i]];
  }
  return md5String;
}

+ (NSString *)webSafeBase64EncodedString:(NSString *)string {
  return [[WCSGTMStringEncoding rfc4648Base64WebsafeStringEncoding] encodeString:string];
}

+ (NSString *)base64EncodedString:(NSString *)string {
  return [[WCSGTMStringEncoding rfc4648Base64StringEncoding] encodeString:string];
}

+ (NSString *)convertMD5Bytes2String:(unsigned char *)md5Bytes {
  return [NSString stringWithFormat:
          @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
          md5Bytes[0], md5Bytes[1], md5Bytes[2], md5Bytes[3],
          md5Bytes[4], md5Bytes[5], md5Bytes[6], md5Bytes[7],
          md5Bytes[8], md5Bytes[9], md5Bytes[10], md5Bytes[11],
          md5Bytes[12], md5Bytes[13], md5Bytes[14], md5Bytes[15]
          ];
}

@end
