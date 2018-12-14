//
//  RCTWeChat.m
//  RCTWeChat
//
//  Created by Yorkie Liu on 10/16/15.
//  Copyright © 2015 WeFlex. All rights reserved.
//

#import "RCTWeChat.h"
#import "WXApiObject.h"
#import <React/RCTEventDispatcher.h>
#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTImageLoader.h>

// Define error messages
#define NOT_REGISTERED (@"registerApp required.")
#define INVOKE_FAILED (@"WeChat API invoke returns false.")

@implementation RCTWeChat

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:@"RCTOpenURLNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)handleOpenURL:(NSNotification *)aNotification
{
    NSString * aURLString =  [aNotification userInfo][@"url"];
    NSURL * aURL = [NSURL URLWithString:aURLString];

    if ([WXApi handleOpenURL:aURL delegate:self])
    {
        return YES;
    } else {
        return NO;
    }
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_METHOD(registerApp:(NSString *)appid
                  :(RCTResponseSenderBlock)callback)
{
    self.appId = appid;
    callback(@[[WXApi registerApp:appid] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(registerAppWithDescription:(NSString *)appid
                  :(NSString *)appdesc
                  :(RCTResponseSenderBlock)callback)
{
    callback(@[[WXApi registerApp:appid] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(isWXAppInstalled:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppInstalled])]);
}

RCT_EXPORT_METHOD(isWXAppSupportApi:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppSupportApi])]);
}

RCT_EXPORT_METHOD(getWXAppInstallUrl:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getWXAppInstallUrl]]);
}

RCT_EXPORT_METHOD(getApiVersion:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getApiVersion]]);
}

RCT_EXPORT_METHOD(openWXApp:(RCTResponseSenderBlock)callback)
{
    callback(@[([WXApi openWXApp] ? [NSNull null] : INVOKE_FAILED)]);
}

