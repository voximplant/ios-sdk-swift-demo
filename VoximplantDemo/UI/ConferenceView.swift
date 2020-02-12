/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

class ConferenceView: UIView {
    var enlargedParticipant: String?
    var participants: [String: UIImageView] = [:]
    let participantAvatar = UIImage(named: "ic_person")?.withRenderingMode(.alwaysTemplate)

    private func createView(for id: String!) -> UIImageView {
        if self.participants[id] == nil {
            let participant = UIImageView(image: participantAvatar)
            participant.contentMode = .scaleAspectFit
            participant.tintColor = UIColor.random

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleParticipant))
            participant.isUserInteractionEnabled = true
            participant.addGestureRecognizer(tapGesture)
            participant.frame = CGRect(x: self.bounds.width / 2, y: self.bounds.height / 2, width: 0, height: 0)

            self.addSubview(participant)

            self.participants[id] = participant
        }

        return self.participants[id]!;
    }

    private func removeView(for id: String!) {
        if let participant = self.participants[id] {
            self.participants.removeValue(forKey: id)
            participant.removeFromSuperview()

            if (id == self.enlargedParticipant) {
                self.enlargedParticipant = nil
            }
        }
    }

    func addParticipant(_ endpoint: VIEndpoint!) {
        guard self.participants.count < 25 else {
            Log.e("Limit!")
            return
        }

        if endpoint.remoteVideoStreams.count > 0 {
            for videoStream in endpoint.remoteVideoStreams {
                self.addVideoStream(endpoint, videoStream: videoStream)
            }
        } else {
            _ = self.createView(for: endpoint.endpointId)
        }

        self.rearrange()
    }

    func updateParticipant(_ endpoint: VIEndpoint!) {
        Log.d("\(#function)")

        self.rearrange()
    }

    func removeParticipant(_ endpoint: VIEndpoint!) {
        self.removeView(for: endpoint.endpointId)

        self.rearrange()
    }

    func addVideoStream(_ endpoint: VIEndpoint!, videoStream: VIVideoStream!) {
        self.removeView(for: endpoint.endpointId)

        let participant = createView(for: videoStream.streamId)
        participant.image = nil

        let viewRenderer = VIVideoRendererView(containerView: participant)
        videoStream.addRenderer(viewRenderer)

        self.rearrange()
    }

    func removeVideoStream(_ endpoint: VIEndpoint!, videoStream: VIVideoStream!) {
        videoStream.removeAllRenderers()
        self.removeView(for: videoStream.streamId)

        if endpoint.remoteVideoStreams.count == 0 {
            _ = self.createView(for: endpoint.endpointId)
        }

        self.rearrange()
    }

    fileprivate func rearrange() {
        DispatchQueue.main.async { () -> Void in
            let surface = self.bounds.size

            if let rootParticipant = self.enlargedParticipant {
                var participants = self.participants
                participants.removeValue(forKey: rootParticipant)

                var w, h: CGFloat

                switch participants.count {
                case 7..<9:
                    w = 1; h = 2
                case 9..<11:
                    w = 2; h = 2
                case 11..<13:
                    w = 3; h = 2
                case 13..<16:
                    w = 3; h = 3
                case 16..<19:
                    w = 4; h = 3
                case 19..<23:
                    w = 4; h = 4
                case 23..<26:
                    w = 5; h = 4
                default:
                    w = 0; h = 0
                }

                let size = CGSize(width: surface.width / w, height: surface.height / (2 * h))

                UIView.animate(withDuration: 0.2) {
                    self.participants[rootParticipant]!.frame = CGRect(x: surface.width / 4, y: 0, width: surface.width / 2, height: surface.height / 2)
                    self.participants[rootParticipant]!.layoutSubviews()
                    for (index, (key:_, value:participant)) in participants.enumerated() {
                        if (index < 6) {
                            let side = index % 2
                            let level = index / 2
                            participant.frame = CGRect(x: (surface.width * 0.75) * CGFloat(side), y: (surface.height / 6) * CGFloat(level), width: surface.width / 4, height: surface.height / 6)
                            participant.layoutSubviews()
                        } else {
                            let idx = index - 6
                            let x = idx % Int(w)
                            let y = idx / Int(w)

                            participant.frame = CGRect(origin: CGPoint(x: CGFloat(x) * size.width, y: CGFloat(y) * size.height + surface.height / 2), size: size)
                            participant.layoutSubviews()
                        }
                    }
                }
            } else {
                var w, h: CGFloat

                switch self.participants.count {
                case 0..<2:
                    w = 1; h = 1
                case 2:
                    w = 1; h = 2
                case 3..<5:
                    w = 2; h = 2
                case 5..<7:
                    w = 3; h = 2
                case 7..<10:
                    w = 3; h = 3
                case 10..<13:
                    w = 4; h = 3
                case 13..<17:
                    w = 4; h = 4
                case 17..<21:
                    w = 5; h = 4
                case 21..<26:
                    w = 5; h = 5
                default:
                    fatalError("Stack Overflow =P")
                }

                let size = CGSize(width: surface.width / w, height: surface.height / h)

                UIView.animate(withDuration: 0.2) {
                    for (index, (key:_, value:participant)) in self.participants.enumerated() {
                        let x = index % Int(w)
                        let y = index / Int(w)

                        participant.frame = CGRect(origin: CGPoint(x: CGFloat(x) * size.width, y: CGFloat(y) * size.height), size: size)
                        participant.layoutSubviews()
                    }
                }
            }
        }
    }

    @objc fileprivate func toggleParticipant(_ sender: UIGestureRecognizer!) {
        if let participant = sender.view, let endpointId = ((self.participants as NSDictionary).allKeys(for: participant) as! [String]).first {
            if endpointId == self.enlargedParticipant {
                self.enlargedParticipant = nil
            } else {
                self.enlargedParticipant = endpointId
            }
        }

        self.rearrange()
    }
}


extension CGFloat {
    static var random: CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random, green: .random, blue: .random, alpha: 1.0)
    }
}
