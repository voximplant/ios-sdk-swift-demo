/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

extension String {
    var appendingVoxDomain: String { "\(self).voximplant.com" }

    func toNode() -> VIConnectionNode? {
        switch self {
        case "Node 1":
            return .node1
        case "Node 2":
            return .node2
        case "Node 3":
            return .node3
        case "Node 4":
            return .node4
        case "Node 5":
            return .node5
        case "Node 6":
            return .node6
        case "Node 7":
            return .node7
        case "Node 8":
            return .node8
        case "Node 9":
            return .node9
        case "Node 10":
            return .node10
        default:
            return nil
        }
    }
}
