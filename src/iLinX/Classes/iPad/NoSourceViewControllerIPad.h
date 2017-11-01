//
//  NoSourceViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 13/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioSubViewControllerIPad.h"
#import "ListDataSource.h"
#import "PagedScrollViewController.h"

@class NLSourceList;

@interface NoSourceViewControllerIPad :  AudioSubViewControllerIPad <PagedScrollViewDelegate, ListDataDelegate>
{
@private
  IBOutlet PagedScrollViewController *_pageController;
  IBOutlet UITableView *_tableView;
  IBOutlet UILabel *_titleLabel;

  NLSourceList *_sources;
  NSIndexPath *_selectedIndex;
  NSUInteger _buttonCount;
  NSUInteger _buttonsOnPage;
  NSUInteger _numberOfColumns;
  BOOL _flash;
}

@end