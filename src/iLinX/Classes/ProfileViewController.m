//
//  ProfileViewController.m
//  iLinX
//
//  Created by mcf on 27/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "ProfileViewController.h"
#import "ConfigProfile.h"
#import "ConfigOptionViewController.h"
#import "SettingAndValueCell.h"

#define SKINS_IMPLEMENTED 1

#define LINE_TAG_NAME 0
#define LINE_TAG_CONNECTION_TYPE 1
#define SECTION_0_ROWS 2

#define LINE_TAG_CONNECTION_ADDRESS 10
#define LINE_TAG_CONNECTION_PORT 11
#define SECTION_1_ROWS 2

#define LINE_TAG_STATIC_MENU_ROOM 20
#define LINE_TAG_TITLE_BAR_MACRO 21
#if defined(IPAD_BUILD)
#  define LINE_TAG_BUTTON_ROWS 22
#  define LINE_TAG_BUTTONS_PER_ROW 23
#  define LINE_TAG_ARTWORK_URL 24
#  define LINE_TAG_CUSTOM_PAGE_BASE_URL 25
#  if defined(SKINS_IMPLEMENTED)
#    define SECTION_2_ROWS 6
#  else
#    define SECTION_2_ROWS 5
#  endif
#else
#  define LINE_TAG_BUTTON_ROWS -02
#  define LINE_TAG_BUTTONS_PER_ROW -01
#  define LINE_TAG_ARTWORK_URL 22
#  define LINE_TAG_CUSTOM_PAGE_BASE_URL 23
#  if defined(SKINS_IMPLEMENTED)
#    define SECTION_2_ROWS 4
#  else
#    define SECTION_2_ROWS 3
#  endif
#endif

@interface ProfileViewController ()

- (void) keypadDone;
- (void) initialiseTitle;

@end

@implementation ProfileViewController

