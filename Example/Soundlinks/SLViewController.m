//
//  SLViewController.m
//  Soundlinks
//
//  Created by liqingyao on 02/25/2016.
//  Copyright (c) 2016 liqingyao. All rights reserved.
//

#import "SLViewController.h"
#import "Soundlinks.h"

@interface SLViewController () <SoundlinksDelegate>

@end

@implementation SLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start Soundlinks by calling startListeningContents
    [Soundlinks setDelegate:self];
    [Soundlinks enable];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Stop Soundlinks by call stopListeningContents
    [Soundlinks disable];
}

// Soundlinks callback when has listened some contents
// Contents are packaged into an array, use SLContent to parse each content
- (void)soundlinks:(Soundlinks *)soundlinks listenContents:(NSArray *)contentArray {
    for (SLContent *content in contentArray) {
        NSLog(@"Succeed Get Content: %@ \n %@ \n %@ \n", content.title, content.url, content.image);
    }
}

@end
