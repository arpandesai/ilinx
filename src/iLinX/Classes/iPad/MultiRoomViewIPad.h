//
//  MultiRoomViewIPad.h
//  iLinX
//
//  Created by Tony Short on 27/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLRenderer.h"
#import "MultiRoomSelectViewController.h"

#define VOLUME_CHANGE_REPEAT_INTERVAL 0.250

enum 
{
	LeaveButtonTag = 1,
	CancelButtonTag,
	VolDownButtonTag,
	VolUpButtonTag,
	SyncButtonTag,
	MuteButtonTag,
	OffButtonTag,
	NewButtonTag,
};

@interface MultiRoomViewIPad : UIView 
		<MultiRoomSelectViewDelegate>
{
	BOOL _inMultiRoom;
	MultiRoomViewIPad *_multiRoomView;
	NLRenderer *_renderer;
	UIBarStyle _style;
	NSTimer *_volTimer;
	BOOL _choosingZone;
	
	UIButton *_create;
	UIButton *_cancel;
	UIButton *_volDown;
	UIButton *_volUp;
	UIButton *_volSync;
	UIButton *_volMute;
	UIButton *_leave;
	UIButton *_allOff;
	
	MultiRoomSelectViewController *_multiRoomSelectViewController;
	UIPopoverController *_multiRoomSelectPopover;
}

@property (nonatomic, retain) NLRenderer *renderer;


- (void) addMultiroomControlsToViewOffset:(NSInteger*)yOffset;
-(void)updateStateInMultiRoom:(BOOL)inMultiRoom;
- (void) multiVolumeDownPressed: (id) control;
- (void) multiVolumeDownReleased: (id) control;
- (void) multiVolumeUpPressed: (id) control;
- (void) multiVolumeUpReleased: (id) control;
- (void) multiVolumeSyncPressed: (id) control;
- (void) multiVolumeMutePressed: (id) control;
- (void) multiVolumeOffPressed: (id) control;
- (void) multiVolumeCreatePressed: (id) control;
- (void) multiVolumeLeavePressed: (id) control;
- (void) multiVolumeCancelPressed: (id) control;

@end
