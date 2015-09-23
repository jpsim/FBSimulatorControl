/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <FBSimulatorControl/FBSimulator+Queries.h>
#import <FBSimulatorControl/FBSimulator.h>
#import <FBSimulatorControl/FBSimulatorApplication.h>
#import <FBSimulatorControl/FBSimulatorConfiguration.h>
#import <FBSimulatorControl/FBSimulatorControl+Private.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBSimulatorControl/FBSimulatorControlConfiguration.h>
#import <FBSimulatorControl/FBSimulatorPool.h>
#import <FBSimulatorControl/FBSimulatorSession.h>
#import <FBSimulatorControl/FBSimulatorSessionInteraction.h>
#import <FBSimulatorControl/FBSimulatorSessionLifecycle.h>
#import <FBSimulatorControl/FBSimulatorSessionState+Queries.h>
#import <FBSimulatorControl/FBSimulatorSessionState.h>
#import <FBSimulatorControl/FBSimulatorWindowTiler.h>

@interface FBSimulatorWindowTilingTests : XCTestCase

@property (nonatomic, strong) FBSimulatorControl *control;

@end

@implementation FBSimulatorWindowTilingTests

- (void)setUp
{
  FBSimulatorManagementOptions options =
  FBSimulatorManagementOptionsDeleteManagedSimulatorsOnFirstStart |
  FBSimulatorManagementOptionsKillUnmanagedSimulatorsOnFirstStart |
  FBSimulatorManagementOptionsDeleteOnFree;

  FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
    configurationWithSimulatorApplication:[FBSimulatorApplication simulatorApplicationWithError:nil]
    namePrefix:nil
    bucket:0
    options:options];

  self.control = [[FBSimulatorControl alloc] initWithConfiguration:configuration];
}

- (void)testTilesSingleiPhoneSimulatorInTopLeft
{
  NSError *error = nil;
  FBSimulatorSession *session = [self.control createSessionForSimulatorConfiguration:FBSimulatorConfiguration.iPhone5 error:&error];
  XCTAssertNotNil(session);
  XCTAssertNil(error);

  BOOL success = [[session.interact
    bootSimulator]
    performInteractionWithError:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error);

  FBSimulatorWindowTiler *tiler = [FBSimulatorWindowTiler withSimulator:session.simulator];
  CGRect position = [tiler placeInForegroundWithError:&error];
  XCTAssertNil(error);
  XCTAssertEqual(CGRectGetMinX(position), 0);
  XCTAssertEqual(CGRectGetMinX(position), 0);
}

- (void)testTilesMultipleiPhone5Horizontally
{
  FBSimulatorConfiguration *configuration = FBSimulatorConfiguration.iPhone5.scale50Percent;

  NSError *error = nil;
  FBSimulatorSession *firstSession = [self.control createSessionForSimulatorConfiguration:configuration error:&error];
  XCTAssertNotNil(firstSession);
  XCTAssertNil(error);

  BOOL success = [[firstSession.interact
    bootSimulator]
    performInteractionWithError:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error);

  FBSimulatorWindowTiler *tiler = [FBSimulatorWindowTiler withSimulator:firstSession.simulator];
  CGRect position = [tiler placeInForegroundWithError:&error];
  XCTAssertNil(error);
  XCTAssertEqual(CGRectGetMinX(position), 0);
  XCTAssertEqual(CGRectGetMinY(position), 0);

  FBSimulatorSession *secondSession = [self.control createSessionForSimulatorConfiguration:configuration error:&error];
  XCTAssertNotNil(secondSession);
  XCTAssertNil(error);

  success = [[secondSession.interact
    bootSimulator]
    performInteractionWithError:&error];
  XCTAssertTrue(success);
  XCTAssertNi3l(error);

  tiler = [FBSimulatorWindowTiler withSimulator:secondSession.simulator];
  position = [tiler placeInForegroundWithError:&error];
  XCTAssertNil(error);
  XCTAssertEqual(CGRectGetMinX(position), 160);
  XCTAssertEqual(CGRectGetMinY(position), 0);
}

@end
