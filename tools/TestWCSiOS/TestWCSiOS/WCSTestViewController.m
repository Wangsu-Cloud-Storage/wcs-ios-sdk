//
//  WCSTestViewController.m
//  TestWCSiOS
//
//  Created by wangwayhome on 2017/5/11.
//  Copyright © 2017年 CNC. All rights reserved.
//  测试Demo

#import "WCSTestViewController.h"
#import "SVProgressHUD.h"
#import <WCSiOS/WCSClient.h>
static NSString * const kNokeyToken = @"";

@interface WCSTestViewController ()<UIPickerViewDataSource, UIPickerViewDelegate,UITextFieldDelegate>
@property (strong, nonatomic) WCSClient *client;
@property (strong, nonatomic) NSArray *pickerData;
@property (strong, nonatomic) NSArray *fileSizeArray;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) IBOutlet UITextField *fileField;
@property (strong, nonatomic) NSURL *fileURL;
@property (weak, nonatomic)   WCSRequest *req;
@property (strong, nonatomic) NSMutableString *logStr;//log显示

@end

@implementation WCSTestViewController
#pragma mark - 文件操作
- (NSString *)getDocumentDirectory {
  NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString * documentsDirectory = [paths objectAtIndex:0];
  return documentsDirectory;
}

-(NSArray *)getFilenamelist{
  NSMutableArray *filenamelist = [NSMutableArray arrayWithCapacity:10];
  NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self getDocumentDirectory] error:nil];
  
  for (NSString *filename in tmplist) {
    NSString *fullpath = [[self getDocumentDirectory] stringByAppendingPathComponent:filename];
    if ([self isFileExistAtPath:fullpath]) {
      [filenamelist  addObject:filename];
    }
  }
  
  return filenamelist;
}

