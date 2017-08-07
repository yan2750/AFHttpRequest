//
//  AFHttpRequest.m
//  PipixiaTravel
//
//  Created by LazyDuan on 2017/5/8.
//  Copyright © 2017年 easyto. All rights reserved.
//

#import "AFHttpRequest.h"
//#import "LoadingView.h"
//#import "NSObject+GetTableView.h"
//#import <MJRefresh.h>

#define ERROR_CODE  @"res_code"
#define ERROR_MESSAGE  @"res_msg"
#define tokenOverCode @"000996"
@interface AFHttpRequest ()
@property (nonatomic, strong)AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong)AFSecurityPolicy *securityPolicy;
@property (nonatomic, strong)AFNetworkReachabilityManager *networkManager;
@property (nonatomic, copy) NSMutableSet *mutableSet;
@end

@implementation AFHttpRequest

static AFHttpRequest *request = nil;

+ (AFHttpRequest *)shareRequest
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        request = [[AFHttpRequest alloc] init];
        request.sessionManager = [AFHTTPSessionManager manager];
        request.networkManager = [AFNetworkReachabilityManager sharedManager];
        request.enableMessage = NO;
    });
    return request;
}


//- (NSMutableDictionary *)defaultParam{
//    
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    dict[@"user_id"] = [UserInfoModel userInfoModel].user_id;
//    dict[@"device_id"] = [ToolMethod UUIDString];
//    dict[@"token"] = [UserInfoModel userInfoModel].token;
//    
//////#warning 临时添加测试数据
////    dict[@"user_id"] = @"0001_5555555555";
////    dict[@"device_id"] = @"1";
////    dict[@"token"] = @"1";
//    return dict;
//}


- (NSMutableSet *)mutableSet
{
    if (!_mutableSet) {
        _mutableSet = [NSMutableSet set];
    }
    return _mutableSet;
}


#pragma mark 网络状态

+ (BOOL)isNetworkConnected
{
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    return (mgr.networkReachabilityStatus == (AFNetworkReachabilityStatusNotReachable | AFNetworkReachabilityStatusUnknown))?NO:YES;
}

+ (BOOL)isWifiConnected
{
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    return mgr.isReachableViaWiFi;
}

+ (kNetWorkConnectState)getNetworkState {
    kNetWorkConnectState connectState = kNetWorkConnectStateNotConnected;
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    switch (mgr.networkReachabilityStatus) {
        case (AFNetworkReachabilityStatusNotReachable | AFNetworkReachabilityStatusUnknown):
            connectState = kNetWorkConnectStateNotConnected;
            break;
        case AFNetworkReachabilityStatusReachableViaWiFi:
            connectState = kNetWorkConnectStateWifi;
            break;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            connectState = kNetWorkConnectStateData;
            break;
        default:
            break;
    }
    return connectState;
}

- (void)configAFInAppDeletage {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
        if (status == AFNetworkReachabilityStatusUnknown || status == AFNetworkReachabilityStatusNotReachable) {
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:nil message:@"亲，请检查网络状态！~~~" preferredStyle:UIAlertControllerStyleAlert];
            [alertC addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            
            [[[UIApplication sharedApplication].delegate window].rootViewController presentViewController:alertC animated:YES completion:nil];
            
            
        }else {
        }
    }];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}



#pragma mark get和post请求

/**
 发起网络请求

 @param urlString 链接地址
 @param header 传的参数列表  showLoadingView 默认为YES显示
 @param success 成功
 @param failure 失败
 */

