//
//  do_VideoView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_VideoView_IView <NSObject>

@required
//属性方法
- (void)change_path:(NSString *)newValue;

//同步或异步方法
- (void)pause:(NSArray *)parms;
- (void)play:(NSArray *)parms;
- (void)resume:(NSArray *)parms;
- (void)stop:(NSArray *)parms;
- (void)isPlaying:(NSArray *)parms;
- (void)getCurrentPosition:(NSArray *)parms;
- (void)expand:(NSArray *)parms;
- (void)setControlVisible:(NSArray *)parms;
- (void)getFrameAsImage:(NSArray *)parms;
- (void)getFrameAsBitmap:(NSArray *)parms;
@end