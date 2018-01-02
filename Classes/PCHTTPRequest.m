//
//  PCHTTPRequest.m
//  testDemo
//
//  Created by 张瑞 on 16/4/12.
//  Copyright © 2016年 张瑞. All rights reserved.
//

#import "PCHTTPRequest.h"
#import <UIKit/UIKit.h>

#define iOS7Later (([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)? (YES):(NO))

static NSInteger kRequestCount =0;
static NSString* kStringBoundary = @"----WebKitFormBoundary5lfm9tU6pTGrcrLW";

#pragma mark -上传文件DataObject

@interface PCUploadFileDO : NSObject
//文件流
@property(nonatomic,strong) NSData *fileData;
//文件名
@property(nonatomic,strong) NSString *fileName;
//文件类型
@property(nonatomic,strong) NSString *fileType;

@end

@implementation PCUploadFileDO

@end

#pragma mark -PNCHTTPRequest

@interface PCHTTPRequest()<NSURLSessionDelegate,NSURLSessionDataDelegate>

@property(nonatomic, strong)NSURLSession *session;

@property (nonatomic,strong) NSMutableData *receivedData;

@property (nonatomic,retain) NSMutableData *postHttpData;

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic,assign) long long totalLength;

@property (nonatomic, strong) NSMutableArray *uploadFiles;

@end

@implementation PCHTTPRequest

#pragma mark -init

-(id)init{
    if (self=[super init]) {
        _isLoading = NO;
        self.timeoutInterval = 60.f;
        self.contentType = @"application/json";
        self.charType  = @"charset=UTF-8";
        self.requestMethod = @"POST";
        self.certificateStatus = PCHTTPCertificateStatusDefault;
        self.receivedData =[[NSMutableData alloc] init];
    }
    return self;
}

+(PCHTTPRequest *)requestWithURL:(NSString *)urlString{
    
    PCHTTPRequest *request =[[PCHTTPRequest alloc] init];
    request.urlString = urlString;
    return request;
}

#pragma mark -上传文件数组

-(NSMutableArray *)uploadFiles{
    if (_uploadFiles==nil) {
        _uploadFiles =[[NSMutableArray alloc]init];
    }
    return _uploadFiles;
}

#pragma mark -追加HttpData

- (void)appendPostData:(NSData *)data{
    
    if (self.postHttpData ==nil) {
        self.postHttpData =[[NSMutableData alloc] init];
    }
    [(NSMutableData *)self.postHttpData appendData:data];
}

#pragma mark -设置HttpData

-(void)setPostData:(NSData *)data{
    
    self.postHttpData = [[NSMutableData alloc] initWithData:data];
}

#pragma mark -添加上传文件

- (void)addFile:(nullable NSData*)data mimeType:(nullable NSString*)mimeType fileName:(nullable NSString*)fileName{
    if (data && data.length>0) {
        PCUploadFileDO *fileDO =[[PCUploadFileDO alloc]init];
        fileDO.fileData =data;
        fileDO.fileName =fileName?:@"";
        fileDO.fileType =mimeType?:@"";
        [self.uploadFiles addObject:fileDO];
    }
}

#pragma mark -postData

-(NSData *)postData{
    
    return _postHttpData;
}

#pragma mark -urlRequest

