//
//  SecurityViewControllerIPad.m
//  iLinX
//
//  Created by James Stamp on 29/09/2010.
//  Copyright 2010 Janus Technology. All rights reserved.
//

#import "SecurityViewControllerIPad.h"
#import "SecurityPageViewControllerIPad.h"
#import "MainNavigationController.h"
#import "NLServiceSecurity.h"

#define BUTTONS_PER_PAGE 6	
#define BUTTONS_PER_ROW  3

#define ENTER_KEY     1000
#define DELETE_KEY    1001
#define POLICE_KEY    2001
#define FIRE_KEY      2002
#define AMBULANCE_KEY 2003


@interface SecurityViewControllerIPad  ()

- (void) configureSegments;
- (void) sendKey: (NSUInteger) key pressed: (BOOL) pressed;
- (void) initialisePages;

@end


@implementation SecurityViewControllerIPad 
@synthesize tableView = _tableView;

- (id) initWithOwner: (RootViewControllerIPad *) owner service: (NLService *) service
{
  if (self = [super initWithOwner: owner service: service
			  nibName: @"SecurityViewIPad" bundle: nil])
  {
    _securityService = [(NLServiceSecurity *) service retain];
    _numberOfColumns = BUTTONS_PER_ROW;
    _buttonsOnPage = BUTTONS_PER_PAGE;
    _buttonsControlMode = NSNotFound;
    _tableControlMode = NSNotFound;
  }

  return self;
}

- (void) dealloc
{
  [_serviceName release];
  [_emergency release];
  [_policeButton release];
  [_fireButton release];
  [_ambulanceButton release];
  [_numberDisplay release];
  [_deleteButton release];
  [_enterButton release];
  [_starButton release];
  [_hashButton release];
  [_openAreas release];
  [_scroller release];
  [_tableView release];
  [_buttonsTitle release];
  [_tableTitle release];
  [_pageController release];
  [_securityService removeDelegate: self];
  [_securityService release];
  [super dealloc];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  NSUInteger capabilities = _securityService.capabilities;
  BOOL noEmergencyButtons = ((capabilities & (SERVICE_SECURITY_HAS_FIRE|SERVICE_SECURITY_HAS_POLICE|SERVICE_SECURITY_HAS_AMBULANCE)) == 0);
  
  _starButton.hidden = ((capabilities & SERVICE_SECURITY_HAS_STAR_HASH) == 0);
  _hashButton.hidden = _starButton.hidden;
  _deleteButton.hidden = ((capabilities & SERVICE_SECURITY_HAS_CLEAR_ENTER) == 0);
  _enterButton.hidden = _deleteButton.hidden;

  _policeButton.hidden = ((capabilities & SERVICE_SECURITY_HAS_POLICE) == 0);
  _fireButton.hidden = ((capabilities & SERVICE_SECURITY_HAS_FIRE) == 0);
  _ambulanceButton.hidden = ((capabilities & SERVICE_SECURITY_HAS_AMBULANCE) == 0);
  _emergency.hidden = noEmergencyButtons;
  _openAreas.hidden = !noEmergencyButtons;

  [self configureSegments];
  [self initialisePages];
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [self service: _securityService changed: 0xFFFFFFFF];
  [_securityService addDelegate: self];
  _tableView.hidden = (_tableControlMode == NSNotFound);
  _scroller.hidden = (_buttonsControlMode == NSNotFound);
  [_pageController viewWillAppear: animated];
  [_tableView reloadData];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  _serviceName.text = [_service displayName];
  [_pageController viewDidAppear: animated];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_securityService removeDelegate: self];
  [_pageController viewWillDisappear: animated];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_pageController viewDidDisappear: animated];
  [super viewDidDisappear: animated];
}

