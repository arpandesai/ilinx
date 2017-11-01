//  LocalSourceViewControllerIPad.h
//  iLinX
//
//  Created by James Stamp on 29/07/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioSubViewControllerIPad.h"
#import "ListDataSource.h"
#import "NLSourceLocal.h"


@class NLSourceList;

@interface LocalSourceViewControllerIPad :  AudioSubViewControllerIPad <ListDataDelegate, NLSourceLocalDelegate, UIWebViewDelegate>
{
@private
  NLSourceLocal  *_localSource;
  NSArray *_presetButtons;
  id _changeHandler;
  IBOutlet UIView     *_viewBackGroundNaim;
  IBOutlet UIView     *_viewBackGroundLocal;
  IBOutlet UIButton    *_button1Off;
  IBOutlet UIButton    *_button1On;
  IBOutlet UIButton    *_button2Off;
  IBOutlet UIButton    *_button2On;
  IBOutlet UIButton    *_button3Off;
  IBOutlet UIButton    *_button3On;
  IBOutlet UIButton    *_button4Off;
  IBOutlet UIButton    *_button4On;
  IBOutlet UIButton    *_button5Off;
  IBOutlet UIButton    *_button5On;
  IBOutlet UIButton    *_button6Off;
  IBOutlet UIButton    *_button6On;
  IBOutlet UILabel     *_sourceTitle;
}

- (IBAction) buttonPushed: (UIView *) button;

@end
 