//
//  UIViewController+ScrollingNavbar.m
//  ScrollingNavbarDemo
//
//  Created by Andrea on 24/03/14.
//  Copyright (c) 2014 Andrea Mazzini. All rights reserved.
//

#import "UIViewController+ScrollingNavbar.h"
#import <objc/runtime.h>

@implementation UIViewController (ScrollingNavbar)

- (void)setPanGesture:(UIPanGestureRecognizer*)panGesture {	objc_setAssociatedObject(self, @selector(panGesture), panGesture, OBJC_ASSOCIATION_RETAIN); }
- (UIPanGestureRecognizer*)panGesture {	return objc_getAssociatedObject(self, @selector(panGesture)); }

- (void)setScrollableView:(UIView*)scrollableView {	objc_setAssociatedObject(self, @selector(scrollableView), scrollableView, OBJC_ASSOCIATION_RETAIN); }
- (UIView*)scrollableView {	return objc_getAssociatedObject(self, @selector(scrollableView)); }

- (void)setOverlay:(UIView*)overlay { objc_setAssociatedObject(self, @selector(overlay), overlay, OBJC_ASSOCIATION_RETAIN); }
- (UIView*)overlay { return objc_getAssociatedObject(self, @selector(overlay)); }

- (void)setCollapsed:(BOOL)collapsed { objc_setAssociatedObject(self, @selector(collapsed), [NSNumber numberWithBool:collapsed], OBJC_ASSOCIATION_RETAIN); }
- (BOOL)collapsed {	return [objc_getAssociatedObject(self, @selector(collapsed)) boolValue]; }

- (void)setExpanded:(BOOL)expanded { objc_setAssociatedObject(self, @selector(expanded), [NSNumber numberWithBool:expanded], OBJC_ASSOCIATION_RETAIN); }
- (BOOL)expanded {	return [objc_getAssociatedObject(self, @selector(expanded)) boolValue]; }

- (void)setLastContentOffset:(float)lastContentOffset { objc_setAssociatedObject(self, @selector(lastContentOffset), [NSNumber numberWithFloat:lastContentOffset], OBJC_ASSOCIATION_RETAIN); }
- (float)lastContentOffset { return [objc_getAssociatedObject(self, @selector(lastContentOffset)) floatValue]; }

- (void)setMaxDelay:(float)maxDelay { objc_setAssociatedObject(self, @selector(maxDelay), [NSNumber numberWithFloat:maxDelay], OBJC_ASSOCIATION_RETAIN); }
- (float)maxDelay { return [objc_getAssociatedObject(self, @selector(maxDelay)) floatValue]; }

- (void)setDelayDistance:(float)delayDistance { objc_setAssociatedObject(self, @selector(delayDistance), [NSNumber numberWithFloat:delayDistance], OBJC_ASSOCIATION_RETAIN); }
- (float)delayDistance { return [objc_getAssociatedObject(self, @selector(delayDistance)) floatValue]; }

- (void)followScrollView:(UIView*)scrollableView
{
	[self followScrollView:scrollableView withDelay:0];
}

- (void)followScrollView:(UIView*)scrollableView withDelay:(float)delay
{
	self.scrollableView = scrollableView;
	
	self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	[self.panGesture setMaximumNumberOfTouches:1];
	
	[self.panGesture setDelegate:self];
	[self.scrollableView addGestureRecognizer:self.panGesture];
	
	/* The navbar fadeout is achieved using an overlay view with the same barTintColor.
	 this might be improved by adjusting the alpha component of every navbar child */
	CGRect frame = self.navigationController.navigationBar.frame;
	frame.origin = CGPointZero;
	self.overlay = [[UIView alloc] initWithFrame:frame];
    
    // Use tintColor instead of barTintColor on iOS < 7
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
        if (!self.navigationController.navigationBar.barTintColor) {
            NSLog(@"[%s]: %@", __PRETTY_FUNCTION__, @"[AMScrollingNavbarViewController] Warning: no bar tint color set");
        }
        [self.overlay setBackgroundColor:self.navigationController.navigationBar.barTintColor];
    } else {
        [self.overlay setBackgroundColor:self.navigationController.navigationBar.tintColor];
    }
	
	if ([self.navigationController.navigationBar isTranslucent]) {
		NSLog(@"[%s]: %@", __PRETTY_FUNCTION__, @"[AMScrollingNavbarViewController] Warning: the navigation bar should not be translucent");
	}
	
	[self.overlay setUserInteractionEnabled:NO];
	[self.overlay setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[self.navigationController.navigationBar addSubview:self.overlay];
	[self.overlay setAlpha:0];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didBecomeActive:)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	
	self.maxDelay = delay;
	self.delayDistance = delay;
}

