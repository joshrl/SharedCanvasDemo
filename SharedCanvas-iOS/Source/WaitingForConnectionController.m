//
//  WaitingForConnectionController.m
//  TouchMe-Peripheral
//
//  Created by Josh Rooke-Ley on 8/27/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import "WaitingForConnectionController.h"
#import "TouchService.h"

@interface WaitingForConnectionController ()
@property BOOL isAppBackgrounded;
@end

@implementation WaitingForConnectionController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
}

- (void)viewDidAppear:(BOOL)animated
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnected) name:kTouchCenralConnectedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onConnected
{
    
    if (self.isAppBackgrounded)
    {
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        notif.alertBody = @"You've been invited!";
        notif.fireDate =[NSDate date];
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    }
    else {
        [self performSegueWithIdentifier:@"onConnectSegue" sender:nil];
    }
    
}

- (void)onAppBackground:(NSNotification *)notification
{
    self.isAppBackgrounded=YES;
    [[TouchService sharedInstance] advertise];
    NSLog(@"App is backgrounded");
}

- (void)onAppForeground:(NSNotification *)notification
{
    if ([TouchService sharedInstance].isConnected)
    {
        [self onConnected];
    }
    self.isAppBackgrounded=NO;
    NSLog(@"App is foregrounded");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}


@end