RCT_EXPORT_METHOD(sendRequest:(NSString *)openid
                  :(RCTResponseSenderBlock)callback)
{
    BaseReq* req = [[BaseReq alloc] init];
    req.openID = openid;
    callback(@[[WXApi sendReq:req] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendAuthRequest:(NSString *)scope
                  :(NSString *)state
                  :(RCTResponseSenderBlock)callback)
{
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = scope;
    req.state = state;
    BOOL success = [WXApi sendReq:req];
    callback(@[success ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendSuccessResponse:(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXSuccess;
    callback(@[[WXApi sendResp:resp] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendErrorCommonResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeCommon;
    resp.errStr = message;
    callback(@[[WXApi sendResp:resp] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendErrorUserCancelResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeUserCancel;
    resp.errStr = message;
    callback(@[[WXApi sendResp:resp] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(shareToTimeline:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneTimeline callback:callback];
}

RCT_EXPORT_METHOD(shareToSession:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneSession callback:callback];
}

RCT_EXPORT_METHOD(shareToMiniProgram:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToMiniProgramWithData:data scene:WXSceneSession callback:callback];
}

- (void)shareToMiniProgramWithData:(NSDictionary *)aData scene:(int)aScene callback:(RCTResponseSenderBlock)aCallBack
{
    NSLog(@"进来了 %@ == ",aData);
    //如果是网络图片huo'quuan'ga
    NSURL *url = [NSURL URLWithString:aData[RCTWXShareImageUrl]];
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
    if([aData[RCTWXShareImageUrl] hasPrefix:@"http"]){
        NSData *datas = [NSData dataWithContentsOfURL:url];
    }
    NSData *datas = [NSData dataWithContentsOfURL:url];
    
    [self.bridge.imageLoader loadImageWithURLRequest:imageRequest callback:^(NSError *error, UIImage *image)  {
        if (image == nil){
            aCallBack(@[@"fail to load image resource"]);
        } else {
            
            WXMiniProgramObject *wxMiniObject = [WXMiniProgramObject object];
            wxMiniObject.webpageUrl = aData[@"webPage"];
            wxMiniObject.userName = aData[@"miniProgramId"];
            
            if(datas){
               wxMiniObject.hdImageData = datas;
            }else{
                wxMiniObject.hdImageData =UIImagePNGRepresentation(image) ;
            }
            wxMiniObject.path = aData[@"path"];
            
            NSString *typeMini = aData[@"type"];
            if([typeMini isEqualToString:RCTMiniProgramTypeRelease]){
                wxMiniObject.miniProgramType = WXMiniProgramTypeRelease;
            }else if([typeMini isEqualToString:RCTMiniProgramTypeTest]){
                wxMiniObject.miniProgramType = WXMiniProgramTypeTest;
            }else if([typeMini isEqualToString:RCTMiniProgramTypePreview]){
                wxMiniObject.miniProgramType = WXMiniProgramTypePreview;
            }
            
            WXMediaMessage *message = [WXMediaMessage message];
            message.title= aData[@"title"];
            message.description = aData[@"desc"];
            message.mediaObject = wxMiniObject ;
            message.thumbData = nil;
            
            SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
            req.message = message;
            req.scene = WXSceneSession;
            
//            wxMiniObject.webpageUrl = @"http://www.baidu.com/asdf";
//            wxMiniObject.userName = @"gh_feeed5fa6d6d";
//            wxMiniObject.path = @"pages/index/index";
//            wxMiniObject.hdImageData = UIImagePNGRepresentation(image);
//            NSString *typeMini = aData[@"type"];
//            if([typeMini isEqualToString:RCTMiniProgramTypeRelease]){
//                wxMiniObject.miniProgramType = WXMiniProgramTypeRelease;
//            }else if([typeMini isEqualToString:RCTMiniProgramTypeTest]){
//                wxMiniObject.miniProgramType = WXMiniProgramTypeTest;
//            }else if([typeMini isEqualToString:RCTMiniProgramTypePreview]){
//                wxMiniObject.miniProgramType = WXMiniProgramTypePreview;
//            }
            //
//            WXLaunchMiniProgramReq *WxLaunch = [WXLaunchMiniProgramReq object];
//            WxLaunch.userName = @"gh_feeed5fa6d6d";
//            WxLaunch.miniProgramType =WXMiniProgramTypePreview;
//            WXMediaMessage *message = [WXMediaMessage message];
//            WxLaunch.path = @"pages/index/index";
//            message.title = @"333";
//            message.description = @"343";
//            message.mediaObject = wxMiniObject;
//            message.thumbData =nil;
//            NSLog(@"进来了数据显示嘿嘿msg %@ == ",message);
//            NSLog(@"进来了数据显示嘿嘿 图片 %@ == ",UIImagePNGRepresentation(image));
//
//            NSLog(@"进来了数据显示userName %@ == ",wxMiniObject.userName);
//
//            NSLog(@"进来了数据显示嘿嘿 path %@ == ",wxMiniObject.path);
//            NSLog(@"进来了数据显示嘿嘿tuype %d == ",wxMiniObject.miniProgramType);
            
            
//            SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
//            req.message = message;
//            req.scene = WXSceneSession;
            BOOL success = [WXApi sendReq:req];
            NSLog(@"进来了数据显示嘿嘿1 %@ == ",success==true?@"true":@"false");
            aCallBack(@[success ? [NSNull null] : INVOKE_FAILED]);
            
        }
    }];
   
    
    
}

RCT_EXPORT_METHOD(shareToFavorite:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneFavorite callback:callback];
}

RCT_EXPORT_METHOD(pay:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    PayReq* req             = [PayReq new];
    req.partnerId           = data[@"partnerId"];
    req.prepayId            = data[@"prepayId"];
    req.nonceStr            = data[@"nonceStr"];
    req.timeStamp           = [data[@"timeStamp"] unsignedIntValue];
    req.package             = data[@"package"];
    req.sign                = data[@"sign"];
    BOOL success = [WXApi sendReq:req];
    callback(@[success ? [NSNull null] : INVOKE_FAILED]);
}

-(void)shareToMiniProgramWithData:(NSDictionary *)aData{
    
}

- (void)shareToWeixinWithData:(NSDictionary *)aData
                   thumbImage:(UIImage *)aThumbImage
                        scene:(int)aScene
                     callBack:(RCTResponseSenderBlock)callback
{
    NSString *type = aData[RCTWXShareType];

    if ([type isEqualToString:RCTWXShareTypeText]) {
        NSString *text = aData[RCTWXShareDescription];
        [self shareToWeixinWithTextMessage:aScene Text:text callBack:callback];
    } else {
        NSString * title = aData[RCTWXShareTitle];
        NSString * description = aData[RCTWXShareDescription];
        NSString * mediaTagName = aData[@"mediaTagName"];
        NSString * messageAction = aData[@"messageAction"];
        NSString * messageExt = aData[@"messageExt"];

        if (type.length <= 0 || [type isEqualToString:RCTWXShareTypeNews]) {
            NSString * webpageUrl = aData[RCTWXShareWebpageUrl];
            if (webpageUrl.length <= 0) {
                callback(@[@"webpageUrl required"]);
                return;
            }

            WXWebpageObject* webpageObject = [WXWebpageObject object];
            webpageObject.webpageUrl = webpageUrl;

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:webpageObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeAudio]) {
            WXMusicObject *musicObject = [WXMusicObject new];
            musicObject.musicUrl = aData[@"musicUrl"];
            musicObject.musicLowBandUrl = aData[@"musicLowBandUrl"];
            musicObject.musicDataUrl = aData[@"musicDataUrl"];
            musicObject.musicLowBandDataUrl = aData[@"musicLowBandDataUrl"];

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:musicObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeVideo]) {
            WXVideoObject *videoObject = [WXVideoObject new];
            videoObject.videoUrl = aData[@"videoUrl"];
            videoObject.videoLowBandUrl = aData[@"videoLowBandUrl"];

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:videoObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeImageUrl] ||
                   [type isEqualToString:RCTWXShareTypeImageFile] ||
                   [type isEqualToString:RCTWXShareTypeImageResource]) {
            NSURL *url = [NSURL URLWithString:aData[RCTWXShareImageUrl]];
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
            [self.bridge.imageLoader loadImageWithURLRequest:imageRequest callback:^(NSError *error, UIImage *image) {
                if (image == nil){
                    callback(@[@"fail to load image resource"]);
                } else {
                    WXImageObject *imageObject = [WXImageObject object];
                    imageObject.imageData = UIImagePNGRepresentation(image);
                    
                    [self shareToWeixinWithMediaMessage:aScene
                                                  Title:title
                                            Description:description
                                                 Object:imageObject
                                             MessageExt:messageExt
                                          MessageAction:messageAction
                                             ThumbImage:aThumbImage
                                               MediaTag:mediaTagName
                                               callBack:callback];
                    
                }
            }];
        } else if ([type isEqualToString:RCTWXShareTypeFile]) {
            NSString * filePath = aData[@"filePath"];
            NSString * fileExtension = aData[@"fileExtension"];

            WXFileObject *fileObject = [WXFileObject object];
            fileObject.fileData = [NSData dataWithContentsOfFile:filePath];
            fileObject.fileExtension = fileExtension;

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:fileObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else {
            callback(@[@"message type unsupported"]);
        }
    }
}


- (void)shareToWeixinWithData:(NSDictionary *)aData scene:(int)aScene callback:(RCTResponseSenderBlock)aCallBack
{
    NSString *imageUrl = aData[RCTWXShareTypeThumbImageUrl];
    if (imageUrl.length && _bridge.imageLoader) {
        NSURL *url = [NSURL URLWithString:imageUrl];
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
        [_bridge.imageLoader loadImageWithURLRequest:imageRequest size:CGSizeMake(100, 100) scale:1 clipped:FALSE resizeMode:RCTResizeModeStretch progressBlock:nil partialLoadBlock:nil
            completionBlock:^(NSError *error, UIImage *image) {
            [self shareToWeixinWithData:aData thumbImage:image scene:aScene callBack:aCallBack];
        }];
    } else {
        [self shareToWeixinWithData:aData thumbImage:nil scene:aScene callBack:aCallBack];
    }

}

- (void)shareToWeixinWithTextMessage:(int)aScene
                                Text:(NSString *)text
                                callBack:(RCTResponseSenderBlock)callback
{
    SendMessageToWXReq* req = [SendMessageToWXReq new];
    req.bText = YES;
    req.scene = aScene;
    req.text = text;

    BOOL success = [WXApi sendReq:req];
    callback(@[success ? [NSNull null] : INVOKE_FAILED]);
}

- (void)shareToWeixinWithMediaMessage:(int)aScene
                                Title:(NSString *)title
                          Description:(NSString *)description
                               Object:(id)mediaObject
                           MessageExt:(NSString *)messageExt
                        MessageAction:(NSString *)action
                           ThumbImage:(UIImage *)thumbImage
                             MediaTag:(NSString *)tagName
                             callBack:(RCTResponseSenderBlock)callback
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    message.mediaObject = mediaObject;
    message.messageExt = messageExt;
    message.messageAction = action;
    message.mediaTagName = tagName;
    [message setThumbImage:thumbImage];

    SendMessageToWXReq* req = [SendMessageToWXReq new];
    req.bText = NO;
    req.scene = aScene;
    req.message = message;

    BOOL success = [WXApi sendReq:req];
    callback(@[success ? [NSNull null] : INVOKE_FAILED]);
}

#pragma mark - wx callback

-(void) onReq:(BaseReq*)req
{
    // TODO(Yorkie)
}

-(void) onResp:(BaseResp*)resp
{
	if([resp isKindOfClass:[SendMessageToWXResp class]])
	{
	    SendMessageToWXResp *r = (SendMessageToWXResp *)resp;
    
	    NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
	    body[@"errStr"] = r.errStr;
	    body[@"lang"] = r.lang;
	    body[@"country"] =r.country;
	    body[@"type"] = @"SendMessageToWX.Resp";
	    [self.bridge.eventDispatcher sendDeviceEventWithName:RCTWXEventName body:body];
	} else if ([resp isKindOfClass:[SendAuthResp class]]) {
	    SendAuthResp *r = (SendAuthResp *)resp;
	    NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
	    body[@"errStr"] = r.errStr;
	    body[@"state"] = r.state;
	    body[@"lang"] = r.lang;
	    body[@"country"] =r.country;
	    body[@"type"] = @"SendAuth.Resp";
    
	    if (resp.errCode == WXSuccess)
	    {
	        [body addEntriesFromDictionary:@{@"appid":self.appId, @"code" :r.code}];
	        [self.bridge.eventDispatcher sendDeviceEventWithName:RCTWXEventName body:body];
	    }
	    else {
	        [self.bridge.eventDispatcher sendDeviceEventWithName:RCTWXEventName body:body];
	    }
	} else if ([resp isKindOfClass:[PayResp class]]) {
	        PayResp *r = (PayResp *)resp;
	        NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
	        body[@"errStr"] = r.errStr;
	        body[@"type"] = @(r.type);
	        body[@"returnKey"] =r.returnKey;
	        body[@"type"] = @"PayReq.Resp";
	        [self.bridge.eventDispatcher sendDeviceEventWithName:RCTWXEventName body:body];
    	}
}

@end