- (void)requestPOSTWithUrl:(NSString *)urlString
                withParams:(id)header
               withSuccess:(void (^)(id data, NSError *error))success
               withFailure:(void (^)(id data, NSError *error ,NSDictionary *errorDic))failure {
    
    if(urlString == nil) {
        return;
    }
    
    if(!header){
        header = [[NSMutableDictionary alloc]init];
    }
    
    
    if ([self.mutableSet containsObject:urlString]) {
        return;
    }
    
    NSLog(@"header = %@",header);
    // 只有设置了showLoadingView这个参数为NO才不显示loading框
    [self showLoadingViewWithHeader:header];
    
    if([header isKindOfClass:NSMutableDictionary.class]){
        NSMutableDictionary *dict = header;
        if([[dict allKeys]containsObject:@"json"]){
            [dict removeObjectForKey:@"json"];
            urlString = [NSString stringWithFormat:@"%@?user_id=%@&device_id=%@&token=%@",
                         urlString,
                         self.userID,
                         self.uuid,
                         self.token];
            _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        }else{
            [dict addEntriesFromDictionary:self.defaultParam];
            _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        }
    }else{
        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    
    [self.mutableSet addObject:urlString];
    _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [_sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [_sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
    [_sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/json"];
    
    _sessionManager.securityPolicy = [self customSecurityPolicy:NO];
    
    [_sessionManager POST:urlString parameters:header progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        id data = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        // 隐藏loading框
        [self hiddenLoadingView];
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSString *code = [data objectForKey:ERROR_CODE];
            if ([code isEqualToString:tokenOverCode]) {
                //[YTAlertUtils urlRequestTokenErrorWithMessage:data[ERROR_MESSAGE]];
            }else{
                success(data,nil);
            }
        }else{
            success(data,nil);
        }
        [self.mutableSet removeObject:urlString];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 隐藏loading框
        [self hiddenLoadingView];
        failure(task,error,nil);
        [self.mutableSet removeObject:urlString];
//        if (error.code == 1009) {
//            [ToastsView showWithMessage:@"网络开了小差"];
//        }
    }];
}


/**
 发起Get网络请求
 
 @param urlString 链接地址
 @param header 传的参数列表  showLoadingView 默认为YES显示  传输Bool值
 @param success 成功
 @param failure 失败
 */

- (void)requestGETWithUrl:(NSString *)urlString
               withParams:(id)header
              withSuccess:(void (^)(id data, NSError *error))success
              withFailure:(void (^)(id data, NSError *error ,NSDictionary *errorDic))failure {
    if ([self.mutableSet containsObject:urlString]) {
        return;
    }
    
    if(header == nil){
        header = [[NSMutableDictionary alloc]init];
        [header addEntriesFromDictionary:[self defaultParam]];
    }else if([header isKindOfClass:NSMutableDictionary.class]){
        NSMutableDictionary *dict = header;
        [dict addEntriesFromDictionary:[self defaultParam]];
    }
    
    
    if ([header isKindOfClass:NSClassFromString(@"_TtGCs26_SwiftDeferredNSDictionarySSSS_")]) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:header];
        [dict addEntriesFromDictionary:[self defaultParam]];
        header = dict;
    }
    
    [self.mutableSet addObject:urlString];
    _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [_sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    _sessionManager.securityPolicy = [self customSecurityPolicy:NO];
    [self showLoadingViewWithHeader:header];
    
    [_sessionManager GET:urlString parameters:header progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 隐藏loading框
        [self hiddenLoadingView];
        
        id data = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        //DebugLog(@"服务器返回数据 = %@",data);
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSString *code = [data objectForKey:@"res_code"];
            if ([code isEqualToString:tokenOverCode]) {
                //[YTAlertUtils urlRequestTokenErrorWithMessage:data[ERROR_MESSAGE]];
            }else{

                success(data,nil);
            }
        }else{
            success(data,nil);
        }
        [self.mutableSet removeObject:urlString];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 隐藏loading框
        [self hiddenLoadingView];
        
        [self.mutableSet removeObject:urlString];
        failure(task,error,nil);
        //        [MBProgressHUD showError:@"网络开了小差"];
    }];
}

- (void)requestGETReturnStrWithUrl:(NSString *)urlString
               withParams:(id)header
              withSuccess:(void (^)(id data, NSError *error))success
              withFailure:(void (^)(id data, NSError *error ,NSDictionary *errorDic))failure {
    if ([self.mutableSet containsObject:urlString]) {
        return;
    }
    
    if(header == nil){
        header = [[NSMutableDictionary alloc]init];
        [header addEntriesFromDictionary:[self defaultParam]];
    }else if([header isKindOfClass:NSMutableDictionary.class]){
        NSMutableDictionary *dict = header;
        [dict addEntriesFromDictionary:[self defaultParam]];
    }
    
    [self.mutableSet addObject:urlString];
    _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [_sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    _sessionManager.securityPolicy = [self customSecurityPolicy:NO];
    [self showLoadingViewWithHeader:header];
    
    [_sessionManager GET:urlString parameters:header progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 隐藏loading框
        [self hiddenLoadingView];
        
        id data = [[NSString alloc] initWithData:responseObject  encoding:NSUTF8StringEncoding];
        
        //DebugLog(@"服务器返回数据 = %@",data);
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSString *code = [data objectForKey:@"res_code"];
            if ([code isEqualToString:tokenOverCode]) {
                //[YTAlertUtils urlRequestTokenErrorWithMessage:data[ERROR_MESSAGE]];
            }else{

                success(data,nil);
            }
        }else{
            success(data,nil);
        }
        [self.mutableSet removeObject:urlString];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 隐藏loading框
        [self hiddenLoadingView];
        
        [self.mutableSet removeObject:urlString];
        failure(task,error,nil);
        //        [MBProgressHUD showError:@"网络开了小差"];
    }];
}



