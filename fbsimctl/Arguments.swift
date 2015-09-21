/**
* Copyright (c) 2015-present, Facebook, Inc.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import Foundation

public enum SimulatorFormat {
  case UUID

  public func format(simulator: FBSimulator) -> String {
    switch (self) {
      case UUID: return simulator.udid
    }
  }

  public static func format(format: [SimulatorFormat], simulator: FBSimulator) -> String {
    return format.reduce("") { previous, current in
      return previous + " " + current.format(simulator)
    }
  }
}

public enum SimulatorQuery {
  case All

  public func get(pool: FBSimulatorPool) -> [FBSimulator] {
    switch (self) {
      case .All: return pool.allPooledSimulators.array as! [FBSimulator]
    }
  }
}

public enum Command {
  case List(SimulatorQuery, [SimulatorFormat])
  case Help

  public static func parseArguments(args: [String]) -> Command {
    if (args.count == 0) {
      return .Help
    }
    return .List(.All, [.UUID])
  }

  public func run() -> Void {
    let application = try! FBSimulatorApplication(error: ())
    let config = FBSimulatorControlConfiguration(simulatorApplication: application, namePrefix: "E2E", bucket: 0, options: .DeleteOnFree)
    let control = FBSimulatorControl(configuration: config)

    switch (self) {
      case .Help:
        printHelp()
      case .List(let query, let format):
        print(query.get(control.simulatorPool).map {SimulatorFormat.format(format, simulator: $0)})
    }
  }

  private func printHelp() -> Void {
    let help : [Command] = []
    print(help)
  }

  private func description() -> String {
    switch (self) {
      case .Help: return "Prints Help"
      case .List: return "Lists Simulators"
    }
  }
}
