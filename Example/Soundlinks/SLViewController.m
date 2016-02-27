//
//  SLViewController.m
//  Soundlinks
//
//  Created by liqingyao on 02/25/2016.
//  Copyright (c) 2016 liqingyao. All rights reserved.
//

#import "SLViewController.h"
#import <Soundlinks.h>

@interface SLViewController () <SoundlinksDelegate>

@property (strong,nonatomic) Soundlinks *soundlinks;

@end

@implementation SLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // Init Soundlinks instance with appid, eventid
    // Set delegate
    self.soundlinks = [[Soundlinks alloc] initWithAppid:@"qingting2016" eventid:@"qingting-huodong" andDelegate:self];
    
    // Start Soundlinks by calling startListeningContents
    [self.soundlinks startListeningContents];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Stop Soundlinks by call stopListeningContents
    [self.soundlinks stopListeningContents];
}

// Soundlinks callback when has listened some contents
// Contents are packaged into an array, use SLContent to parse each content
- (void)soundlinks:(Soundlinks *)soundlinks listenContents:(NSArray *)contentArray {
    for (SLContent *content in contentArray) {
        NSLog(@"Succeed Get Content: %@ \n %@ \n %@ \n", content.title, content.url, content.image);
    }
}

@end
