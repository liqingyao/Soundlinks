//
//  SLNetwork.h
//  microhoneTest
//
//  Created by LiQingyao on 16/2/24.
//  Copyright © 2016年 Pheroant. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^Completion)(NSData *data, NSError *error);

@interface SLNetwork : NSObject

+ (void)getCoinContentsWithCode:(int)code
                          appid:(NSString *)appid
                        eventid:(NSString *)eventid
           andCompletionHandler:(Completion)completion;

@end
