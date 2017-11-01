//
//  TintedTableViewDelegate.h
//  iLinX
//
//  Created by mcf on 10/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TintedTableViewDelegate : NSObject <UITableViewDelegate>
{
@private
  UITableView *_tableView;
  UIView *_backdrop;
  UIColor *_backdropTint;
  UIColor *_headerTextColour;
  UIColor *_headerShadowColour;
  UIColor *_headerTint;
}

@property (nonatomic, assign) UITableView *tableView;
@property (nonatomic, retain) UIColor *backdropTint;
@property (nonatomic, retain) UIColor *headerTextColour;
@property (nonatomic, retain) UIColor *headerShadowColour;
@property (nonatomic, retain) UIColor *headerTint;

- (void) viewDidLoad;
- (void) viewWillAppear: (BOOL) animated;
- (void) viewDidDisappear: (BOOL) animated;

@end