- (void)didBecomeActive:(id)sender
{
	[self showNavbar];
}

// NOTE: you should implement this in your view controller's instance when using this category
//- (void)viewWillDisappear:(BOOL)animated
//{
//	[super viewWillDisappear:animated];
//	[self showNavbar];
//}
//
//- (void)viewWillAppear:(BOOL)animated
//{
//	[super viewWillAppear:animated];
//	[self refreshNavbar];
//}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect frame = self.overlay.frame;
	frame.size.height = self.navigationController.navigationBar.frame.size.height;
	self.overlay.frame = frame;
    
    [self updateSizingWithDelta:0]; // Refresh sizes on rotation
}

- (float)deltaLimit
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return ([[UIApplication sharedApplication] isStatusBarHidden]) ? 44 : 24;
    } else {
		if ([[UIApplication sharedApplication] isStatusBarHidden]) {
			return (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 44 : 32);
		} else {
			return (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 24 : 12);
		}
    }
}

- (float)statusBar
{
	return ([[UIApplication sharedApplication] isStatusBarHidden]) ? 0 : 20;
}

- (float)compatibilityHeight
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return ([[UIApplication sharedApplication] isStatusBarHidden]) ? 44 : 64;
    } else {
		if ([[UIApplication sharedApplication] isStatusBarHidden]) {
			return (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 44 : 32);
		} else {
			return (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 64 : 52);
		}
    }
}

- (void)showNavBarAnimated:(BOOL)animated
{
	NSTimeInterval interval = animated ? 0.2 : 0;
	if (self.scrollableView != nil) {
		if (self.collapsed) {
			CGRect rect;
			if ([self.scrollableView isKindOfClass:[UIWebView class]]) {
				rect = ((UIWebView*)self.scrollableView).scrollView.frame;
			} else {
				rect = self.scrollableView.frame;
			}
			rect.origin.y = 0;
			if ([self.scrollableView isKindOfClass:[UIWebView class]]) {
				((UIWebView*)self.scrollableView).scrollView.frame = rect;
			} else {
				self.scrollableView.frame = rect;
			}
			[UIView animateWithDuration:interval animations:^{
				self.lastContentOffset = 0;
				[self scrollWithDelta:-self.compatibilityHeight];
			}];
		} else {
			[self updateNavbarAlpha:self.compatibilityHeight];
		}
	}
}

