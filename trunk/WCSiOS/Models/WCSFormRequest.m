//
//  WCSFormRequest.m
//  WCSiOS
//
//  Created by mato on 16/4/7.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSFormRequest.h"
#import <MobileCoreServices/MobileCoreServices.h>

static NSString * WCSContentTypeForPathExtension(NSString *extension) {
  NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
  NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
  if (!contentType) {
    return @"application/octet-stream";
  } else {
    return contentType;
  }
}

@interface WCSFormRequest()

@property (nonatomic, strong) NSMutableArray *postDataArray;
@property (nonatomic, strong) NSMutableArray *fileDataArray;
@property (nonatomic, strong) NSError *error;

@end

@implementation WCSFormRequest

+ (NSString *)createMultipartFormBoundary {
  return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

- (void)addPostValue:(NSString *)postValue forKey:(NSString *)key {
  if (!key) {
    return;
  }
  if (!self.postDataArray) {
    self.postDataArray = [NSMutableArray array];
  }
  NSMutableDictionary *keyValuePair = [NSMutableDictionary dictionaryWithCapacity:2];
  [keyValuePair setValue:key forKey:@"key"];
  [keyValuePair setValue:[postValue description] forKey:@"value"];
  [self.postDataArray addObject:keyValuePair];
}

- (void)addFileData:(NSData *)fileData fileName:(NSString *)fileName {
  [self addFileData:fileData fileName:fileName mimeType:nil];
}

- (void)addFileData:(NSData *)fileData fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
  [self innerAddFileData:fileData fileName:fileName mimeType:mimeType];
}

- (void)addFileURL:(NSURL *)fileURL {
  [self addFileURL:fileURL fileName:nil];
}

- (void)addFileURL:(NSURL *)fileURL fileName:(NSString *)fileName {
  [self addFileURL:fileURL fileName:fileName mimeType:nil];
}

- (void)addFileURL:(NSURL *)fileURL fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
  BOOL isDirectory = NO;
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileURL.absoluteString isDirectory:&isDirectory];
  
  if (!fileExists || isDirectory) {
    // TODO:ERROR
    WCSLogError("file %@ invalidate", fileURL);
    return;
  }
  
  if (!fileName) {
    fileName = [fileURL.absoluteString lastPathComponent];
  }
  
  if (!mimeType) {
    mimeType = WCSContentTypeForPathExtension(fileURL.pathExtension);
  }
  [self innerAddFileData:fileURL fileName:fileName mimeType:mimeType];
}

#pragma mark - WCSRequestModelSerializer
- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
  return [super constructSessionTaskUsingSession:session baseURL:baseURL];
}

- (void)resetData {
  if (self.postDataArray) {
    [self.postDataArray removeAllObjects];
  }
  if (self.fileDataArray) {
    [self.fileDataArray removeAllObjects];
  }
  _error = nil;
}

#pragma mark - Private Methods
- (NSMutableData *)buildMultipartFormDataPostBodyUsingBoundary:(NSString *)boundary {
  NSMutableData *data = [NSMutableData data];
  [data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  NSData *endItemBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
  
  // Post Values
  NSUInteger i=0;
  for (NSDictionary *val in [self postDataArray]) {
    [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [val objectForKey:@"key"]] dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:[[val objectForKey:@"value"] dataUsingEncoding:NSUTF8StringEncoding]];
    i++;
    if (i != self.postDataArray.count || self.fileDataArray.count > 0) { //Only add the boundary if this is not the last item in the post body
      [data appendData:endItemBoundary];
    }
  }
  
  // Post Files
  i=0;
  for (NSDictionary *val in self.fileDataArray) {
    
    //mimeType跟filename不是兄弟关系 是叔侄关系 所以要单列一段
    NSString *mimeType = [val objectForKey:@"contentType"];
    if (mimeType != nil) {
      [data appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"mimeType\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
      [data appendData:[mimeType dataUsingEncoding:NSUTF8StringEncoding]];
      [data appendData:endItemBoundary];
    }
    
    NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", WCSFormUploadFile, [val objectForKey:@"fileName"]];
//    NSString *contentType = [NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [val objectForKey:@"contentType"]];
    NSString *contentType = [NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"];
    
    [data appendData:[disposition dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:[contentType dataUsingEncoding:NSUTF8StringEncoding]];
    
    id fileData = [val objectForKey:@"data"];
    if ([fileData isKindOfClass:[NSURL class]]) {
      NSURL *fileURL = fileData;
      [data appendData:[[NSFileManager defaultManager] contentsAtPath:fileURL.absoluteString]];
    } else {
      [data appendData:fileData];
    }
    i++;
    // Only add the boundary if this is not the last item in the post body
    if (i != self.fileDataArray.count) {
      [data appendData:endItemBoundary];
    }
  }
  
  [data appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  return data;
}

- (void)innerAddFileData:(id)fileData fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
  if (!self.fileDataArray) {
    self.fileDataArray = [NSMutableArray array];
  }
  if (!mimeType) {
    mimeType = @"application/octet-stream";
  }
  
  NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithCapacity:4];
  [fileInfo setValue:fileName forKey:@"fileName"];
  [fileInfo setValue:mimeType forKey:@"contentType"];
  [fileInfo setValue:fileData forKey:@"data"];
  [self.fileDataArray addObject:fileInfo];
}

@end
