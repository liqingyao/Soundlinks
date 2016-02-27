//
//  Soundlinks.h
//
//  Created by LiQingyao on 16/2/24.
//  Copyright © 2016年 Pheroant. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLContent : NSObject

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *image;
@property (nonatomic, retain) NSString *url;

@end

@class Soundlinks;

@protocol SoundlinksDelegate <NSObject>

- (void)soundlinks:(Soundlinks *)soundlinks listenContents:(NSArray *)contentArray;

@end

@interface Soundlinks : NSObject

@property (nonatomic, weak) id<SoundlinksDelegate> delegate;

- (Soundlinks *)initWithAppid:(NSString *)appid eventid:(NSString *)eventid andDelegate:(id<SoundlinksDelegate>)delegate;

- (void)startListeningContents;

- (void)stopListeningContents;

@end
