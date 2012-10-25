//
//  ViewController.m
//  CBPeripheral
//
//  Created by Josh Rooke-Ley on 8/14/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import "ConnectedController.h"
#import "TouchService.h"

@interface ConnectedController ()

@end

@implementation ConnectedController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDisconnected) name:kTouchCentralDisconnectedNotification object:nil];
}

- (void)onDisconnected
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [TouchService sharedInstance].view = self.view;
}

- (BOOL)shouldAutorotate
{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


#pragma mark - UIResponder

//Forward ui events to the touch service...
- (UIResponder *)nextResponder {
    return [TouchService sharedInstance];
}

@end
