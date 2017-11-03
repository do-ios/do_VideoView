//
//  do_VideoView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "do_VideoView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doJsonHelper.h"
#import "doIOHelper.h"
#import "doIApp.h"
#import "doIPage.h"
#import "doIDataFS.h"
#import "doIDataSource.h"
#import "doIBitmap.h"

@interface do_VideoView_UIView()
@property (nonatomic,strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic,strong) UIImageView *thumbImageView;
@end

@implementation do_VideoView_UIView
{
    NSURL *_url;
    NSTimeInterval _initialPlaybackTime;
    
   __block BOOL _isPlay;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    [self addSubview:self.moviePlayer.view];
    [self addSubview:self.thumbImageView];
    [self addNotification];
    
    _isPlay = NO;
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.moviePlayer stop];
    self.moviePlayer = nil;
    _url = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    self.thumbImageView.frame = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_path:(NSString *)newValue
{
    //自己的代码实现
    //"支持data://、source://和网络地址"
    _url = [self getUrl:newValue];
    if (_moviePlayer) {
        if (_moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
            return;
        }
    }
    [_moviePlayer stop];
    [self thumbnailImageRequest:0 :nil :nil :-1 :nil];
}

#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)pause:(NSArray *)parms
{
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    [self.moviePlayer pause];
    int currentTime = round(self.moviePlayer.currentPlaybackTime);
    [_invokeResult SetResultInteger:currentTime*1000];
}
- (void)play:(NSArray *)parms
{
    self.thumbImageView.hidden = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.moviePlayer stop];
        
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        _initialPlaybackTime = [doJsonHelper GetOneInteger:_dictParas :@"point" :0]/1000;
        
        if (_url) {
            if ([_url.host isEqualToString:@"http"]) {
                self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
            }
            else
            {
                self.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
            }
            self.moviePlayer.contentURL = _url;
        }
        _isPlay = YES;
        [self.thumbImageView removeFromSuperview];
        self.moviePlayer.initialPlaybackTime = _initialPlaybackTime;
        [self.moviePlayer play];

    });
    
}
- (void)resume:(NSArray *)parms
{
    if (self.moviePlayer.playbackState==MPMoviePlaybackStateStopped) {
        return;
    }
    [self.moviePlayer play];
}
- (void)stop:(NSArray *)parms
{
    [self.moviePlayer stop];
    [self addSubview:self.thumbImageView];
}
- (void)isPlaying:(NSArray *)parms
{
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    BOOL isPlay = NO;
    if (_moviePlayer) {
        if (_moviePlayer.playbackState!=MPMoviePlaybackStateStopped && _moviePlayer.playbackState!=MPMoviePlaybackStateInterrupted && _moviePlayer.playbackState!=MPMoviePlaybackStatePaused) {
            isPlay = YES;
        }
    }
    [_invokeResult SetResultBoolean:isPlay];
}
- (void)getCurrentPosition:(NSArray *)parms
{
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    
    int currentTime = round(self.moviePlayer.currentPlaybackTime);

    [_invokeResult SetResultText:[@(currentTime*1000) stringValue]];
}
- (void)expand:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
//    //参数字典_dictParas
//    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
//    //自己的代码实现
//    
//    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    BOOL isFullScreen = [doJsonHelper GetOneBoolean:_dictParas :@"isFullScreen" :NO];
    [self.moviePlayer setFullscreen:isFullScreen animated:YES];
}
- (void)setControlVisible:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
//    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    BOOL visible = [doJsonHelper GetOneBoolean:_dictParas :@"visible" :YES];
    if (!visible) {
       self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    }
    else
    {
        self.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    }
    
//    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

- (void) addNotification
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerPlaybackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [notificationCenter addObserverForName:MPMoviePlayerLoadStateDidChangeNotification
                       object:nil queue:[NSOperationQueue mainQueue]
                   usingBlock:^(NSNotification *note) {
                       if (_moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
                           if (_isPlay) {
                               _isPlay = NO;
                               [_moviePlayer pause];
                               [_moviePlayer setCurrentPlaybackTime:(_initialPlaybackTime+1)];
                               [_moviePlayer play];
                               return ;
                           }
                       }
                   }];
}
#pragma -mark -
#pragma -mark 获得视频第一帧
/**
 *  截取指定时间的视频缩略图
 *
 *  @param timeBySecond 时间点
 */
-(void)thumbnailImageRequest:(CGFloat )timeBySecond :(id<doIScriptEngine>)scriptEngine :(NSString *)callbackName :(int)type :(NSDictionary *)info{
    
    if (!_url) {
        return;
    }
    
    if (type>0) {
        if ([_url.scheme hasPrefix:@"http"]) {
            return;
        }
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_url options:nil];
        NSParameterAssert(asset);
        AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        assetImageGenerator.appliesPreferredTrackTransform = YES;
        assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
        
        CGImageRef thumbnailImageRef = NULL;
        CFTimeInterval thumbnailImageTime = timeBySecond/1000*60;
        NSError *thumbnailImageGenerationError = nil;
        @try {
            thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&thumbnailImageGenerationError];
        } @catch (NSException *exception) {
            
        }
        UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
        
        
        if (type<0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _thumbImageView.hidden = NO;
                _thumbImageView.image = thumbnailImage;
            });
            return ;
        }

        if (type==1) {
            NSString *format = [doJsonHelper GetOneText:info :@"format" :@"JPEG"];
            NSInteger quality = [doJsonHelper GetOneInteger:info :@"quality" :100];
            NSString *outPath = [doJsonHelper GetOneText:info :@"outPath" :@""];
            NSString *pathReturn = [doJsonHelper GetOneText:info :@"pathReturn" :@""];
            NSData *imageData = [NSData new];
            CGFloat percent = quality / 100.0;
            if(percent<=0) percent = .1;
            if(percent>1) percent = 1;
            if ([format isEqualToString:@"JPEG"]) {
                imageData = UIImageJPEGRepresentation(thumbnailImage, percent);
            }else
                imageData = UIImagePNGRepresentation(thumbnailImage);
            [doIOHelper WriteAllBytes:outPath :imageData];
            doInvokeResult *_invokeResult = [[doInvokeResult alloc]init];
            [_invokeResult SetResultText:pathReturn];
            [scriptEngine Callback:callbackName :_invokeResult];
        }else if (type==2){
            NSString *bitmapAddress = [doJsonHelper GetOneText:info :@"bitmap" :@""];
            doMultitonModule *_multitonModule = [doScriptEngineHelper ParseMultitonModule:scriptEngine :bitmapAddress];
            id<doIBitmap> bitmap = (id<doIBitmap>)_multitonModule;
            [bitmap setData:thumbnailImage];
            doInvokeResult *_invokeResult = [[doInvokeResult alloc]init];
            [scriptEngine Callback:callbackName :_invokeResult];
        }
    });
}

