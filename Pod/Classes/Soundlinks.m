//
//  Soundlinks.m
//  microhoneTest
//
//  Created by LiQingyao on 16/2/24.
//  Copyright © 2016年 Pheroant. All rights reserved.
//

#import "Soundlinks.h"
#import "SLMicrophone.h"
#import "SLAlgorithm.h"
#import "SLNetwork.h"

#ifdef DEBUG
#define DebugLog( s, ... ) NSLog( @"<%p %@:%d (%@)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  NSStringFromSelector(_cmd), [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DebugLog( s, ... )
#endif

@implementation SLContent

@end

@interface Soundlinks() <SLMicrophoneDelegate>

@property (strong,nonatomic) SLMicrophone *microphone;
@property (strong,nonatomic) NSString *appid;
@property (strong,nonatomic) NSString *eventid;

+ (instancetype)sharedInstance;

@end

@implementation Soundlinks

static int bufferCounter = 0;

+ (Soundlinks *)sharedInstance {
    
    static dispatch_once_t onceToken;
    static Soundlinks *soundlinks;
    
    dispatch_once(&onceToken, ^{
        soundlinks = [[Soundlinks alloc] init];
    });
    return soundlinks;
}

+ (void)setAppID:(NSString *)appid andEventId:(NSString *)eventid {
    
    [Soundlinks sharedInstance].appid = appid;
    [Soundlinks sharedInstance].eventid = eventid;
}

+ (void)enable {
    
    [[Soundlinks sharedInstance].microphone startFetchingAudio];
}

+ (void)disable {
    
    [[Soundlinks sharedInstance].microphone stopFetchingAudio];
}

- (id)init {
    
    self = [super init];
    
    if(self) {
        
        // Active an audio session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error;
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        [session setActive:YES error:&error];
        
        // Init an instance of SLMicrophone and set delegate
        self.microphone = [[SLMicrophone alloc] initWithMicrophoneDelegate:self];
    }
    
    return self;
}

- (void)    microphone:(SLMicrophone *)microphone
      hasAudioReceived:(float **)buffer
        withBufferSize:(UInt32)bufferSize
  withNumberOfChannels:(UInt32)numberOfChannels {
    
    if (bufferCounter == 0) {
        [SLAlgorithm initAlgorithmWithBufferSize:bufferSize];
    }
    
    int code = [SLAlgorithm detectedDataWithBuffer:buffer[0] andBufferSize:bufferSize];
    
    if (code) {
        
        [SLNetwork getCoinContentsWithCode:code appid:self.appid eventid:self.eventid andCompletionHandler:^(NSData *data, NSError *error) {
            
            if (data) {
                
                NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                //DebugLog(@"jsonDic: %@", jsonDic);
                NSArray *resultArray = (NSArray *)[jsonDic objectForKey:@"result"];
                
                if (!jsonDic) {
                    DebugLog(@"Error JSON Parse");
                } else if (resultArray) {
                    DebugLog(@"Succeed Get Content: %@", resultArray);
                    
                    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
                    
                    for (NSDictionary *resultDic in resultArray) {
                        DebugLog(@"Succeed Get resultDic: %@", resultDic);
                        
                        SLContent *content = [[SLContent alloc] init];
                        if ([resultDic objectForKey:@"name"]) {
                            content.title = [resultDic objectForKey:@"name"];
                        }
                        if ([resultDic objectForKey:@"url"]) {
                            content.url = [resultDic valueForKey:@"url"];
                        }
                        if ([resultDic objectForKey:@"image"]) {
                            content.image = [resultDic valueForKey:@"image"];
                        }
                        [contentArray addObject:content];
                    }

                    if ([self.delegate respondsToSelector:@selector(soundlinks:listenContents:)]) {
                        [self.delegate soundlinks:self listenContents:[contentArray copy]];
                    }
                    
                } else {
                    DebugLog(@"Error JSON No Contrnt Return");
                }
                
            } if (error) {
                DebugLog(@"Error URL Request: %@", error.localizedDescription);
            }
        }];
    }
    
    bufferCounter = 1;
    //dispatch_async(dispatch_get_main_queue(), ^{
    //});
}


@end
