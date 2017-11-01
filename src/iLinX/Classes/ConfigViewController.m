//
//  ConfigViewController.m
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ConfigViewController.h"
#import "ConfigRootController.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "ConfigOptionViewController.h"
#import "DeprecationHelper.h"
#import "ProfileListController.h"
#import "SettingAndValueCell.h"
#import "StandardPalette.h"

@interface ConfigViewController ()

- (void) donePressed;

@end


@implementation ConfigViewController

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target: self action: @selector(donePressed)];
  
  self.navigationItem.title = NSLocalizedString( @"Settings", @"Title of the main iLinX configuration settings view" );
  self.navigationItem.rightBarButtonItem = rightItem;
  [rightItem release];
  
  UIView *footer = [[UIView alloc] initWithFrame: CGRectZero];
  UILabel *explanation = [[UILabel alloc] initWithFrame: CGRectZero];
  UIColor *textColour = [StandardPalette tableGroupedHeaderTextColour];
  UIColor *shadowColour = [StandardPalette tableGroupedHeaderShadowColour];
    
  explanation.backgroundColor = [UIColor clearColor];
  explanation.text = NSLocalizedString( @"To change your connection, choose \"Current\" and then \"Edit\" to add or change details.",
                                       @"Explanation of how to change connection details in config view" );
  explanation.font = [UIFont boldSystemFontOfSize: [UIFont systemFontSize]];
  if (textColour == nil)
    textColour = [UIColor colorWithRed: 76.0/255 green: 86.0/255.0 blue: 108.0/255.0 alpha: 1.0];
  if (shadowColour == nil)
    shadowColour = [UIColor whiteColor];
  explanation.textColor = textColour;
  explanation.shadowColor = shadowColour;
  explanation.shadowOffset = CGSizeMake( 0, 1 );
  explanation.lineBreakMode = UILineBreakModeWordWrap;
  explanation.numberOfLines = 4;
  explanation.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  explanation.textAlignment = UITextAlignmentCenter;
  [explanation sizeToFit];
  footer.backgroundColor = [UIColor clearColor];
  footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  footer.autoresizesSubviews = YES;
  footer.frame = CGRectMake( 0, 0, self.tableView.bounds.size.width, [explanation.font lineSpacing] * 4 );
  explanation.frame = CGRectMake( 10, 0, self.tableView.bounds.size.width - 20, [explanation.font lineSpacing] * 4 );
  [footer addSubview: explanation];
  [explanation release];
  self.tableView.tableFooterView = footer;
  [footer release];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];

  [StandardPalette setTintForNavigationBar: self.navigationController.navigationBar];
  [self refreshPalette];
  if (_originalProfile == nil)
    _originalProfile = [[ConfigManager currentProfileData] mutableCopy];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
#if defined(IPAD_BUILD)
  // Overriden to allow any orientation.
  return YES;
#else
  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
#endif
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
  return 3;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  switch (section)
  {
    case 0:
      return NSLocalizedString( @"Profiles", @"Title of the profiles section in the iLinX settings view" );
    case 1:
      return NSLocalizedString( @"Wi-Fi", @"Title of the Wifi section in the iLinX settings view" );
    case 2:
    default:
      return NSLocalizedString( @"Version", @"Title of the version section in the iLinX settings view" );

  }
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section 
{
  if (section == 0)
    return 2;
  else
    return 1;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"Cell";
  SettingAndValueCell *cell = (SettingAndValueCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  
  if (cell == nil)
    cell = [[[SettingAndValueCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: CellIdentifier
                                                        table: tableView] autorelease];
  else 
    [cell refreshPaletteToVersion: _paletteVersion];
  
  switch (indexPath.section)
  {
    case 0:
      switch (indexPath.row)
      {
        case 0:
          cell.nameText = NSLocalizedString( @"Current", @"Title of the iLinX current profile setting" );
          cell.detailText = [[ConfigManager currentProfileData] name];
          break;
        case 1:
          cell.nameText = NSLocalizedString( @"Start Up", @"Title of the iLinX start-up profile setting" );
          cell.detailText = [ConfigManager currentStartupTypeName];
          break;
        default:
          break;
      }
      [cell setBorderTypeForIndex: indexPath.row totalItems: 2];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      break;
    case 1:
    {
      UISwitch *stayConnectedSwitch = [[UISwitch alloc] initWithFrame: CGRectZero];
      
      cell.nameText = NSLocalizedString( @"Stay On", @"Title of the WiFi persistent connection setting" );
      cell.detailText = @"";
      [cell setBorderTypeForIndex: 0 totalItems: 1];
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      [stayConnectedSwitch sizeToFit];
      stayConnectedSwitch.on = [ConfigManager stayConnected];
      [stayConnectedSwitch addTarget: self action: @selector(stayConnectedChanged:) 
                         forControlEvents: UIControlEventValueChanged];
      cell.accessoryView = stayConnectedSwitch;
      [stayConnectedSwitch release];
      break;
    }
    case 2:
      cell.nameText = NSLocalizedString( @"Version", @"Title of the iLinX version setting" );
      cell.detailText = [NSString stringWithFormat: @"%@ (%@)",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]]; 
      [cell setBorderTypeForIndex: 0 totalItems: 1];
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      break;
    default:
      break;
  }
    
  return cell;
}

- (NSIndexPath *) tableView: (UITableView *) tableView willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  if (indexPath.section == 0)
    return indexPath;
  else
    return nil;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  UIViewController *newController;
  
  switch (indexPath.row)
  {
    case 0:
      newController = [[ProfileListController alloc] initWithStyle: UITableViewStyleGrouped];
      break;
    case 1:
      newController = [[ConfigOptionViewController alloc] 
                       initWithTitle: NSLocalizedString( @"Start Up", @"Title of the iLinX start-up profile setting" )
                       options: [ConfigManager startupTypes]
                       chosenOption: [ConfigManager currentStartupType]];
      ((ConfigOptionViewController *) newController).delegate = self;
      break;
    default:
      newController = nil;
      break;
  }
  
  if (newController != nil)
  {
    [self.navigationController pushViewController: newController animated: YES];
    [newController release];
  }
  
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void) chosenConfigOption: (NSInteger) option
{
  [ConfigManager setCurrentStartupType: option];
}

- (void) donePressed
{
  if (![_originalProfile isEqual: [ConfigManager currentProfileData]])
    [(ConfigRootController *) [self navigationController] setProfileRefresh];
  
  [_originalProfile release];
  _originalProfile = nil;

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;  
  [self dismissModalViewControllerAnimated: YES];
}

- (void) stayConnectedChanged: (UISwitch *) stayConnectedSwitch
{
  [ConfigManager setStayConnected: stayConnectedSwitch.on];
}

- (void) dealloc
{
  [_originalProfile release];
  [super dealloc];
}

@end

