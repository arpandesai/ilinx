//
//  TintedTableViewController.h
//  iLinX
//
//  Created by mcf on 07/05/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TintedTableViewDelegate;

@interface TintedTableViewController : 
#if DOES_NOT_INHERIT_FROM_UITABLEVIEWCONTROLLER
  UIViewController <UITableViewDelegate, UITableViewDataSource>
#else
  UITableViewController
#endif
{
@private
  TintedTableViewDelegate *_tintHandler;
#if DOES_NOT_INHERIT_FROM_UITABLEVIEWCONTROLLER
  UITableViewStyle _tableStyle;
  UITableView *_tableView;
#endif
@protected
  NSUInteger _paletteVersion;
}

#if DOES_NOT_INHERIT_FROM_UITABLEVIEWCONTROLLER
@property (assign) UITableViewStyle style;
@property (nonatomic, retain) UITableView *tableView;
#endif
@property (nonatomic, retain) UIColor *backdropTint;
@property (nonatomic, retain) UIColor *headerTextColour;
@property (nonatomic, retain) UIColor *headerShadowColour;
@property (nonatomic, retain) UIColor *headerTint;

- (id) initWithStyle: (UITableViewStyle) style;
- (void) refreshPalette;

@end
