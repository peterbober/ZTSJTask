//
//  PCHTTPRequest.h
//  testDemo
//
//  Created by 张瑞 on 16/4/12.
//  Copyright © 2016年 张瑞. All rights reserved.
//

#import <Foundation/Foundation.h>

#define  CerFile @"developer.apple.com"

typedef NS_ENUM(NSInteger, PCHTTPCertificateStatus) {
    PCHTTPCertificateStatusDefault = 0,
    PCHTTPCertificateStatusNotValidate,
    PCHTTPCertificateStatusValidateCer,
};

#if NS_BLOCKS_AVAILABLE
typedef void (^PNCBasicBlock)(_Nullable id obj);
typedef void (^PNCHeadersBlock)( NSDictionary * _Nullable responseHeaders);
typedef void (^PNCDataBlock)( NSData * _Nullable data);
#endif

@protocol PCHTTPRequestDelegate;

/**
 *  基础http请求
 */
@interface PCHTTPRequest : NSObject
/*!
 *  @brief url
 */
@property (nullable, nonatomic, copy) NSString *urlString;

/*!
 *  @brief http  method，默认POST
 */
@property (nullable,nonatomic, copy) NSString *requestMethod;

/**
 *	@brief	服务器端解析所使用的编码格式,默认为text/xml
 */
@property (nullable,nonatomic,copy) NSString *contentType;

/**
 *	@brief	服务器端解析所使用的字符集类型 默认为UTF-8
 */
@property (nullable,nonatomic,copy) NSString *charType;

/*!
 *  @brief  委托
 */
@property (nullable,nonatomic ,assign) id <PCHTTPRequestDelegate> delegate;

/*!
 *  @brief  错误
 */
@property (nullable,nonatomic,strong) NSError *error;

/*!
 *  @brief  缓存策略，默认 NSURLRequestReloadIgnoringLocalCacheData
 */
@property (nonatomic ,assign) NSURLRequestCachePolicy cachePolicy;

/*!
 *  @brief  超时时间，默认 60秒
 */
@property (nonatomic ,assign) NSTimeInterval timeoutInterval;

/*!
 *  @brief  是否正在加载
 */
@property (nonatomic ,readonly) BOOL isLoading;

/*!
 *  @brief  状态返回代码
 */
@property (nonatomic ,assign) NSInteger statusCode;

/*!
 *  @brief  连接状态码
 */
@property (nonatomic ,assign) NSInteger errorCode;

/*!
 *  @brief  证书验证规则
 */
@property (nonatomic ,assign) PCHTTPCertificateStatus certificateStatus;

/**
 *  @brief  URLSessionConfiguration，iOS7后有效
 */
@property(nullable, nonatomic ,strong) NSURLSessionConfiguration *sessionConfiguration NS_AVAILABLE_IOS(7_0);

/*!
 *  @brief  启动请求添加字段 20170908
 */
@property (nullable,nonatomic ,copy) NSString *speNeed;

/*!
 *  @brief  通过url 构造一个实例
 *
 *  @param urlString url
 *
 *  @return PNCHTTPRequest
 */
+(nonnull PCHTTPRequest *)requestWithURL:(nullable NSString *)urlString;

/*!
 *  @brief 追加 post data
 *
 *  @param data NSData
 */
- (void)appendPostData:(nullable NSData *)data;

/*!
 *  @brief  获取 postData
 *
 *  @return 数据
 */
-(nullable NSData *)postData;

/*!
 *  @brief  设置post data
 *
 *  @param data NSData
 */
- (void)setPostData:(nullable NSData *)data;

/**
 *  @brief 上传文件
 *
 *  @param data     文件数据
 *  @param mimeType 文件类型
 *  @param fileName 文件名称
 */
- (void)addFile:(nullable NSData*)data mimeType:(nullable NSString*)mimeType fileName:(nullable NSString*)fileName;

/*!
 *  @brief  开始加载。异步
 */
- (void)start;

/*!
 *  @brief  取消加载，会将当前delegate、block置空
 */
-(void)cancel;

/*!
 *  @brief  同步请求
 *
 *  @return responseString
 */
-(nullable NSString *)startSynchronous;

/*!
 *  @brief  接收数据，NSString，utf-8编码
 *
 *  @return NSString
 */
- (nullable NSString *)responseString;

/*!
 *  @brief  接收数据，NSData 类型
 *
 *  @return NSData
 */
- (nullable NSData *)responseData;

/*!
 *  @brief  获取当前正在发送请求的数量
 *
 *  @return 请求数量
 */
+(NSInteger)requestCount;

/*!
 *  @brief  接收http 报文头 响应的block
 */
@property (nullable,nonatomic,copy) PNCHeadersBlock headersReceivedBlock;

/*!
 *  @brief  请求完成 响应的block
 */
@property (nullable,nonatomic,copy) PNCBasicBlock completionBlock;

/*!
 *  @brief  请求失败 响应的block
 */
@property (nullable,nonatomic,copy) PNCBasicBlock failureBlock;

/*!
 *  @brief  接收到数据 响应的block
 */
@property (nullable,nonatomic,copy) PNCDataBlock dataReceivedBlock;

@end

/*!
 *  @brief PNCHTTPRequest 的委托方法
 */
@protocol PCHTTPRequestDelegate <NSObject>

@optional

/*!
 *  @brief  接收报文头 响应的 委托方法
 *
 *  @param request         请求实例
 *  @param responseHeaders 报文头信息
 */
- (void)request:(nonnull PCHTTPRequest *)request didReceiveResponseHeaders:(nullable NSDictionary *)responseHeaders;

/*!
 *  @brief  请求完成 响应的委托方法
 *
 *  @param request 请求实例
 */
- (void)requestFinished:(nullable PCHTTPRequest *)request;

/*!
 *  @brief  请求失败 响应的委托方法
 *
 *  @param request 请求实例
 */
- (void)requestFailed:(nonnull PCHTTPRequest *)request;

/*!
 *  @brief  接收数据响应的委托方法
 *
 *  @param request 请求实例
 *  @param data    数据
 */
- (void)request:(nonnull PCHTTPRequest *)request didReceiveData:(nullable NSData *)data;

/**
 *  @brief 上传文件进度委托方法
 *
 *  @param request  请求实例
 *  @param progress 进度
 */
- (void)request:(nonnull PCHTTPRequest *)request uploadProgress:(nullable NSProgress *)progress;

/**
 *  @brief 下载文件进度委托方法
 *
 *  @param request  请求实例
 *  @param progress 进度
 */
- (void)request:(nonnull PCHTTPRequest *)request downloadProgress:(nullable NSProgress *)progress;

@end