- (void) service: (NLServiceSecurity *) service changed: (NSUInteger) changed
{
  if ((changed & SERVICE_SECURITY_DISPLAY_TEXT_CHANGED) != 0)
    _numberDisplay.text = service.displayText;
  
  if ((changed & SERVICE_SECURITY_ERROR_MESSAGE_CHANGED) != 0)
  {
    NSString *message = service.errorMessage;
    
    if (message != nil && [message length] > 0)
    {
      UIAlertView *alert = [[UIAlertView alloc] 
                            initWithTitle: NSLocalizedString( @"Security System Warning", @"Title for the security warning dialog" )
                            message: NSLocalizedString( service.errorMessage,
                                                       @"Localised version of the error message" ) 
                            delegate: nil
                            cancelButtonTitle: NSLocalizedString( @"OK", @"Title of button dismissing the security warning dialog" )
                            otherButtonTitles: nil];
      
      [alert show];
      [alert release];
    }
  }
  
  if ((changed & SERVICE_SECURITY_MODES_CHANGED) != 0)
  {
    [self configureSegments];
    [self initialisePages];
  }

  if ((changed & SERVICE_SECURITY_MODE_TITLES_CHANGED) != 0)
  {
    if (_tableControlMode != NSNotFound)
    {
      [self.tableView reloadData];
      if ([_securityService buttonCountInControlMode: _tableControlMode] > 0)
      {
        @try
        {
          [self.tableView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0]
                                atScrollPosition: UITableViewScrollPositionTop animated: NO];
        }
        @catch (NSException *exception)
        {
        }
      }
    }

    if (_buttonsControlMode != NSNotFound && 
        _buttonCount != [_securityService buttonCountInControlMode: _buttonsControlMode])
      [self initialisePages];
  }
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
  NSUInteger rows;

  if (_tableControlMode == NSNotFound)
    rows = 0;
  else
    rows = [_securityService buttonCountInControlMode: _tableControlMode];

  return rows;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MyIdentifier"];
  UIView *backgroundView;
  UILabel *text;
  
  if (cell == nil)
  {
//    cell = [[[UITableViewCell alloc] initDefaultWithFrame: CGRectMake( 0, 0, self.tableView.bounds.size.width, self.tableView.rowHeight )
//					  reuseIdentifier: @"MyIdentifier"] autorelease];
  
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: @"MyIdentifier"] autorelease];
    //cell = [[[UITableViewCell alloc] initWithFrame: CGRectMake( 0, 0, self.tableView.bounds.size.width, self.tableView.rowHeight ) 
    //                               reuseIdentifier:@"MyIdentifier"] autorelease];
    backgroundView = [[UIView alloc] initWithFrame: cell.bounds];
    [cell.contentView addSubview: backgroundView];
    [backgroundView release];
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    text = [[UILabel alloc] initWithFrame: CGRectInset( cell.bounds, 10, 0 )];
    text.backgroundColor = [UIColor clearColor];
    text.font = [UIFont boldSystemFontOfSize: [UIFont buttonFontSize]];
    text.textColor = [UIColor whiteColor];
    [cell.contentView addSubview: text];
    [text release];
  }
  else
  {
    NSArray *subviews = [cell.contentView subviews];
    
    backgroundView = [subviews objectAtIndex: 0];
    text = [subviews objectAtIndex: 1];
  }
  
  if (indexPath.row % 2 == 1)
    backgroundView.backgroundColor = [UIColor colorWithWhite: 0.3 alpha: 0.2];
  else
    backgroundView.backgroundColor = [UIColor colorWithWhite: 0.5 alpha: 0.2];
  
  text.text = [_securityService nameForButton: indexPath.row inControlMode: _tableControlMode];
  
  if ([_securityService isEnabledButton: indexPath.row inControlMode: _tableControlMode])
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  else
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  if ([_securityService indicatorStateForButton: indexPath.row inControlMode: _tableControlMode])
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  else
    cell.accessoryType = UITableViewCellAccessoryNone;

  return cell;
}

- (void) initialisePages
{
  if (_buttonsControlMode == NSNotFound)
  {
    _scroller.hidden = YES;
    _pageController.numberOfPages = 0;
    //NSLog( @"initialisePages: 0" );
  }
  else
  {
    NSUInteger pageCount;
    
    _scroller.hidden = NO;
    _buttonCount = [_securityService buttonCountInControlMode: _buttonsControlMode];
    if (_buttonCount == 0)
      pageCount = 1;
    else
      pageCount = ((_buttonCount - 1) / _buttonsOnPage) + 1;

    _pageController.numberOfPages = pageCount;
  }
}

