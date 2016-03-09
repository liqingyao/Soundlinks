# Soundlinks

[![CI Status](http://img.shields.io/travis/liqingyao/Soundlinks.svg?style=flat)](https://travis-ci.org/liqingyao/Soundlinks)
[![Version](https://img.shields.io/cocoapods/v/Soundlinks.svg?style=flat)](http://cocoapods.org/pods/Soundlinks)
[![License](https://img.shields.io/cocoapods/l/Soundlinks.svg?style=flat)](http://cocoapods.org/pods/Soundlinks)
[![Platform](https://img.shields.io/cocoapods/p/Soundlinks.svg?style=flat)](http://cocoapods.org/pods/Soundlinks)

## Features
Soundlinks provides basic APIs for parsing contents from audios which are carried inaudible information.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

#### Init Soundlinks

In `AppDelegate` init Soundlinks with Appid and Eventid.

```objectivec
#import "Soundlinks.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Init Soundlinks with AppID and EventId
    [Soundlinks setAppID:@"appid" andEventId:@"eventid"];

    return YES;
}
```

#### Start Soundlinks

In `ViewDidLoad` set delegate and start microphone to record audio.

```objectivec
#import "Soundlinks.h"

@interface SLViewController () <SoundlinksDelegate>

@end

@implementation SLViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set delegate and enable Soundlinks
    [Soundlinks setDelegate:self];
    [Soundlinks enable];
}
```

#### Stop Soundlinks

Stop microphone and no longer recording audio.

```objectivec
[Soundlinks disable];
```
#### Soundlinks Callback

When Soundlinks has listened some contents then callback is called. The returned contents are packaged into an array, use SLContent to parse each content.

```objectivec
- (void)soundlinks:(Soundlinks *)soundlinks listenContents:(NSArray *)contentArray {
    for (SLContent *content in contentArray) {
        NSLog(@"Succeed Get Content: %@ \n %@ \n %@ \n", content.title, content.url, content.image);
        // To do with the content
    }
}
```

#### Do not Forget

Add **App Transport Security Setting** in `Info.plist`, and set **Allow Arbitrary Loads** to **YES**.

## Build Requirements

**iOS**

- 7.0+

## Frameworks

**iOS**

- Foundation

- AudioToolbox

- AVFoundation

- UIKit

- QuartzCore

## Installation

Soundlinks is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Soundlinks'
```

## License

Soundlinks is available under the MIT license. See the LICENSE file for more info.
