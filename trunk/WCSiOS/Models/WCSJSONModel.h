//
//  WCSJSONModel.h
//  WCSiOS
//
//  Created by mato on 16/5/3.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"
#import "NSDictionary+WCSDictionarySafeExtensions.h"

@interface WCSJSONModel : WCSModel<WCSResponseModelSerializer>

- (instancetype)initWithJSONData:(NSDictionary *)JSONData HTTPResponse:(NSHTTPURLResponse *)response error:(NSError **)error;

@end
