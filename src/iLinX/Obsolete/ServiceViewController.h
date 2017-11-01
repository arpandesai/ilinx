//
//  ServiceViewController.h
//  NetStreams
//
//  Created by mcf on 29/12/2008.
//  Copyright 2008 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ServiceViewController : UITableViewController
{
  NSArray *serviceList;
}

@property (nonatomic, retain) NSArray *serviceList;

@end
