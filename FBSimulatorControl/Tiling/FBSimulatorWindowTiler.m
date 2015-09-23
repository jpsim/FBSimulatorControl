/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSimulatorWindowTiler.h"

#import "FBSimulator.h"
#import "FBSimulatorError.h"
#import "FBSimulatorPool.h"
#import "FBSimulatorPredicates.h"

#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

@interface FBSimulatorWindowTiler ()

@property (nonatomic, strong, readwrite) FBSimulator *simulator;

@end

@implementation FBSimulatorWindowTiler

+ (instancetype)withSimulator:(FBSimulator *)simulator
{
  FBSimulatorWindowTiler *tiler = [FBSimulatorWindowTiler new];
  tiler.simulator = simulator;
  return tiler;
}

- (CGRect)placeInForegroundWithError:(NSError **)error
{
  if (!AXIsProcessTrusted()) {
    return [[FBSimulatorError describe:@"Current process is untrusted"] failRect:error];
  }
  if (self.simulator.processIdentifier < 1) {
    return [[[FBSimulatorError describe:@"Cannot find Window ID"] inSimulator:self.simulator] failRect:error];
  }

  AXUIElementRef applicationElement = AXUIElementCreateApplication(self.simulator.processIdentifier);
  if (!applicationElement) {
    return [[[FBSimulatorError describe:@"Could not get an Application Element for process"] inSimulator:self.simulator] failRect:error];
  }

  // Bring to the front
  if (AXUIElementSetAttributeValue(applicationElement, (CFStringRef) NSAccessibilityFrontmostAttribute, kCFBooleanTrue) != kAXErrorSuccess) {
    return [[[FBSimulatorError describe:@"Could not make Simulator Application frontmost"] inSimulator:self.simulator] failRect:error];
  }

  // Get the Window
  AXUIElementRef windowElement = NULL;
  if (AXUIElementCopyAttributeValue(applicationElement, (CFStringRef) NSAccessibilityFocusedWindowAttribute, (CFTypeRef *) &windowElement) != kAXErrorSuccess) {
    return [[[FBSimulatorError describe:@"Could not get the Window Element for the forground Simulator"] inSimulator:self.simulator] failRect:error];
  }

  // Position at the appropriate position.
  NSError *innerError = nil;
  CGPoint position = [self bestFittingPositionWithError:&innerError];
  if (position.x < 0 || position.y < 0) {
    return [[[[FBSimulatorError describe:@"Could not find the best fit for the tiled window"] inSimulator:self.simulator] causedBy:innerError] failRect:error];
  }
  AXValueRef positionValue = AXValueCreate(kAXValueTypeCGPoint, (void *) &position);
  if (AXUIElementSetAttributeValue(windowElement, (CFStringRef) NSAccessibilityPositionAttribute, (CFTypeRef *) positionValue) != kAXErrorSuccess) {
    return [[[FBSimulatorError describe:@"Could not set the position for the Window element"] inSimulator:self.simulator] failRect:error];
  }

  // Get the true bounds
  CGSize size = CGSizeZero;
  AXValueRef sizeValue = NULL;
  if (AXUIElementCopyAttributeValue(windowElement, (CFStringRef) NSAccessibilitySizeAttribute, (CFTypeRef *) &sizeValue) != kAXErrorSuccess) {
    return [[[FBSimulatorError describe:@"Could not get the size of the Window element"] inSimulator:self.simulator] failRect:error];
  }
  if (!AXValueGetValue(sizeValue, kAXValueTypeCGSize, (void *) &size)) {
    return [[[FBSimulatorError describe:@"Could not extract the Size struct from the value"] inSimulator:self.simulator] failRect:error];
  }

  return (CGRect) {position, size};
}

- (CGPoint)bestFittingPositionWithError:(NSError **)error
{
  // TODO: Have a true position rather than the maximal x-position.
  CGPoint point = CGPointZero;
  for (NSValue *windowBoundsValue in [self obtainBoundsOfOtherSimulators]) {
    point.x = MAX(point.x, CGRectGetMaxX(windowBoundsValue.rectValue));
  }
  return point;
}

- (NSArray *)obtainBoundsOfOtherSimulators
{
  NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
    [FBSimulatorPredicates launched],
    [NSCompoundPredicate notPredicateWithSubpredicate:[FBSimulatorPredicates only:self.simulator]],
  ]];
  NSOrderedSet *simulators = [self.simulator.pool.allSimulators filteredOrderedSetUsingPredicate:predicate];
  NSArray *windows = [FBSimulatorWindowTiler windowsForSimulators:simulators];

  NSMutableArray *boundsValues = [NSMutableArray array];
  for (NSDictionary *window in windows) {
    NSDictionary *boundsDictionary = window[(NSString *)kCGWindowBounds];
    CGRect windowBounds = CGRectZero;
    if (!CGRectMakeWithDictionaryRepresentation((CFDictionaryRef) boundsDictionary, &windowBounds)) {
      continue;
    }
    [boundsValues addObject:[NSValue valueWithRect:windowBounds]];
  }
  return [boundsValues copy];
}

+ (NSArray *)windowsForSimulators:(NSOrderedSet *)simulators
{
  NSArray *windows = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID));

  NSOrderedSet *pids = [simulators valueForKey:@"processIdentifier"];
  NSPredicate *pidPredicate = [NSPredicate predicateWithBlock:^ BOOL (NSDictionary *window, NSDictionary *_) {
    NSNumber *processIdentifier = window[(NSString *)kCGWindowOwnerPID];
    return [pids containsObject:processIdentifier];
  }];
  // There are a bunch of other 'Windows' with strange bounds. We just care about the named one.
  NSPredicate *namePredicate = [NSPredicate predicateWithBlock:^ BOOL (NSDictionary *window, NSDictionary *_) {
    NSString *windowName = window[(NSString *)kCGWindowName];
    return windowName.length > 0;
  }];
  NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
    pidPredicate,
    namePredicate
  ]];

  return [windows filteredArrayUsingPredicate:predicate];
}

@end