-(BOOL)isFileExistAtPath:(NSString*)fileFullPath {
  BOOL isExist = NO;
  isExist = [[NSFileManager defaultManager] fileExistsAtPath:fileFullPath];
  return isExist;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  _logStr = [[NSMutableString alloc]init];
  _pickerData = @[@"file100k",@"file200k",@"file500k",@"file1m",@"file4m",@"file10m",@"file50m",@"file100m",@"file500m",@"file1G"];
  _tokenTextField.text = kNokeyToken;
  self.fileSizeArray = @[@102400, @204800, @512000, @1048576, @4194304,@10485760, @52428800, @104857600 ,@524288000,@1073741824];
  self.client = [[WCSClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://apitestuser.up0.v1.wcsapi.com"] andTimeout:30];
  //  生成选择文件列表
  _picker.showsSelectionIndicator = YES;
  [_picker removeFromSuperview];
  UIToolbar *toolBar= [[UIToolbar alloc] init];
  [toolBar sizeToFit];
  [toolBar setBarStyle:UIBarStyleBlackOpaque];
  UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(changeDateFromLabel:)];
  toolBar.items = @[barButtonDone];
  barButtonDone.tintColor=[UIColor blackColor];
  toolBar.translucent = YES;
  toolBar.userInteractionEnabled = YES;
  _fileField.inputView = _picker;
  _fileField.inputAccessoryView = toolBar;
  
  
}

-(void)changeDateFromLabel:(id)sender
{
  [_fileField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
  return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
  return [[self getFilenamelist] count];
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
  return [self getFilenamelist][row];
}

// Catpure the picker view selection
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
  NSString *selectFileName = [NSString stringWithFormat:@"%@",[self getFilenamelist][row]];
  NSLog(@"选中：%@",selectFileName);
  _fileField.text = selectFileName;
  _fileNameTextField.text = selectFileName;
  _keyTextField.text = selectFileName;
  self.fileURL = [NSURL URLWithString:[[self getDocumentDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",selectFileName]]];
}

/**
 初始化文件
 
 @param sender button
 */
- (IBAction)initialFiles:(UIButton *)sender {
  [SVProgressHUD showWithStatus:@"正在生成文件,请稍后!"];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0 ), ^{
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * mainDir = [self getDocumentDirectory];
    
    
    for (int i = 0; i < [self.pickerData count]; i++) {
      NSMutableData * basePart = [NSMutableData dataWithCapacity:1024];
      for (int j = 0; j < 1024/4; j++) {
        u_int32_t randomBit = j;// arc4random();
        [basePart appendBytes:(void*)&randomBit length:4];
      }
      NSString * name = [self.pickerData objectAtIndex:i];
      long size = [[self.fileSizeArray objectAtIndex:i] longValue];
      NSString * newFilePath = [mainDir stringByAppendingPathComponent:name];
      if ([fm fileExistsAtPath:newFilePath]) {
        NSLog(@"file exists %@", newFilePath);
        continue;
      }
      [fm createFileAtPath:newFilePath contents:nil attributes:nil];
      NSFileHandle * f = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
      for (int k = 0; k < size/1024; k++) {
        [f writeData:basePart];
      }
      [f closeFile];
      NSLog(@"initial file : %@", newFilePath);
    }
    NSLog(@"initial file DONE.");
    dispatch_async(dispatch_get_main_queue(), ^{
      [SVProgressHUD dismiss];
    });
  });
}
#pragma mark - 按钮事件
/**
 普通上传事件
 
 @param sender button
 */
- (IBAction)testUpload:(id)sender {
  [_logStr setString:@""];
  WCSUploadObjectRequest *uploadRequest = [[WCSUploadObjectRequest alloc] init];
  uploadRequest.token = _tokenTextField.text;
  uploadRequest.key = _keyTextField.text;
  uploadRequest.fileName = _fileNameTextField.text;
  uploadRequest.fileURL = _fileURL;
  if (_mimeTypeTextField.text.length >0) {
    uploadRequest.mimeType = _mimeTypeTextField.text;
  }
  [SVProgressHUD show];
  _req = uploadRequest;
  
  [uploadRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSString *str =[NSString stringWithFormat:@"=== %@ %@\n", @(totalBytesSent), @(totalBytesExpectedToSend)];
    NSLog(@"%@",str);
    [_logStr appendString:str];
    dispatch_async(dispatch_get_main_queue(), ^{
      [SVProgressHUD showProgress:(float)totalBytesSent/totalBytesExpectedToSend];
      _log.text = _logStr;
      [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
    });
  }];
  
  [[self.client uploadRequest:uploadRequest] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
    if (task.error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        NSLog(@"error %@ %@", task.error.localizedDescription, task.error.userInfo);
        [_logStr appendString: [NSString stringWithFormat:@"error %@ %@", task.error.localizedDescription, task.error.userInfo]];
        _log.text = _logStr;
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [_logStr appendString: [NSString stringWithFormat:@"%@",task.result.results]];
        _log.text = _logStr;
        NSLog(@"results %@", task.result.results);
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
    }
    return nil;
  }];
}

/**
 返回格式为base64编码后的字符串
 普通上传

 @param sender button
 */
- (IBAction)testUploadRaw:(id)sender {
  [_logStr setString:@""];
  WCSUploadObjectRequest *uploadRequest = [[WCSUploadObjectRequest alloc] init];
  uploadRequest.token = _tokenTextField.text;
  uploadRequest.key = _keyTextField.text;
  uploadRequest.fileName = _fileNameTextField.text;
  uploadRequest.fileURL = _fileURL;
  if (_mimeTypeTextField.text.length >0) {
    uploadRequest.mimeType = _mimeTypeTextField.text;
  }
  [SVProgressHUD show];
  _req = uploadRequest;
  
  [uploadRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSString *str =[NSString stringWithFormat:@"=== %@ %@\n", @(totalBytesSent), @(totalBytesExpectedToSend)];
    NSLog(@"%@",str);
    [_logStr appendString:str];
    dispatch_async(dispatch_get_main_queue(), ^{
      [SVProgressHUD showProgress:(float)totalBytesSent/totalBytesExpectedToSend];
      _log.text = _logStr;
      [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
    });
  }];
  
  [[self.client uploadRequestRaw:uploadRequest] continueWithBlock:^id _Nullable(WCSTask<WCSUploadObjectStringResult *> * _Nonnull task) {
    if (task.error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        NSLog(@"error %@ %@", task.error.localizedDescription, task.error.userInfo);
        [_logStr appendString: [NSString stringWithFormat:@"error %@ %@", task.error.localizedDescription, task.error.userInfo]];
        _log.text = _logStr;
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [_logStr appendString: [NSString stringWithFormat:@"%@",task.result.resultString]];
        _log.text = _logStr;
        NSLog(@"results %@", task.result.resultString);
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
    }
    return nil;
  }];
}

/**
 分块上传
 
 @param sender button
 */
- (IBAction)chunkUpload:(id)sender {
  [_logStr setString:@""];
  [SVProgressHUD show];
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = _keyTextField.text;
  blockRequest.uploadToken = _tokenTextField.text;
  if (_mimeTypeTextField.text.length >0) {
    blockRequest.mimeType = _mimeTypeTextField.text;
  }
  blockRequest.fileURL = _fileURL ;
  if (_blockTextField.text.length >0){
    blockRequest.blockSize = [_blockTextField.text intValue]*1024*1024;
  }
  if (_chunkTextField.text.length >0){
    blockRequest.chunkSize = [_chunkTextField.text intValue]*1024;
  }
  _req = blockRequest;
  [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSString *str =[NSString stringWithFormat:@"=== %@ %@\n", @(totalBytesSent), @(totalBytesExpectedToSend)];
//    NSLog(@"%@",str);
    [_logStr appendString:str];
    dispatch_async(dispatch_get_main_queue(), ^{
      [SVProgressHUD showProgress:(float)totalBytesSent/totalBytesExpectedToSend];
      _log.text = _logStr;
      [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
    });
  }];
  
  [[self.client blockUploadRequest:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    if (task.error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        NSLog(@"error %@ %@", task.error.localizedDescription, task.error.userInfo);
        [_logStr appendString: [NSString stringWithFormat:@"error %@ %@", task.error.localizedDescription, task.error.userInfo]];
        _log.text = _logStr;
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
      
      
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [_logStr appendString: [NSString stringWithFormat:@"%@",task.result.results]];
        _log.text = _logStr;
        NSLog(@"results %@", task.result.results);
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
      
    }
    return nil;
  }];
}

/**
 分块上传
 未解析返回json

 @param sender butoon
 */
- (IBAction)chunkUploadRaw:(id)sender {
  [_logStr setString:@""];
  [SVProgressHUD show];
  WCSBlockUploadRequest *blockRequest = [[WCSBlockUploadRequest alloc] init];
  blockRequest.fileKey = _keyTextField.text;
  blockRequest.uploadToken = _tokenTextField.text;
  if (_mimeTypeTextField.text.length >0) {
    blockRequest.mimeType = _mimeTypeTextField.text;
  }
  blockRequest.fileURL = _fileURL ;
  if (_blockTextField.text.length >0){
    blockRequest.blockSize = [_blockTextField.text intValue]*1024*1024;
  }
  if (_chunkTextField.text.length >0){
    blockRequest.chunkSize = [_chunkTextField.text intValue]*1024;
  }
  _req = blockRequest;
  [blockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    NSString *str =[NSString stringWithFormat:@"=== %@ %@\n", @(totalBytesSent), @(totalBytesExpectedToSend)];
    //    NSLog(@"%@",str);
    [_logStr appendString:str];
    dispatch_async(dispatch_get_main_queue(), ^{
      [SVProgressHUD showProgress:(float)totalBytesSent/totalBytesExpectedToSend];
      _log.text = _logStr;
      [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
    });
  }];
  
  [[self.client blockUploadRequestRaw:blockRequest] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadBase64Result *> * _Nonnull task) {
    if (task.error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        NSLog(@"error %@ %@", task.error.localizedDescription, task.error.userInfo);
        [_logStr appendString: [NSString stringWithFormat:@"error %@ %@", task.error.localizedDescription, task.error.userInfo]];
        _log.text = _logStr;
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
      
      
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [_logStr appendString: [NSString stringWithFormat:@"%@",task.result.resultString]];
        _log.text = _logStr;
        NSLog(@"results %@", task.result.resultString);
        [_log scrollRangeToVisible:NSMakeRange(_log.text.length, 1)];//log自动显示最后一行
      });
      
    }
    return nil;
  }];
}
- (IBAction)cancel:(id)sender {
  [_req cancel];
}

#pragma mark - textField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField{
  if ([textField isEqual:_baseUrlTextField]) {
    NSLog(@"_baseUrlTextField end");
    if (self.client) {
      self.client = nil;
      if (textField.text.length == 0) {
        self.client = [[WCSClient alloc] initWithBaseURL:nil andTimeout:30];
      }else{
        self.client = [[WCSClient alloc] initWithBaseURL:[NSURL URLWithString:textField.text] andTimeout:30];
      }
    }
  }
}


@end
