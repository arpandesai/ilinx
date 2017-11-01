//
//  MultiRoomViewIPad.m
//  iLinX
//
//  Created by Tony Short on 27/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "MultiRoomViewIPad.h"
#import "StandardPalette.h"
#import "SettingsControlsIPad.h"
#import "ChangeSelectionHelper.h"
#import "NLRoom.h"
#import "NLZoneList.h"

@implementation MultiRoomViewIPad

@synthesize renderer = _renderer;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
	[_renderer release];

}

- (void) addMultiroomControlsToViewOffset:(NSInteger*)yOffset
{
	_style = UIBarStyleDefault;
	
	_create = (UIButton*)[self viewWithTag:NewButtonTag];
	if(_create != nil)
	{
		[_create setTitle: NSLocalizedString( @"New", @"Title of button to join a multiroom" ) forState: UIControlStateNormal]; 
		[_create addTarget: self action: @selector(multiVolumeCreatePressed:) forControlEvents: UIControlEventTouchDown];	}
	
	_volDown = (UIButton*)[self viewWithTag:VolDownButtonTag];
	if(_volDown != nil)
	{
		[_volDown setTitle: NSLocalizedString( @"Vol -", @"Title of button to lower multiroom volume" ) forState: UIControlStateNormal];
		[_volDown addTarget: self action: @selector(multiVolumeDownPressed:) forControlEvents: UIControlEventTouchDown];
		[_volDown addTarget: self action: @selector(multiVolumeDownReleased:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	}

	_volUp = (UIButton*)[self viewWithTag:VolUpButtonTag];
	if(_volUp != nil)
	{
		[_volUp setTitle: NSLocalizedString( @"Vol +", @"Title of button to raise multiroom volume" ) forState: UIControlStateNormal]; 
		[_volUp addTarget: self action: @selector(multiVolumeUpPressed:) forControlEvents: UIControlEventTouchDown];
		[_volUp addTarget: self action: @selector(multiVolumeUpReleased:) forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	}

	_volSync = (UIButton*)[self viewWithTag:SyncButtonTag];
	if(_volSync != nil)
	{
		[_volSync setTitle: NSLocalizedString( @"Sync", @"Title of button to synchronize multiroom volume" ) forState: UIControlStateNormal]; 
		[_volSync addTarget: self action: @selector(multiVolumeSyncPressed:) forControlEvents: UIControlEventTouchDown];
	}

	_volMute = (UIButton*)[self viewWithTag:MuteButtonTag];
	if(_volMute != nil)
	{
		[_volMute setTitle: NSLocalizedString( @"Mute", @"Title of button to mute multiroom volume" ) forState: UIControlStateNormal]; 
		[_volMute addTarget: self action: @selector(multiVolumeMutePressed:) forControlEvents: UIControlEventTouchDown];
	}

	_allOff = (UIButton*)[self viewWithTag:OffButtonTag];
	if(_allOff != nil)
	{
		[_allOff setTitle: NSLocalizedString( @"Off", @"Title of button to switch off a multiroom session" ) forState: UIControlStateNormal]; 
		[_allOff addTarget: self action: @selector(multiVolumeOffPressed:) forControlEvents: UIControlEventTouchDown];
	}

	_leave = (UIButton*)[self viewWithTag:LeaveButtonTag];
	if(_leave != nil)
	{
		[_leave setTitle: NSLocalizedString( @"Leave", @"Title of button to leave a multiroom session" ) forState: UIControlStateNormal]; 
		[_leave addTarget: self action: @selector(multiVolumeLeavePressed:) forControlEvents: UIControlEventTouchDown];
	}

	_cancel = (UIButton*)[self viewWithTag:CancelButtonTag];
	if(_cancel != nil)
	{
		[_cancel setTitle: NSLocalizedString( @"Cancel", @"Title of button to cancel a multiroom session" ) forState: UIControlStateNormal];
		[_cancel addTarget: self action: @selector(multiVolumeCancelPressed:) forControlEvents: UIControlEventTouchDown];
	}
	(*yOffset += 189);
	
	[self updateStateInMultiRoom:_inMultiRoom];
}

-(void)updateStateInMultiRoom:(BOOL)inMultiRoom
{
	_inMultiRoom = inMultiRoom;
	
	if(_inMultiRoom)
		_cancel.hidden = _volDown.hidden = _volUp.hidden = _volMute.hidden = _volSync.hidden = _leave.hidden = _allOff.hidden = NO;
	else
		_cancel.hidden = _volDown.hidden = _volUp.hidden = _volMute.hidden = _volSync.hidden = _leave.hidden = _allOff.hidden = YES;
}

- (void) multiVolumeDownPressed: (id) control
{
	[_volTimer invalidate];
	[_renderer multiRoomVolumeDown];
	_volTimer = [NSTimer scheduledTimerWithTimeInterval: VOLUME_CHANGE_REPEAT_INTERVAL target: self
											   selector: @selector(multiVolumeDownPressed:) userInfo: nil repeats: NO];
}

- (void) multiVolumeDownReleased: (id) control
{
	[_volTimer invalidate];
	_volTimer = nil;
}

- (void) multiVolumeUpPressed: (id) control
{
	[_volTimer invalidate];
	[_renderer multiRoomVolumeUp];
	_volTimer = [NSTimer scheduledTimerWithTimeInterval: VOLUME_CHANGE_REPEAT_INTERVAL target: self
											   selector: @selector(multiVolumeUpPressed:) userInfo: nil repeats: NO];
}

- (void) multiVolumeUpReleased: (id) control
{
	[_volTimer invalidate];
	_volTimer = nil;
}

- (void) multiVolumeSyncPressed: (id) control
{
	[_renderer multiRoomVolumeSync];
}

- (void) multiVolumeMutePressed: (id) control
{
	[_renderer multiRoomVolumeMute];
}

- (void) multiVolumeOffPressed: (id) control
{
	[_renderer multiRoomAllOff];
}

- (void) multiVolumeCreatePressed: (id) control
{
	if (_renderer.audioSessionActive)
		[_renderer.room.zones setCurrentZoneToMatchAudioSession: _renderer.audioSessionName];
	else
		[_renderer.room.zones setCurrentZoneToMatchAudioSession: @""];
	
	_choosingZone = YES;

	if(_multiRoomSelectViewController == nil)
	{
		_multiRoomSelectViewController = [[MultiRoomSelectViewController alloc] initWithNibName:@"MultiRoomSelectViewIPad" bundle:nil];
		_multiRoomSelectViewController.delegate = self;
		_multiRoomSelectPopover = [[UIPopoverController alloc] initWithContentViewController:_multiRoomSelectViewController];
	}
	
	if(_multiRoomSelectPopover.popoverVisible)
		[_multiRoomSelectPopover dismissPopoverAnimated:YES];
	else
	{
		[_multiRoomSelectViewController setZones:_renderer.room.zones.zones];
		[_multiRoomSelectPopover setPopoverContentSize:_multiRoomSelectViewController.contentSizeForViewInPopover];
		[_multiRoomSelectPopover presentPopoverFromRect:_create.frame inView:_create.superview permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];	
	}
	
}

-(void)multiRoomChosen:(NSInteger)multiRoomSelect
{
	[_multiRoomSelectPopover dismissPopoverAnimated:YES];
	[_renderer multiRoomJoin: [_renderer.room.zones.zones objectAtIndex:multiRoomSelect]];

}

- (void) multiVolumeLeavePressed: (id) control
{
	[_renderer multiRoomLeave];
}

- (void) multiVolumeCancelPressed: (id) control
{
	[_renderer multiRoomCancel];
}

@end
