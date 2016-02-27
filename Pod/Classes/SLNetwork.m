//
//  SLNetwork.m
//  microhoneTest
//
//  Created by LiQingyao on 16/2/24.
//  Copyright © 2016年 Pheroant. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLNetwork.h"

#define URL_HOST @"http://api.soundlinks.net/v1"
#define RESOURCE_COIN @"/getcoins"
#define PROGRAM_ID @"qingting-huodong"
#define PLATFORM @"ios"
#define APP_ID @"qingting2016"
#define IP @""

#define HTTP_Timeout 10

#ifdef DEBUG
#define DebugLog( s, ... ) NSLog( @"<%p %@:%d (%@)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  NSStringFromSelector(_cmd), [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DebugLog( s, ... )
#endif

@implementation SLNetwork

+ (void)getCoinContentsWithCode:(int)code
                          appid:(NSString *)appid
                        eventid:(NSString *)eventid
           andCompletionHandler:(Completion)completion {
    
    NSString *action = @"GET";
    NSString *type = @"application/json";
    NSString *timestamp = [self timestamp];
    NSString *macaddress = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    //NSString *nonce = [@(arc4random() % 100000000000000) stringValue];
    
    //URL setup
    NSMutableString *urlString = [NSMutableString stringWithString:URL_HOST];
    [urlString appendString:RESOURCE_COIN];
    [urlString appendString:@"?"];
    [urlString appendString:[NSString stringWithFormat:@"code=%d", code]];
    [urlString appendString:@"&"];
    [urlString appendString:[NSString stringWithFormat:@"pid=%@", eventid]];
    [urlString appendString:@"&"];
    [urlString appendString:[NSString stringWithFormat:@"pl=%@", PLATFORM]];
    [urlString appendString:@"&"];
    [urlString appendString:[NSString stringWithFormat:@"aid=%@", appid]];
    [urlString appendString:@"&"];
    [urlString appendString:[NSString stringWithFormat:@"i=%@", IP]];
    [urlString appendString:@"&"];
    [urlString appendString:[NSString stringWithFormat:@"m=%@", macaddress]];
    [urlString appendString:@"&"];
    [urlString appendString:[NSString stringWithFormat:@"t=%@", timestamp]];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    //DebugLog(@"url: %@", url);
    
    //Request init
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //Request header setup
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
//    [request setValue:[MyUtilit md5_base64:queryString] forHTTPHeaderField:@"Content-MD5"];
//    [request setValue:timestamp forHTTPHeaderField:@"UTC-Timestamp"];
//    [request setValue:nonce forHTTPHeaderField:@"Nonce"];
//    [request setValue:[[NSUserDefaults standardUserDefaults] objectForKey:API_KEY] forHTTPHeaderField:@"Api-key"];
//    [request setValue:[MyUtilit authHeaderContentWithAction:action Type:type PostBody:queryString Timestamp:timestamp Nonce:nonce Resource:resource] forHTTPHeaderField:@"Authorization"];
    
    //Request option setup
    [request setHTTPMethod:action];
    [request setTimeoutInterval:HTTP_Timeout];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:(id<NSURLSessionDelegate>)self delegateQueue:nil];
    NSURLSessionDataTask *getDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (data) {
            //NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //DebugLog(@"GetSetting response: %@", jsonString);
            if (completion) {
                completion(data,nil);
            }
        }
        if (error) {
            //DebugLog(@"Error URL Request: %@", error);
            if (completion) {
                completion(nil,error);
            }
        }
    }];
    [getDataTask resume];
}

+ (NSString *)timestamp {
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyMMddHHmmss"];
//    NSString *timestamp = [dateFormatter stringFromDate:[NSDate date]];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString *timestamp = [NSString stringWithFormat:@"%lld", (long long int)timeInterval];
    //DebugLog(@"timestamp: %@", timestamp);
    return timestamp;
}

@end