#pragma mark 改进的post和get请求

/**
 改进版POST请求
 
 @param url 连接地址
 @param header 传输的DIC
 @param block 返回的block
 */

- (void)requestPOSTWithUrl:(NSString *)url
                withParams:(id)header
                 withBlock:(Result)block {
    [self requestPOSTWithUrl:url
                  withParams:header
                 withSuccess:^(id data, NSError *error) {
        block(data,nil,nil);
                     
    } withFailure:^(id data, NSError *error ,NSDictionary *errorDic) {
        block(nil,error,errorDic);
        
    }];
}

/**
 改进版Get请求
 
 @param url 连接地址
 @param header 传输的DIC
 @param block 返回的block
 */
- (void)requestGETWithUrl:(NSString *)url
               withParams:(id)header
                withBlock:(Result)block {
    [self requestGETWithUrl:url
                 withParams:header
                withSuccess:^(id data, NSError *error) {
        block(data,nil,nil);
                    
    } withFailure:^(id data, NSError *error ,NSDictionary *errorDic) {
        block(nil,data,errorDic);
        
    }];
}

- (void)requestGETReturnStrWithUrl:(NSString *)url
               withParams:(id)header
                withBlock:(Result)block {
    [self requestGETReturnStrWithUrl:url
                 withParams:header
                withSuccess:^(id data, NSError *error) {
                    block(data,nil,nil);
                    
                } withFailure:^(id data, NSError *error ,NSDictionary *errorDic) {
                    block(nil,data,errorDic);
                    
                }];
}

#pragma mark 上传文件

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
           withFailuer:(UploadFileFailure)failure {
    if ([self.mutableSet containsObject:url]) {
        return;
    }
    
    [self showLoadingViewWithHeader:header];
    [self.mutableSet addObject:url];
    [_sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    _sessionManager.securityPolicy = [self customSecurityPolicy:NO];
    
    [_sessionManager POST:url parameters:header constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        postData(formData);
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *code = [responseObject objectForKey:@"res_code"];
            if ([code isEqualToString:tokenOverCode]) {
            } else {
                if ([responseObject[@"code"] integerValue] == 200) {
                    success(responseObject,nil);
                }
            }
        }else {
            success(responseObject,nil);
        }
        
        // 隐藏loading框
        [self hiddenLoadingView];
        [self.mutableSet removeObject:url];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.mutableSet removeObject:url];
        failure(nil,error,nil);
        // 隐藏loading框
        [self hiddenLoadingView];
    }];
}


- (AFSecurityPolicy*)customSecurityPolicy:(BOOL)isHTTPS
{
    if (isHTTPS) {
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@".cer"];
        NSData *certData = [NSData dataWithContentsOfFile:cerPath];
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        [_securityPolicy setPinnedCertificates:[NSSet setWithObject:certData]];
        [_securityPolicy setValidatesDomainName:NO];
        [_securityPolicy setAllowInvalidCertificates:YES];
        
    }else{
        self.securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    return _securityPolicy;
}


- (void)showLoadingViewWithHeader:(id)header {
    if ([header isKindOfClass:[NSMutableDictionary class]]) {
        if (!([[header allKeys] containsObject:@"showLoadingView"] && (header[@"showLoadingView"]))) {
            // 显示loading框
            //[LoadingView showInView:[[UIApplication sharedApplication].delegate window]];
        }
        // 移除loading框的key
        if ([[header allKeys] containsObject:@"showLoadingView"] ) {
            [header removeObjectForKey:@"showLoadingView"];
            if ([[header allKeys] count] == 0) {
                header = nil;
            }
        }
    }
}

- (void)hiddenLoadingView {
//    [LoadingView hiddenFromView:[[UIApplication sharedApplication].delegate window]];
//    [self getScrollView:^(UIScrollView *scroll) {
//        if (scroll) {
//            
//            if (scroll.mj_footer.isRefreshing) {
//                [scroll.mj_footer endRefreshing];
//            }
//            
//            if (scroll.mj_header.isRefreshing) {
//                [scroll.mj_header endRefreshing];
//            }
//        }
//        
//    }];
    
}




@end