- (id) initWithProfile: (ConfigProfile *) profile
{
  if (self = [super initWithStyle: UITableViewStyleGrouped])
    _profile = [profile retain];
  
  return self;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [self initialiseTitle];
  [self.tableView reloadData];
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

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSInteger rows;

  switch (section)
  {
    case 0:
      rows = SECTION_0_ROWS;
      break;
    case 1:
      rows = SECTION_1_ROWS;
      break;
    case 2:
      rows = SECTION_2_ROWS;
      break;
    default:
      rows = 0;
      break;
  }
  
  return rows;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
  NSString *title;
  
  switch (section)
  {
    case 1:
      if (_profile.autoDiscovery)
        title = NSLocalizedString( @"Auto-Discovery", @"Title of autodiscovery section of profile view" );
      else
        title = NSLocalizedString( @"Direct Connection", @"Title of direct connection section of profile view" );
      break;
    case 2:
      title = NSLocalizedString( @"Customization", @"Title of customization section of profile view" );
      break;
    default:
      title = @"";
      break;
  }
  
  return title;  
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  static NSString *CellIdentifier = @"ProfileCell";
    
  SettingAndValueCell *cell = (SettingAndValueCell *) [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  
  if (cell == nil)
    cell = [[[SettingAndValueCell alloc] initDefaultWithFrame: CGRectZero reuseIdentifier: CellIdentifier
                                                        table: tableView] autorelease];
  
  cell.detailMinimumFontSize = 10;
  cell.detailAdjustsFontSizeToFitWidth = YES;
  cell.tag = indexPath.section * 10 + indexPath.row;
  cell.editableDetailField.tag = cell.tag;
  cell.accessoryType = UITableViewCellAccessoryNone;
  
  switch (indexPath.section)
  {
    case 0:
      switch (cell.tag)
      {
        case LINE_TAG_NAME:  
          cell.nameText = NSLocalizedString( @"Name", @"Title for name field in profile view" );
          cell.detailText = _profile.name;
          break;
        case LINE_TAG_CONNECTION_TYPE:
          cell.nameText = NSLocalizedString( @"Type", @"Title of connection type field in profile view" );
          if (_profile.autoDiscovery)
            cell.detailText = NSLocalizedString( @"Auto-Discovery", @"Name of auto-discovery value for connection type in profile view" );
          else
            cell.detailText = NSLocalizedString( @"Direct", @"Name of direct connection value for connection type in profile view" );
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
           break;
        default:
          break;
      }
      [cell setBorderTypeForIndex: indexPath.row totalItems: SECTION_0_ROWS];
      break;
    case 1:
      if (_profile.autoDiscovery)
      {
        switch (cell.tag)
        {
          case LINE_TAG_CONNECTION_ADDRESS:
            cell.nameText = NSLocalizedString( @"Multicast Address", @"Title of autodiscovery address field in profile view" );
            cell.detailText = _profile.multicastAddress;
            break;
          case LINE_TAG_CONNECTION_PORT:
            cell.nameText = NSLocalizedString( @"Port", @"Title of autodiscovery port field in profile view" );
            cell.detailText = [NSString stringWithFormat: @"%d", _profile.multicastPort];
            break;
          default:
            break;
        }
      }
      else
      {
        switch (cell.tag)
        {
          case LINE_TAG_CONNECTION_ADDRESS:
            cell.nameText = NSLocalizedString( @"Address", @"Title of direct connect address field in profile view" );
            cell.detailText = _profile.directAddress;
            break;
          case LINE_TAG_CONNECTION_PORT:
            cell.nameText = NSLocalizedString( @"Port", @"Title of direct connect port field in profile view" );
            cell.detailText = [NSString stringWithFormat: @"%d", _profile.directPort];
            break;
          default:
            break;
        }        
      }
      [cell setBorderTypeForIndex: indexPath.row totalItems: SECTION_1_ROWS];
      break;
    case 2:
      switch (cell.tag)
      {
        case LINE_TAG_STATIC_MENU_ROOM:
          cell.nameText = NSLocalizedString( @"Static Menu Room", @"Title of static menu room field in profile view" );
          cell.detailText = _profile.staticMenuRoom;
          break;
        case LINE_TAG_TITLE_BAR_MACRO:
          cell.nameText = NSLocalizedString( @"Title Bar Macro", @"Title of title bar macro field in profile view" );
          cell.detailText = _profile.titleBarMacro;
          break;
        case LINE_TAG_BUTTON_ROWS:
          cell.nameText = NSLocalizedString( @"Button Rows", @"Title of custom how many rows of buttons" );
          cell.detailText = [NSString stringWithFormat: @"%d", _profile.buttonRows];
          break;	  
        case LINE_TAG_BUTTONS_PER_ROW:
          cell.nameText = NSLocalizedString( @"Buttons Per Row", @"Title of custom how many buttons on a row" );
          cell.detailText = [NSString stringWithFormat: @"%d", _profile.buttonsPerRow];
          break;	  
        case LINE_TAG_ARTWORK_URL:
          cell.nameText = NSLocalizedString( @"Artwork URL", @"Title of artwork URL field in profile view" );
          cell.detailText = _profile.artworkURL;
          break;
        case LINE_TAG_CUSTOM_PAGE_BASE_URL:
          cell.nameText = NSLocalizedString( @"Skin URL", @"Title of custom pages base URL field in profile view" );
          cell.detailText = _profile.skinURL;
          break;
        default:
          break;
      }
      [cell setBorderTypeForIndex: indexPath.row totalItems: SECTION_2_ROWS];
      break;
  }

  return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
  SettingAndValueCell *currentCell = (SettingAndValueCell *) [tableView cellForRowAtIndexPath: indexPath];
  
  [_currentCell resignFirstResponder];
  [_currentCell release];
  _currentCell = [currentCell retain];
  
  if (_currentCell.tag == LINE_TAG_CONNECTION_TYPE)
  {
    ConfigOptionViewController *newController = [[ConfigOptionViewController alloc]
                                                 initWithTitle: NSLocalizedString( @"Connection", @"Title of the view that sets the type of a connection in a profile" )
                                                 options: [NSArray arrayWithObjects:
                                                           NSLocalizedString( @"Auto-Discovery", @"Profile connection type: auto-discovery" ),
                                                           NSLocalizedString( @"Direct", @"Profile connection type: direct" ),
                                                           nil]
                                                 chosenOption: (_profile.autoDiscovery?0:1)];

    newController.delegate = self;
    [self.navigationController pushViewController: newController animated: YES];
    [newController release];
  }
  else
  {    
    _currentCell.editableDetailField.delegate = self;
    _currentCell.editableDetailField.returnKeyType = UIReturnKeyDone;
    switch (_currentCell.tag)
    {
      case LINE_TAG_NAME:
        _currentCell.editableDetailField.keyboardType = UIKeyboardTypeAlphabet;
        _currentCell.editableDetailField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        _currentCell.editableDetailField.autocorrectionType = UITextAutocorrectionTypeDefault;
        break;
      case LINE_TAG_CONNECTION_ADDRESS:
      case LINE_TAG_ARTWORK_URL:
      case LINE_TAG_CUSTOM_PAGE_BASE_URL:
        _currentCell.editableDetailField.keyboardType = UIKeyboardTypeURL;
        _currentCell.editableDetailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _currentCell.editableDetailField.autocorrectionType = UITextAutocorrectionTypeNo;
        break;
      case LINE_TAG_CONNECTION_PORT:
      case LINE_TAG_BUTTON_ROWS:
      case LINE_TAG_BUTTONS_PER_ROW:
        _currentCell.editableDetailField.keyboardType = UIKeyboardTypeNumberPad;
        _currentCell.editableDetailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _currentCell.editableDetailField.autocorrectionType = UITextAutocorrectionTypeNo;
        break;
      default:
        _currentCell.editableDetailField.keyboardType = UIKeyboardTypeAlphabet;
        _currentCell.editableDetailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _currentCell.editableDetailField.autocorrectionType = UITextAutocorrectionTypeNo;
        break;
    }
        
    [_currentCell becomeFirstResponder];
  }

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (BOOL) textFieldShouldReturn: (UITextField *) textField
{
  [self keypadDone];
  
  return NO;
}

- (void) textFieldDidEndEditing: (UITextField *) textField
{
  switch (textField.tag)
  {
    case LINE_TAG_NAME:
      _profile.name = textField.text;
      [self initialiseTitle];
      break;
    case LINE_TAG_CONNECTION_ADDRESS:
    {
      NSString *oldText;

      if (_profile.autoDiscovery)
      {
        oldText = _profile.multicastAddress;
        _profile.multicastAddress = textField.text;
      }
      else
      {
        oldText = _profile.directAddress;
        _profile.directAddress = textField.text;
      }
      if (![oldText isEqualToString: textField.text])
      {
        // Reset state if we change connection destination as the old details may now be invalid
        _profile.state = [NSMutableArray arrayWithCapacity: 5];
      }
      break;
    }
    case LINE_TAG_CONNECTION_PORT:
      if (_profile.autoDiscovery)
        _profile.multicastPort = [textField.text integerValue];
      else 
        _profile.directPort = [textField.text integerValue];
      break;
    case LINE_TAG_STATIC_MENU_ROOM:
      _profile.staticMenuRoom = textField.text;
      break;
    case LINE_TAG_BUTTON_ROWS:
      _profile.buttonRows = [textField.text integerValue];
      break;
    case LINE_TAG_BUTTONS_PER_ROW:
      _profile.buttonsPerRow = [textField.text integerValue];
      break;
    case LINE_TAG_TITLE_BAR_MACRO:
      _profile.titleBarMacro = textField.text;
      break;
    case LINE_TAG_ARTWORK_URL:
      _profile.artworkURL = textField.text;
      break;
    case LINE_TAG_CUSTOM_PAGE_BASE_URL:
      _profile.skinURL = textField.text;
      break;
    default:
      break;
  }
  
  textField.delegate = nil;
  [self.tableView reloadData];
}

- (void) chosenConfigOption: (NSInteger) option
{
  if (_profile.autoDiscovery != (option == 0))
  {
    // Reset state if we change connection type as the old details may now be invalid
    _profile.autoDiscovery = (option == 0);
    _profile.state = [NSMutableArray arrayWithCapacity: 5];
  }
}

- (void) keypadDone
{
  [_currentCell resignFirstResponder];
  [_currentCell release];
  _currentCell = nil;
}

- (void) initialiseTitle
{
  if ([_profile.name length] > 0)
    self.navigationItem.title = _profile.name;
  else
    self.navigationItem.title = NSLocalizedString( @"<Unnamed>", @"Temporary title for an unnamed communications profile" );
}

- (void) dealloc
{
  [_profile release];
  [_currentCell release];
  [super dealloc];
}

@end