-(NSURLRequest *)urlRequest{
    
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.timeoutInterval];
    NSString *httpContentType = [NSString stringWithFormat:@"%@;%@",self.contentType,self.charType];
    [request setValue:httpContentType forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:self.requestMethod];
    
    //上传文件
    if (self.uploadFiles && self.uploadFiles.count>0) {
        NSMutableData *uploadData =[[NSMutableData alloc]init];
        for (PCUploadFileDO *fileDO  in self.uploadFiles) {
            //组装文件流对应格式
            NSString *contentType =[NSString stringWithFormat:@"multipart/form-data; boundary=%@",kStringBoundary];
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
            NSString* beginLine = [NSString stringWithFormat:@"--%@\r\n", kStringBoundary];
            NSString *endLine = @"\r\n";
            [uploadData appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];
            [uploadData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileDO.fileName] dataUsingEncoding:NSUTF8StringEncoding]];
            [uploadData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", fileDO.fileType]dataUsingEncoding:NSUTF8StringEncoding]];
            [uploadData appendData:fileDO.fileData];
            [uploadData appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
            [uploadData appendData:[[NSString stringWithFormat:@"--%@--\r\n", kStringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [self appendPostData:uploadData];
    }
    if(self.postHttpData){
        [request setHTTPBody:self.postHttpData];
    }
    return request;
}

#pragma mark -异步请求

-(void)start{
    
    NSURLRequest *request =[self urlRequest];
    
    if(!iOS7Later){
        //iOS7以下使用NSURLConnection
        if (self.connection) {
            [self.connection cancel];
            self.receivedData =nil;
        }
        self.connection =[[NSURLConnection alloc] initWithRequest:request delegate:self];
        [self.connection start];
    }else{
        //iOS7以上使用NSURLSession
        if (self.session) {
            [self.session  invalidateAndCancel];
        }
        if (!self.sessionConfiguration) {
            self.sessionConfiguration =[NSURLSessionConfiguration defaultSessionConfiguration];
        }
        self.session = [NSURLSession sessionWithConfiguration:_sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
        
        [task resume];
    }
    [self setNetworkActivity:YES];
}

#pragma mark -同步请求

-(NSString *)startSynchronous{
    
    [self setNetworkActivity:YES];
    
    __block NSString *responseString;
    NSMutableURLRequest *request =(NSMutableURLRequest *)[self urlRequest];
    
    if (iOS7Later) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            responseString =[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
    }else{
        NSData *data =[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        responseString =[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    }
    
    [self setNetworkActivity:NO];
    
    return responseString;
}

#pragma mark -取消请求

-(void)cancel{
    
    if (iOS7Later) {
        if (self.isLoading && self.session)
            [self.session  invalidateAndCancel];
        self.session =nil;
    }else{
        [self.connection cancel];
    }
    self.delegate =nil;
    self.completionBlock =nil;
    self.failureBlock =nil;
    self.dataReceivedBlock =nil;
    self.headersReceivedBlock =nil;
    
    [self setNetworkActivity:NO];
}

#pragma mark -响应数据字符串格式

- (NSString *)responseString{
    
    NSData *data = [self receivedData];
    if (!data) {
        return nil;
    }
    NSString *string =[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    
    return string;
}

#pragma mark -响应数据NSData格式

- (NSData *)responseData{
    
    return self.receivedData;
}

#pragma mark -当前请求个数

+(NSInteger)requestCount{
    
    return kRequestCount;
}

#pragma mark -NSURLConnectionDelegate(<iOS7)

//发送数据
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    //上传进度
    NSProgress *uploadProgress =[[NSProgress alloc]init];
    uploadProgress.totalUnitCount =totalBytesExpectedToWrite;
    uploadProgress.completedUnitCount =totalBytesWritten;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:uploadProgress:)]) {
        [self.delegate request:self uploadProgress:uploadProgress];
    }
}

//收到响应
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    
    self.receivedData =[[NSMutableData alloc] init];
    
    NSHTTPURLResponse *httpResPonse = (NSHTTPURLResponse *)response;
    
    if ([httpResPonse isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSDictionary *httpResponseHeaderFields = [httpResPonse allHeaderFields];
        
        if (_headersReceivedBlock !=nil) {
            _headersReceivedBlock(httpResponseHeaderFields);
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(request:didReceiveResponseHeaders:)]) {
            [self.delegate request:self didReceiveResponseHeaders:httpResponseHeaderFields];
        }
        self.totalLength = [[httpResponseHeaderFields objectForKey:@"Content-Length"] longLongValue];
    }
}

//收到数据
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    [self.receivedData appendData:data];
    
    if (_dataReceivedBlock !=nil) {
        _dataReceivedBlock(data);
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
        [self.delegate request:self didReceiveData:data];
    }
    //下载进度
    NSProgress *downloadProgress =[[NSProgress alloc]init];
    downloadProgress.totalUnitCount =self.totalLength;
    downloadProgress.completedUnitCount =self.receivedData.length;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:downloadProgress:)]) {
        [self.delegate request:self downloadProgress:downloadProgress];
    }
}

//请求完成
- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection{
    
    if (_completionBlock !=nil) {
        _completionBlock(self);
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFinished:)]){
        [self.delegate requestFinished:self];
    }
    
    [self setNetworkActivity:NO];
}

//请求失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    self.error = error;
    
    if (_failureBlock !=nil) {
        _failureBlock(self);
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFailed:)]){
        [self.delegate requestFailed:self];
    }
    
    [self setNetworkActivity:NO];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

