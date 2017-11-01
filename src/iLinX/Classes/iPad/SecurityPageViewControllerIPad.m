#import "SecurityPageViewControllerIPad.h"
#import "UncodableObjectArchiver.h"

#define BUTTON_STATE_OFF  0
#define BUTTON_STATE_ON   1
#define BUTTON_STATE_NA   2
#define NUM_BUTTON_STATES 3

@interface SecurityPageViewControllerIPad ()

- (void) buttonPushed: (UIButton *) button;
- (void) buttonReleased: (UIButton *) button;

@end

@implementation SecurityPageViewControllerIPad

- (id) initWithService: (NLServiceSecurity *) securityService controlMode: (NSUInteger) controlMode
                offset: (NSUInteger) offset buttonsPerRow: (NSUInteger) buttonsPerRow 
        buttonsPerPage: (NSUInteger) buttonsPerPage buttonTotal: (NSUInteger) buttonTotal
{
  if (self = [super initWithNibName: @"SecurityPageIPad" bundle: nil offset: offset
                      buttonsPerRow: buttonsPerRow buttonsPerPage: buttonsPerPage
                        buttonTotal: buttonTotal flash: NO])
  {
    _securityService = securityService;
    _controlMode = controlMode;
  }

  return self;
}

- (void) viewDidLoad
{
  NSArray *buttonTemplate = [NSArray arrayWithObjects:
                             [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplateOff],
                             [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplateOn],
                             [UncodableObjectArchiver dictionaryEncodingWithRootObject: _buttonTemplateNa], nil];
  
  [super viewDidLoadWithButtonTemplate: buttonTemplate frame: _buttonTemplateOff.frame];
  
  // Hide the templates once they're no longer needed
  _buttonTemplateOff.hidden = YES;
  _buttonTemplateOn.hidden = YES;
  _buttonTemplateNa.hidden = YES;
}

- (id) createButtonAtIndex: (NSUInteger) index buttonTemplate: (id) buttonTemplate frame: (CGRect) frame
{
  NSArray *titles = [_securityService.controlModeTitles objectAtIndex: _controlMode];
  NSString *name = [titles objectAtIndex: _offset + index];
  NSMutableArray *buttonArrayType = [NSMutableArray arrayWithCapacity: NUM_BUTTON_STATES];
  
  for (NSUInteger i = 0; i < NUM_BUTTON_STATES; ++i)
  {
    UIButton *button = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: [(NSArray *) buttonTemplate objectAtIndex: i]];
    
    button.frame = frame;
    button.tag = _offset + index;
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    button.hidden = YES;
    [button setTitle: name forState: UIControlStateNormal];
    [button addTarget: self action: @selector(buttonPushed:) forControlEvents: UIControlEventTouchDown];
    [button addTarget: self action: @selector(buttonReleased:) 
     forControlEvents: UIControlEventTouchUpOutside | UIControlEventTouchUpInside];
    [_contentView addSubview: button];
    [buttonArrayType addObject: button];
  }
  
  return buttonArrayType;
}

- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];

  [_securityService addDelegate: self];
  for (NSUInteger i = 0; i < _count; ++i)
    [self service: _securityService controlMode: _controlMode button: i + _offset changed: 0xFFFFFFFF];
}

- (void) viewWillDisappear: (BOOL) animated
{
  [_securityService removeDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) service: (NLServiceSecurity *) service controlMode: (NSUInteger) controlMode
          button: (NSUInteger) buttonIndex changed: (NSUInteger) changed
{
  //NSLog( @"security mode: %d button: %d changed (received by mode: %d, offset: %d, count: %d)",
  //      controlMode, buttonIndex, _controlMode, _offset, _count );
  if (controlMode == _controlMode && buttonIndex >= _offset && buttonIndex < _offset + _count)
  {
    NSArray *buttonSet = [_buttonArray objectAtIndex: (buttonIndex - _offset)];
    BOOL hasIndicator = [service indicatorPresentOnButton: buttonIndex inControlMode: controlMode];
    BOOL indicatorState = [service indicatorStateForButton: buttonIndex inControlMode: controlMode];
    
    for (NSInteger i = 0; i < NUM_BUTTON_STATES; ++i)  
    {
      UIButton *button = [buttonSet objectAtIndex: i];
      
      if (i == BUTTON_STATE_OFF)
        button.hidden = (!hasIndicator || indicatorState);
      else if (i == BUTTON_STATE_ON)
        button.hidden = (!hasIndicator || !indicatorState);
      else
        button.hidden = hasIndicator;
    }
  }
}

- (void) buttonPushed: (UIButton *) button
{
  [_securityService pushButton: button.tag inControlMode: _controlMode];
}

- (void) buttonReleased: (UIButton *) button
{
  [_securityService releaseButton: button.tag inControlMode: _controlMode];
}

- (void) dealloc
{
  [_buttonTemplateOff release];
  [_buttonTemplateOn release];
  [_buttonTemplateNa release];
  [super dealloc];
}

@end
