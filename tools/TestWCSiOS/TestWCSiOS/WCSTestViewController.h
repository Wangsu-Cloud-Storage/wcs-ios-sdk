//
//  WCSTestViewController.h
//  TestWCSiOS
//
//  Created by wangwayhome on 2017/5/11.
//  Copyright © 2017年 CNC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WCSTestViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *tokenTextField;
@property (strong, nonatomic) IBOutlet UITextField *keyTextField;
@property (strong, nonatomic) IBOutlet UITextField *fileNameTextField;
@property (strong, nonatomic) IBOutlet UITextField *mimeTypeTextField;
@property (strong, nonatomic) IBOutlet UITextField *chunkTextField;
@property (strong, nonatomic) IBOutlet UITextField *blockTextField;
@property (strong, nonatomic) IBOutlet UITextField *baseUrlTextField;
@property (strong, nonatomic) IBOutlet UITextView *log;
- (IBAction)testUpload:(id)sender;
- (IBAction)chunkUpload:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)testUploadRaw:(id)sender;
- (IBAction)chunkUploadRaw:(id)sender;
@end
