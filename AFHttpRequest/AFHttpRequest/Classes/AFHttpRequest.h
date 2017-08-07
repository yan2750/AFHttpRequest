//
//  AFHttpRequest.h
//  PipixiaTravel
//
//  Created by LazyDuan on 2017/5/8.
//  Copyright © 2017年 easyto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

typedef void (^Result)(id data, NSError *error ,NSDictionary *errorDic); /*Get、Post请求的block回调*/
typedef void (^UploadFileSuccess)(id data, NSError *error); /*上传文件成功的block回调*/
typedef void (^UploadFileFailure)(id data, NSError *error ,NSDictionary *errorDic); /*上传文件失败的block回调*/


typedef NS_ENUM(NSInteger, kNetWorkConnectState) {
    kNetWorkConnectStateNotConnected = 0,
    kNetWorkConnectStateWifi = 1,
    kNetWorkConnectStateData = 2
};

@interface AFHttpRequest : NSObject

@property (nonatomic, assign) BOOL enableMessage;
@property (nonatomic, strong) NSMutableDictionary *defaultParam;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *uuid;


+ (AFHttpRequest *)shareRequest;


/**
 网络连接状态

 @return YES 连接 NO 未连接
 */
+ (BOOL)isNetworkConnected;

/**
 WIFI的连接状态
 
 @return 连接状态
 */
+ (BOOL)isWifiConnected;


/**
 获取网络的连接状态

 @return 连接状态
 */
+ (kNetWorkConnectState)getNetworkState;

- (void)configAFInAppDeletage;


//post请求
- (void)requestPOSTWithUrl:(NSString *)urlString
                withParams:(id)header withSuccess:(void (^)(id data, NSError *error))success
               withFailure:(void (^)(id data, NSError *error ,NSDictionary *errorDic))failure;
//get请求
- (void)requestGETWithUrl:(NSString *)urlString  withParams:(id)header withSuccess:(void (^)(id data, NSError *error))success withFailure:(void (^)(id data, NSError *error ,NSDictionary *errorDic))failure;


#pragma mark 常用的网络请求
/**
 改进版POST请求
 
 @param url 连接地址
 @param header 传输的DIC
 @param block 返回的block
 */
- (void)requestPOSTWithUrl:(NSString *)url
                withParams:(id)header
                 withBlock:(Result)block;


/**
 改进版Get请求

 @param url 连接地址
 @param header 传输的DIC
 @param block 返回的block
 */
- (void)requestGETWithUrl:(NSString *)url
               withParams:(id)header
                withBlock:(Result)block;

- (void)requestGETReturnStrWithUrl:(NSString *)url
                        withParams:(id)header
                         withBlock:(Result)block;



/**
 上传文件的接口

 @param url 上传的连接地址
 @param header 传输的DIC
 @param postData 流数据
 @param success 成功的回调
 @param failure 失败的回调
 */
- (void)requestPostUrl:(NSString *)url
            withParams:(id)header
         withFilesData:(void(^)(id<AFMultipartFormData> formData))postData
           withSuccess:(UploadFileSuccess)success
           withFailuer:(UploadFileFailure)failure;

@end