- (void)showNavbar
{
	[self showNavBarAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (void)setScrollingEnabled:(BOOL)enabled
{
	self.panGesture.enabled = enabled;
}

- (void)handlePan:(UIPanGestureRecognizer*)gesture
{
	CGPoint translation = [gesture translationInView:[self.scrollableView superview]];
	
	float delta = self.lastContentOffset - translation.y;
	self.lastContentOffset = translation.y;
	
	[self scrollWithDelta:delta];
	
	if ([gesture state] == UIGestureRecognizerStateEnded) {
		// Reset the nav bar if the scroll is partial
		self.lastContentOffset = 0;
		[self checkForPartialScroll];
	}
}

- (void)scrollWithDelta:(CGFloat)delta
{
	CGRect frame;
	
	if (delta > 0) {
		if (self.collapsed) {
			return;
		}
		
		if (self.expanded) {
            self.expanded = NO;
        }
		
		frame = self.navigationController.navigationBar.frame;
		
		if (frame.origin.y - delta < -self.deltaLimit) {
			delta = frame.origin.y + self.deltaLimit;
		}
		
		frame.origin.y = MAX(-self.deltaLimit, frame.origin.y - delta);
		self.navigationController.navigationBar.frame = frame;
		
		if (frame.origin.y == -self.deltaLimit) {
			self.collapsed = YES;
			self.expanded = NO;
			self.delayDistance = self.maxDelay;
		}
		
		[self updateSizingWithDelta:delta];
	}
	
	if (delta < 0) {
		if (self.expanded) {
			return;
		}
		
		if (self.collapsed) {
            self.collapsed = NO;
        }
		
		self.delayDistance += delta;
		
		if (self.delayDistance > 0) {
			return;
		}
		
		frame = self.navigationController.navigationBar.frame;
		
		if (frame.origin.y - delta > self.statusBar) {
			delta = frame.origin.y - self.statusBar;
		}
		frame.origin.y = MIN(20, frame.origin.y - delta);
		self.navigationController.navigationBar.frame = frame;
		
		if (frame.origin.y == self.statusBar) {
			self.expanded = YES;
			self.collapsed = NO;
		}
		
		[self updateSizingWithDelta:delta];
	}
}

- (void)checkForPartialScroll
{
	CGFloat pos = self.navigationController.navigationBar.frame.origin.y;
	
	// Get back down
	if (pos >= -2) {
		[UIView animateWithDuration:0.2 animations:^{
			CGRect frame;
			frame = self.navigationController.navigationBar.frame;
			CGFloat delta = frame.origin.y - self.statusBar;
			frame.origin.y = MIN(20, frame.origin.y - delta);
			self.navigationController.navigationBar.frame = frame;
			
			self.expanded = YES;
			self.collapsed = NO;
			
			[self updateSizingWithDelta:delta];
		}];
	} else {
		// And back up
		[UIView animateWithDuration:0.2 animations:^{
			CGRect frame;
			frame = self.navigationController.navigationBar.frame;
			CGFloat delta = frame.origin.y + self.deltaLimit;
			frame.origin.y = MAX(-self.deltaLimit, frame.origin.y - delta);
			self.navigationController.navigationBar.frame = frame;
			
			self.expanded = NO;
			self.collapsed = YES;
			self.delayDistance = self.maxDelay;
			
			[self updateSizingWithDelta:delta];
		}];
	}
}

- (void)updateSizingWithDelta:(CGFloat)delta
{
	[self updateNavbarAlpha:delta];
	
	// At this point the navigation bar is already been placed in the right position, it'll be the reference point for the other views'sizing
	CGRect frameNav = self.navigationController.navigationBar.frame;
	
	// Move and expand (or shrink) the superview of the given scrollview
	CGRect frame = self.scrollableView.superview.frame;
    frame.origin.y = frameNav.origin.y + frameNav.size.height;
	frame.size.height = [UIScreen mainScreen].bounds.size.height - frame.origin.y;
	self.scrollableView.superview.frame = frame;
}

- (void)updateNavbarAlpha:(CGFloat)delta
{
	CGRect frame = self.navigationController.navigationBar.frame;
	
	// Change the alpha channel of every item on the navbr. The overlay will appear, while the other objects will disappear, and vice versa
	float alpha = (frame.origin.y + self.deltaLimit) / frame.size.height;
	[self.overlay setAlpha:1 - alpha];
	[self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* obj, NSUInteger idx, BOOL *stop) {
		obj.customView.alpha = alpha;
	}];
	[self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* obj, NSUInteger idx, BOOL *stop) {
		obj.customView.alpha = alpha;
	}];
	self.navigationItem.titleView.alpha = alpha;
	self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}

- (void)refreshNavbar
{
	if (self.scrollableView != nil) {
		[self.navigationController.navigationBar bringSubviewToFront:self.overlay];
	}
}

@end
