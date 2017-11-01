//
//  PagedScrollView.h
//  iLinX
//
//  Created by mcf on 12/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PagedScrollView : UIScrollView
{
@private
  UIPageControl *_pager;
}

@property (nonatomic, assign) IBOutlet UIPageControl *pager;

- (IBAction) pageChanged: (id) sender;

@end
