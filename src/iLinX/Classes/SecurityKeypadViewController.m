//
//  SecurityKeypadViewController.m
//  iLinX
//
//  Created by mcf on 18/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "SecurityKeypadViewController.h"
#import "NLServiceSecurity.h"

#define ENTER_KEY     1000
#define DELETE_KEY    1001
#define POLICE_KEY    2001
#define FIRE_KEY      2002
#define AMBULANCE_KEY 2003

@interface SecurityKeypadViewController (LocalDefinitions)

- (void) sendKey: (NSUInteger) key pressed: (BOOL) pressed;

@end

@implementation SecurityKeypadViewController

- (id) initWithSecurityService: (NLServiceSecurity *) securityService parentController: (UIViewController *) parentController
{
  if (self = [super initWithNibName: @"SecurityKeypad" bundle: nil])
  {
    _securityService = [securityService retain];
    _parentController = parentController; // Not retained, because it retains us
  }
  
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  NSUInteger capabilities = _securityService.capabilities;
  CGFloat x = 0;
  CGFloat y = 0;
  BOOL noEmergencyButtons = ((capabilities & (SERVICE_SECURITY_HAS_FIRE|SERVICE_SECURITY_HAS_POLICE|SERVICE_SECURITY_HAS_AMBULANCE)) == 0);
  
  if ((capabilities & SERVICE_SECURITY_HAS_STAR_HASH) == 0)
  {
    if ((capabilities & SERVICE_SECURITY_HAS_CLEAR_ENTER) != 0 && noEmergencyButtons)
    {
      _starButton.tag = DELETE_KEY;
      [_starButton setTitle: [_deleteButton titleForState: UIControlStateNormal] forState: UIControlStateNormal];
      [_starButton setImage: [_deleteButton imageForState: UIControlStateNormal] forState: UIControlStateNormal];
      [_starButton setTitle: [_deleteButton titleForState: UIControlStateNormal] forState: UIControlStateHighlighted];
      [_starButton setImage: [_deleteButton imageForState: UIControlStateNormal] forState: UIControlStateHighlighted];
      _hashButton.tag = ENTER_KEY;
      [_hashButton setTitle: [_enterButton titleForState: UIControlStateNormal] forState: UIControlStateNormal];
      [_hashButton setImage: [_enterButton imageForState: UIControlStateNormal] forState: UIControlStateNormal];
      [_hashButton setTitle: [_enterButton titleForState: UIControlStateNormal] forState: UIControlStateHighlighted];
      [_hashButton setImage: [_enterButton imageForState: UIControlStateNormal] forState: UIControlStateHighlighted];
      capabilities &= ~SERVICE_SECURITY_HAS_CLEAR_ENTER;
    }
    else
    {
      _starButton.hidden = YES;
      _hashButton.hidden = YES;
    }
  }
  if ((capabilities & SERVICE_SECURITY_HAS_POLICE) == 0)
  {
    _policeButton.hidden = YES;
    y = -6;
  }
  _fireButton.hidden = ((capabilities & SERVICE_SECURITY_HAS_FIRE) == 0);
  _ambulanceButton.hidden = ((capabilities & SERVICE_SECURITY_HAS_AMBULANCE) == 0);
  if ((capabilities & SERVICE_SECURITY_HAS_CLEAR_ENTER) == 0)
  {
    _deleteButton.hidden = YES;
    _enterButton.hidden = YES;
    if (noEmergencyButtons)
      x = _enterButton.frame.origin.x - _hashButton.frame.origin.x;
    else if ((capabilities & SERVICE_SECURITY_HAS_POLICE) != 0)
    {
      _policeButton.frame = _fireButton.frame;
      _fireButton.frame = _ambulanceButton.frame;
      _ambulanceButton.frame = _deleteButton.frame;
      y = -6;
    }
  }
  
  if (x != 0 || y != 0)
  {
    NSArray *items = self.view.subviews;
    NSUInteger count = [items count];
    NSUInteger i;
    
    // Start at index 1 to exclude the backdrop image
    for (i = 1; i < count; ++i)
    {
      UIView *item = [items objectAtIndex: i];
      
      item.frame = CGRectOffset( item.frame, x, y );
    }
  }
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [_securityService addDelegate: self];
  [self service: _securityService changed: 0xFFFFFFFF];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_securityService removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) service: (NLServiceSecurity *) service changed: (NSUInteger) changed
{
  if ((changed & SERVICE_SECURITY_DISPLAY_TEXT_CHANGED) != 0)
    _numberDisplay.text = service.displayText;
}

- (IBAction) pressedButton: (UIButton *) button
{
  [self sendKey: button.tag pressed: YES];
}

- (IBAction) releasedButton: (UIButton *) button
{
  [self sendKey: button.tag pressed: NO];
}

- (void) sendKey: (NSUInteger) key pressed: (BOOL) pressed
{
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
      message = NSLocalizedString( @"Call the police?",
                                  @"Message in the call police confirmation dialog" );
      _pendingEmergencyAction = @"Police";
      break;
    case FIRE_KEY:
      message = NSLocalizedString( @"Call the fire service?",
                                  @"Message in the call fire service confirmation dialog" );
      _pendingEmergencyAction = @"Fire";
      break;
    case AMBULANCE_KEY:
      message = NSLocalizedString( @"Call the medic?",
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
    UIActionSheet *queryEmergencyCall = [[UIActionSheet alloc] initWithTitle: message delegate: self 
                                                           cancelButtonTitle: NSLocalizedString( @"Cancel", @"Button to cancel calling emergency service" )
                                                      destructiveButtonTitle: NSLocalizedString( @"Call", @"Button to call emergency service" )
                                                           otherButtonTitles: nil];
    
    queryEmergencyCall.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [queryEmergencyCall showInView: [[UIApplication sharedApplication] keyWindow]];
    [queryEmergencyCall release];
  }
}

- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex
{
  if (buttonIndex != actionSheet.cancelButtonIndex)
  {
    [_securityService pressKeypadKey: _pendingEmergencyAction];
    [_securityService releaseKeypadKey: _pendingEmergencyAction];
  }
}

- (void) dealloc
{
  [_securityService release];
  [_numberDisplay release];
  [_policeButton release];
  [_fireButton release];
  [_ambulanceButton release];
  [_deleteButton release];
  [_enterButton release];
  [_starButton release];
  [_hashButton release];
  [super dealloc];
}

@end
