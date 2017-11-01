//
//  NLSourceIROnly.h
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ListDataSource.h"
#import "NLSource.h"

// Valid keys
#define SOURCE_IRONLY_KEY_STOP        1
#define SOURCE_IRONLY_KEY_PLAY        2
#define SOURCE_IRONLY_KEY_PAUSE       3
#define SOURCE_IRONLY_KEY_PLAY_PAUSE  4
#define SOURCE_IRONLY_KEY_PREV        5
#define SOURCE_IRONLY_KEY_NEXT        6
#define SOURCE_IRONLY_KEY_REWIND      7
#define SOURCE_IRONLY_KEY_FFWD        8
#define SOURCE_IRONLY_KEY_DISC_PREV   9
#define SOURCE_IRONLY_KEY_DISC_NEXT   10
#define SOURCE_IRONLY_KEY_REPEAT      11
#define SOURCE_IRONLY_KEY_SHUFFLE     12
#define SOURCE_IRONLY_KEY_F1          13
#define SOURCE_IRONLY_KEY_F2          14
#define SOURCE_IRONLY_KEY_1           15
#define SOURCE_IRONLY_KEY_2           16
#define SOURCE_IRONLY_KEY_3           17
#define SOURCE_IRONLY_KEY_4           18
#define SOURCE_IRONLY_KEY_5           19
#define SOURCE_IRONLY_KEY_6           20
#define SOURCE_IRONLY_KEY_7           21
#define SOURCE_IRONLY_KEY_8           22
#define SOURCE_IRONLY_KEY_9           23
#define SOURCE_IRONLY_KEY_0           24
#define SOURCE_IRONLY_KEY_10_PLUS     25
#define SOURCE_IRONLY_KEY_100_PLUS    26
#define SOURCE_IRONLY_KEY_CLEAR       27
#define SOURCE_IRONLY_KEY_ENTER       28
#define SOURCE_IRONLY_KEY_MENU        29
#define SOURCE_IRONLY_KEY_TOPMENU     30
#define SOURCE_IRONLY_KEY_UP          31
#define SOURCE_IRONLY_KEY_DOWN        32
#define SOURCE_IRONLY_KEY_LEFT        33
#define SOURCE_IRONLY_KEY_RIGHT       34
#define SOURCE_IRONLY_KEY_SELECT      35
#define SOURCE_IRONLY_KEY_RETURN      36
#define SOURCE_IRONLY_KEY_SETUP       37
#define SOURCE_IRONLY_KEY_MODE        38
#define SOURCE_IRONLY_KEY_DISPLAY     39
#define SOURCE_IRONLY_KEY_EJECT       40
#define SOURCE_IRONLY_KEY_DVDAUDIO    41
#define SOURCE_IRONLY_KEY_ANGLE       42
#define SOURCE_IRONLY_KEY_SUBTITLE    43
#define SOURCE_IRONLY_KEY_ZOOM        44
#define SOURCE_IRONLY_KEY_LANGUAGE    45
#define SOURCE_IRONLY_KEY_GUIDE       46
#define SOURCE_IRONLY_KEY_INFO        47
#define SOURCE_IRONLY_KEY_LIST        48
#define SOURCE_IRONLY_KEY_GO_BACK     49
#define SOURCE_IRONLY_KEY_RECORD      50
#define SOURCE_IRONLY_KEY_CHAN_UP     51
#define SOURCE_IRONLY_KEY_CHAN_DOWN   52
#define SOURCE_IRONLY_KEY_RED         53
#define SOURCE_IRONLY_KEY_GREEN       54
#define SOURCE_IRONLY_KEY_YELLOW      55
#define SOURCE_IRONLY_KEY_BLUE        56

@class NLSourceIROnly;
@class NLBrowseList;

#define SOURCE_IRONLY_PRESETS_CHANGED 0x0001

@protocol NLSourceIROnlyDelegate <NSObject>

- (void) irOnlySource: (NLSourceIROnly *) irOnlySource changed: (NSUInteger) changed;

@end

@interface NLSourceIROnly : NLSource <ListDataDelegate>
{
@private
  NSMutableSet *_sourceDelegates;
  NSString *_redText;
  NSString *_yellowText;
  NSString *_blueText;
  NSString *_greenText;
  NLBrowseList *_presets;
  BOOL _gotFirstPreset;
}

@property (readonly) NSString *redText;
@property (readonly) NSString *yellowText;
@property (readonly) NSString *blueText;
@property (readonly) NSString *greenText;
@property (readonly) NLBrowseList *presets;

- (void) sendKey: (NSUInteger) keyId;
- (void) ifNoFeedbackSetCaption: (NSString *) caption;
- (void) addDelegate: (id<NLSourceIROnlyDelegate>) delegate;
- (void) removeDelegate: (id<NLSourceIROnlyDelegate>) delegate;

@end