#pragma -mark 获得url
- (NSURL *)getUrl:(NSString *)urlStr
{
    if ([urlStr hasPrefix:@"http"]) {
        return [self getNetworkUrl:urlStr];
    }
    else
    {
        return [self getFileUrl:urlStr];
    }
}

- (NSURL *)getFileUrl:(NSString *)urlStr
{
    NSString * fileUrl = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :urlStr];
    NSURL *url = [NSURL fileURLWithPath:fileUrl];
    return url;
}
- (NSURL *)getNetworkUrl:(NSString *)urlStr;
{
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStr];
    return url;
}

- (MPMoviePlayerController *)moviePlayer
{
    if (!_moviePlayer) {
        _moviePlayer = [[MPMoviePlayerController alloc]init];
        _moviePlayer.view.frame = self.bounds;
        _moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _moviePlayer.view.frame = self.bounds;
    }
    return _moviePlayer;
}
/**
 *  播放完毕通知
 *
 *  @param notification notification description
 */
-(void)mediaPlayerPlaybackFinished:(NSNotification *)notification
{
    doInvokeResult *_invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *result = [userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if (MPMovieFinishReasonPlaybackEnded == result.integerValue) {
        [_invokeResult SetResultText:@"finished"];
        [_model.EventCenter FireEvent:@"finished" :_invokeResult];
    }
    else if (MPMovieFinishReasonPlaybackError ==result.integerValue) {
        [_invokeResult SetResultText:@"error"];
        [_model.EventCenter FireEvent:@"error" :_invokeResult];
    }
}

#pragma mark -
#pragma -mark getter方法
-(UIImageView *)thumbImageView
{
    if (!_thumbImageView) {
        _thumbImageView = [[UIImageView alloc]init];
        
    }
    return _thumbImageView;
}

- (void)getFrameAsImage:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    __block id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    __block NSString *_callbackName = [parms objectAtIndex:2];
    
    
    NSInteger time = [doJsonHelper GetOneInteger:_dictParas :@"time" :1000];
    NSString *format = [doJsonHelper GetOneText:_dictParas :@"format" :@"JPEG"];
    NSInteger quality = [doJsonHelper GetOneInteger:_dictParas :@"quality" :100];

    NSString *extension = @"jpg";
    if (![format isEqualToString:@"JPEG"]) {
        extension = @"png";
    }
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",[doUIModuleHelper stringWithUUID],extension];
    NSString *fileFullName = [_scritEngine CurrentApp].DataFS.RootPath;
    NSString *path = [NSString stringWithFormat:@"%@/temp/do_VideoView",fileFullName];
    NSString *defaultName = [NSString stringWithFormat:@"%@/%@",path,fileName];

    NSString *outPath = [doJsonHelper GetOneText:_dictParas :@"outPath" :@""];
    NSString *pathReturn = @"";
    outPath = [outPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (outPath.length == 0) {
        outPath = defaultName;
        pathReturn = [NSString stringWithFormat:@"data://temp/do_VideoView/%@",fileName];
    }else{
        if (![outPath hasPrefix:@"data://"]) {
            outPath = [NSString stringWithFormat:@"data://%@",outPath];
        }
        if ([outPath hasSuffix:@"/"]) {
            outPath = [NSString stringWithFormat:@"%@%@",outPath,fileName];
        }
        pathReturn = outPath;
        outPath = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :outPath];
    }
    NSString *p = [outPath substringWithRange:NSMakeRange(0, outPath.length-(outPath.lastPathComponent.length+1))];
    if(![doIOHelper ExistDirectory:p])
        [doIOHelper CreateDirectory:p];
    
    NSDictionary *dict = @{@"time":@(time),@"format":format,@"quality":@(quality),@"outPath":outPath,@"pathReturn":pathReturn};
    [self thumbnailImageRequest:time :_scritEngine :_callbackName :1 :dict];
}
- (void)getFrameAsBitmap:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    __block id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    __block NSString *_callbackName = [parms objectAtIndex:2];
    //自己的代码实现
    NSString *bitmapAddress = [doJsonHelper GetOneText:_dictParas :@"bitmap" :@""];
    NSInteger time = [doJsonHelper GetOneInteger:_dictParas :@"time" :1000];

    NSDictionary *dict = @{@"time":@(time),@"bitmap":bitmapAddress};
    [self thumbnailImageRequest:time :_scritEngine :_callbackName :2 :dict];
}
@end
