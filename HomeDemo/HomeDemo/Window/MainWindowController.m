//
//  MainWindowController.m
//  HomeDemo
//
//  Created by midoks on 2020/3/2.
//  Copyright © 2020 midoks. All rights reserved.
//

#import "MainWindowController.h"
#import "ListViewController.h"
#import <ContactsUI/ContactsUI.h>

@interface MainWindowController ()

@end

@implementation MainWindowController

-(id)init{
    self = [super initWithWindowNibName:@"MainWindowController"];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    
    NSSplitViewController *splitVC = [[NSSplitViewController alloc] init];
    
    ListViewController *listVC = [[ListViewController alloc] init];
    ListViewController *listVC2 = [[ListViewController alloc] init];
    
//    CNContactViewController *contactVC = [[CNContactViewController alloc] init];
//    [splitVC addChildViewController:contactVC];
    
    [splitVC addSplitViewItem: [NSSplitViewItem splitViewItemWithViewController:listVC]];
    [splitVC addSplitViewItem: [NSSplitViewItem splitViewItemWithViewController:listVC2]];
    
    self.window.contentViewController = splitVC;
}

@end