//验证证书
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    switch (self.certificateStatus) {
        case PCHTTPCertificateStatusDefault:
        {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                NSURLCredential *credential =  [NSURLCredential credentialForTrust:[challenge protectionSpace].serverTrust];
                //创建证书
                [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                
                [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
            }else{
                NSLog(@"证书不可以信任");
            }
        }
            break;
        case PCHTTPCertificateStatusNotValidate:
        {
            NSURLCredential *credential =[NSURLCredential credentialForTrust:[challenge protectionSpace].serverTrust];
            //创建证书
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
        }
            break;
        case PCHTTPCertificateStatusValidateCer:
        {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
                // 获取der格式CA证书路径
                NSString *certPath = [[NSBundle mainBundle] pathForResource:CerFile ofType:@"cer"];
                // 提取二进制内容
                NSData *derCA = [NSData dataWithContentsOfFile:certPath];
                // 根据二进制内容提取证书信息
                SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)derCA);
                // 形成钥匙链
                NSArray * chain = [NSArray arrayWithObject:(__bridge id)(caRef)];
                CFArrayRef caChainArrayRef = CFBridgingRetain(chain);
                // 取出服务器证书
                SecTrustRef trust = [[challenge protectionSpace] serverTrust];
                SecTrustResultType trustResult = 0;
                // 设置为我们自有的CA证书钥匙连
                int err = SecTrustSetAnchorCertificates(trust, caChainArrayRef);
                if (err == noErr) {
                    // 用CA证书验证服务器证书
                    err = SecTrustEvaluate(trust, &trustResult);
                }
                CFRelease(trust);
                // 检查结果
                BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed)||(trustResult ==2) || (trustResult == kSecTrustResultUnspecified));
                if (trusted) {
                    NSURLCredential *credential =  [NSURLCredential credentialForTrust:[challenge protectionSpace].serverTrust];
                    //创建证书
                    [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                    [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
                }else{
                    NSLog(@"证书不可以信任");
                }
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark -NSURLSessionTaskDelegate(>=iOS7)

//发送数据
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    //上传进度
    NSProgress *uploadProgress =[[NSProgress alloc]init];
    uploadProgress.totalUnitCount =totalBytesExpectedToSend;
    uploadProgress.completedUnitCount =totalBytesSent;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:uploadProgress:)]) {
        [self.delegate request:self uploadProgress:uploadProgress];
    }
}

//接收响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        
        self.statusCode = httpResponse.statusCode;
        self.receivedData =[[NSMutableData alloc] init];
        NSDictionary *httpResponseHeaderFields = [httpResponse allHeaderFields];
        
        if (_headersReceivedBlock !=nil) {
            _headersReceivedBlock(httpResponseHeaderFields);
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(request:didReceiveResponseHeaders:)]) {
            [self.delegate request:self didReceiveResponseHeaders:httpResponseHeaderFields];
        }
        self.totalLength = [[httpResponseHeaderFields objectForKey:@"Content-Length"] longLongValue];
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

//请求完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    NSHTTPURLResponse *response =(NSHTTPURLResponse *)task.response;
    self.errorCode  = error.code;
    self.statusCode = response.statusCode;
    
    if (error) {
        self.error = error;
        if (_failureBlock !=nil) {
            _failureBlock(self);
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestFailed:)]){
            [self.delegate requestFailed:self];
        }
    }else{
        if (_completionBlock !=nil) {
            _completionBlock(self);
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestFinished:)]){
            [self.delegate requestFinished:self];
        }
    }
    
    [self setNetworkActivity:NO];
}

//收到返回数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
    [self.receivedData appendData:data];
    
    if (_dataReceivedBlock !=nil) {
        _dataReceivedBlock(data);
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
        [self.delegate request:self didReceiveData:data];
    }
    //下载进度
    NSProgress *downloadProgress =[[NSProgress alloc]init];
    downloadProgress.totalUnitCount =self.totalLength;
    downloadProgress.completedUnitCount =self.receivedData.length;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:downloadProgress:)]) {
        [self.delegate request:self downloadProgress:downloadProgress];
    }
}

//证书验证
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    
    switch (self.certificateStatus) {
        case PCHTTPCertificateStatusDefault:
        {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                
                NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                completionHandler(NSURLSessionAuthChallengeUseCredential , credential);
            }else{
                NSLog(@"证书不可以信任");
            }
        }
            break;
        case PCHTTPCertificateStatusNotValidate:
        {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential , credential);
        }
            break;
        case PCHTTPCertificateStatusValidateCer:
        {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                // 获取der格式CA证书路径
                NSString *certPath = [[NSBundle mainBundle] pathForResource:CerFile ofType:@"cer"];
                // 提取二进制内容
                NSData *derCA = [NSData dataWithContentsOfFile:certPath];
                // 根据二进制内容提取证书信息
                SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)derCA);
                // 形成钥匙链
                NSArray * chain = [NSArray arrayWithObject:(__bridge id)(caRef)];
                
                CFArrayRef caChainArrayRef = CFBridgingRetain(chain);
                // 取出服务器证书
                SecTrustRef trust = [[challenge protectionSpace] serverTrust];
                
                SecTrustResultType trustResult = 0;
                // 设置为我们自有的CA证书钥匙连
                int err = SecTrustSetAnchorCertificates(trust, caChainArrayRef);
                if (err == noErr) {
                    // 用CA证书验证服务器证书
                    err = SecTrustEvaluate(trust, &trustResult);
                }
                CFRelease(trust);
                // 检查结果
                BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed)||(trustResult ==2) || (trustResult == kSecTrustResultUnspecified));
                if (trusted) {
                    //创建证书
                    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    completionHandler(NSURLSessionAuthChallengeUseCredential , credential);
                }else{
                    NSLog(@"证书不可以信任");
                }
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark -风火轮

-(void)setNetworkActivity:(BOOL)show{
    
    _isLoading =show;
    kRequestCount += show?1:-1;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:show];
}

-(void)dealloc{
    
    [self cancel];
}

@end
