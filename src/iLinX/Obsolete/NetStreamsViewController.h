//
//  NetStreamsViewController.h
//  NetStreams
//
//  Created by mcf on 19/12/2008.
//  Copyright Micropraxis Ltd 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>

#import "NetStreamsComms.h"

@interface NetStreamsViewController : UIViewController <UIWebViewDelegate, NetStreamsCommsDelegate>
{
@private
  NetStreamsComms *_netStreamsComms;
  UIWebView *_webView;
  NSString *_initialUrl;
  NSString *_multicastIp;
  uint16_t _multicastPort;
  BOOL _loadingMessageDone;
  CFURLRef _soundFileURLRef;
  SystemSoundID _soundFileObject;
  BOOL _soundEnabled;  
}

@property (nonatomic, retain) NetStreamsComms *netStreamsComms;
@property (readwrite) CFURLRef soundFileURLRef;
@property (readonly) SystemSoundID soundFileObject;

@end

