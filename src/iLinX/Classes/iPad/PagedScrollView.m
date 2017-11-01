//
//  PagedScrollView.m
//  iLinX
//
//  Created by mcf on 12/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "PagedScrollView.h"

@implementation PagedScrollView

@synthesize
  pager = _pager;

- (IBAction) pageChanged: (id) sender
{
  int page = _pager.currentPage; 
  
  // update the scroll view to the appropriate page
  CGRect frame = self.bounds;
  
  frame.origin.x = frame.size.width * page;
  frame.origin.y = 0;
  [self scrollRectToVisible: frame animated: YES];
}

- (void) setFrame: (CGRect) frame
{
  [super setFrame: frame];
  self.contentSize = CGSizeMake( self.frame.size.width * _pager.numberOfPages, self.frame.size.height );
}

@end