- (UIViewController *) pagedScrollView: (PagedScrollView *) pagedScrollView viewControllerForPage: (NSInteger) page
{
  return [[[SecurityPageViewControllerIPad alloc]
           initWithService: _securityService controlMode: _buttonsControlMode 
           offset: page * _buttonsOnPage buttonsPerRow: _numberOfColumns
           buttonsPerPage: _buttonsOnPage buttonTotal: _buttonCount] autorelease];
}

- (IBAction) pressedButton: (UIButton *) button
{
  [self sendKey: button.tag pressed: YES];
}
- (IBAction) releasedButton: (UIButton *) button
{
  [self sendKey: button.tag pressed: NO];
}

- (void) configureSegments
{
  NSUInteger segmentCount = [_securityService.controlModes count] + 1;
  NSUInteger i;
  NSInteger buttonsControlMode = NSNotFound;
  NSInteger tableControlMode = NSNotFound;
  
  for (i = 0; i < segmentCount - 1; ++i)
  {
    if ([_securityService styleForControlMode: i] == SERVICE_SECURITY_MODE_TYPE_LIST)
      tableControlMode = i;
    else
      buttonsControlMode = i;
  }
  
  if (buttonsControlMode != _buttonsControlMode)
  {
    _buttonsControlMode = buttonsControlMode;
    _scroller.hidden = (_buttonsControlMode == NSNotFound);
  }

  if (_buttonsControlMode == NSNotFound)
    _buttonsTitle.text = @"";
  else
    _buttonsTitle.text = [_securityService.controlModes objectAtIndex: _buttonsControlMode];
  
  if (tableControlMode != _tableControlMode)
  {
    _tableControlMode = tableControlMode;
    _tableView.hidden = (_tableControlMode == NSNotFound);
  }
  
  if (_tableControlMode == NSNotFound)
    _tableTitle.text = @"";
  else
    _tableTitle.text = [_securityService.controlModes objectAtIndex: _tableControlMode];
}

- (void) sendKey: (NSUInteger) key pressed: (BOOL) pressed
{
  NSString *title = nil;
  NSString *message = nil;
  NSString *keyName = nil;
  
  switch (key)
  {
    case ENTER_KEY:
      keyName = @"Enter";
      break;
    case DELETE_KEY:
      keyName = @"Clear";
      break;
    case POLICE_KEY:
      title = NSLocalizedString( @"Police",
                                  @"Title in the call police confirmation dialog" );
      message = NSLocalizedString( @"Are you sure you want to call the police?",
                                  @"Message in the call police confirmation dialog" );
      _pendingEmergencyAction = @"Police";
      break;
    case FIRE_KEY:
      title = NSLocalizedString( @"Fire",
                                @"Title in the call fire service confirmation dialog" );
      message = NSLocalizedString( @"Are you sure you want to call the fire service?",
                                  @"Message in the call fire service confirmation dialog" );
      _pendingEmergencyAction = @"Fire";
      break;
    case AMBULANCE_KEY:
      title = NSLocalizedString( @"Medic",
                                @"Title in the call medic confirmation dialog" );
      message = NSLocalizedString( @"Are you sure you want to call the medic?",
                                  @"Message in the call medic confirmation dialog" );
      _pendingEmergencyAction = @"Aux";
      break;
    default:
      keyName = [NSString stringWithFormat: @"%c", (char) key];
      break;
  }
  
  if (keyName != nil)
  {
    if (pressed)
      [_securityService pressKeypadKey: keyName];
    else
      [_securityService releaseKeypadKey: keyName];
  }
  else if (!pressed)
  {
    UIAlertView *queryEmergencyCall = [[UIAlertView alloc] initWithTitle: title message: message delegate: self
                                                       cancelButtonTitle: NSLocalizedString( @"Cancel", @"Button to cancel calling emergency service" )
                                                       otherButtonTitles: NSLocalizedString( @"Call", @"Button to call emergency service" ), nil];
    
    [queryEmergencyCall show];
    [queryEmergencyCall release];
  }
}

- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex
{
  if (buttonIndex != alertView.cancelButtonIndex)
  {
    [_securityService pressKeypadKey: _pendingEmergencyAction];
    [_securityService releaseKeypadKey: _pendingEmergencyAction];
  }
}

@end