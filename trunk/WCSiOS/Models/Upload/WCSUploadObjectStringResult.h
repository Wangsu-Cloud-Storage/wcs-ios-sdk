//
//  WCSUploadObjectStringResult.h
//  TestWCSiOS
//
//  Created by mato on 2016/11/17.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSUploadObjectStringResult : WCSModel<WCSResponseModelSerializer>

@property (nonatomic, copy) NSString *resultString;

@end
