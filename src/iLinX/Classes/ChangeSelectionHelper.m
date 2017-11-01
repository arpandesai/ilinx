//
//  ChangeSelectionHelper.m
//  iLinX
//
//  Created by mcf on 13/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "ChangeSelectionHelper.h"
#import "SelectItemViewController.h"
#import "StandardPalette.h"


@implementation ChangeSelectionHelper

+ (UIToolbar *) addToolbarToView: (UIView *) view withTitle: (NSString *) title1 target: (id) target1 selector: (SEL) selector1
                title: (NSString *) title2 target: (id) target2 selector: (SEL) selector2
{
  UIToolbar *toolbar = [UIToolbar new];
  
  // create the UIToolbar at the top of the view controller
  [StandardPalette setTintForToolbar: toolbar];
  
  // size up the toolbar and set its frame
  [toolbar sizeToFit];
  CGFloat toolbarHeight = [toolbar frame].size.height;
  CGRect mainViewBounds = view.bounds;
  
  [toolbar setFrame:
   CGRectMake( CGRectGetMinX( mainViewBounds ), CGRectGetMinY( mainViewBounds ) - 1,
              CGRectGetWidth( mainViewBounds ), toolbarHeight)];
  
  [view addSubview: toolbar];
  
  // create the location and source selection buttons
  UIBarButtonItem *item1;
  UIBarButtonItem *item2;
  
  if (title1 == nil)
    item1 = nil;
  else
    item1 = [[UIBarButtonItem alloc] initWithTitle: title1 style: UIBarButtonItemStyleBordered
                                            target: target1 action: selector1];
  if (title2 == nil)
    item2 = nil;
  else
    item2 = [[UIBarButtonItem alloc] initWithTitle: title2 style: UIBarButtonItemStyleBordered
                                            target: target2 action: selector2];
  
  NSArray *items = [NSArray arrayWithObjects: item1, item2, nil];
  [toolbar setItems: items animated: NO];
  
  [item1 release];
  [item2 release];
  [toolbar release];
  
  return toolbar;
}

+ (void) showDialogOver: (UINavigationController *) currentNavigationController
           withListData: (id<ListDataSource>) dataSource
{
  [ChangeSelectionHelper showDialogOver: currentNavigationController withListData: dataSource headerView: nil];
}

+ (void) showDialogOver: (UINavigationController *) currentNavigationController
           withListData: (id<ListDataSource>) dataSource headerView: (UIView *) view
{
  UIViewController *controller = [[SelectItemViewController alloc]
                                  initWithTitle: [dataSource listTitle] 
                                  dataSource: dataSource headerView: view
                                  overController: currentNavigationController];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: controller];

  if (currentNavigationController.navigationBar.barStyle == UIBarStyleDefault)
  {
    [StandardPalette setTintForNavigationBar: nav.navigationBar];
    nav.view.backgroundColor = [StandardPalette standardTintColour];
  }
  else
  {
    nav.navigationBar.barStyle = currentNavigationController.navigationBar.barStyle;
    nav.navigationBar.tintColor = currentNavigationController.navigationBar.tintColor;
    nav.view.backgroundColor = [UIColor whiteColor];
  }

  [currentNavigationController presentModalViewController: nav animated: YES];
  [controller release];
  [nav release];
}

@end
