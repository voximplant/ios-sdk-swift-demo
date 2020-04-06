/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

fileprivate struct ParticipantView {
    let id: String
    var view: ConferenceParticipantView
}

final class ConferenceView: UIView {
    private var enlargedParticipant: String?
    private var participantViews: [ParticipantView] = [] {
        didSet {
            if let myIndex = participantViews.firstIndex(where: { $0.id == myId}) { // because local video view always placed first
                if myIndex != 0 {
                    participantViews.rearrange(from: myIndex, to: 0)
                }
            }
        }
    }
    private var defaultParticipantView: ConferenceParticipantView {
        let view = ConferenceParticipantView()
        view.contentMode = .scaleAspectFit

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleParticipant))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        view.frame = CGRect(x: self.bounds.width / 2, y: self.bounds.height / 2, width: 0, height: 0)
        
        addSubview(view)
        
        return view
    }
    private var didDraw: Bool = false
    
    func addParticipant(withID id: String, displayName: String?) {
        guard participantViews.count < 25 else {
            print("Limit!")
            return
        }
        
        getView(for: id).name = displayName
        rearrange()
    }
    
    func updateParticipant(withID id: String, displayName: String?) {
        getView(for: id).name = displayName
        rearrange()
    }
    
    func removeParticipant(withId id: String) {
        removeView(for: id)
        rearrange()
    }
    
    func hideVideoRenderer(_ hide: Bool, for id: String) {
        if let view = participantViews[id] {
            view.streamView.isHidden = hide
        }
    }
    
    func prepareVideoRendererForStream(participantID: String, completion: (VIVideoRendererView) -> Void) {
        let participant = getView(for: participantID)
        participant.streamEnabled = true
        
        completion(VIVideoRendererView(containerView: participant.streamView))
    }
    
    func removeVideoStream(participantID: String) {
        getView(for: participantID).streamEnabled = false
    }
    
    // MARK: - Private -
    private func getView(for id: String) -> ConferenceParticipantView {
        if participantViews[id] == nil {
            participantViews.append(ParticipantView(id: id, view: defaultParticipantView))
        }

        return participantViews[id]!;
    }
    
    private func removeView(for id: String) {
        if let view = participantViews[id] {
            view.removeFromSuperview()
            participantViews.remove(for: id)
            
            if (id == enlargedParticipant) {
                enlargedParticipant = nil
            }
        }
    }

    private func rearrange() {
        DispatchQueue.main.async { () -> Void in
            let surface = self.bounds.size
            
            if let rootParticipant = self.enlargedParticipant {
                guard let rootParticipantView = self.participantViews[rootParticipant]
                    else { return }
                self.participantViews.forEach { $0.view.alpha = 0 }
                rootParticipantView.frame = CGRect(x: 0, y: 0, width: surface.width, height: surface.height)
                rootParticipantView.alpha = 1
                
            } else {
                var w, h: CGFloat

                switch self.participantViews.count {
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
                for (index, participantView) in self.participantViews.enumerated() {
                    participantView.view.alpha = 1
                    let x = index % Int(w)
                    let y = index / Int(w)
                    
                    participantView.view.frame = CGRect(origin: CGPoint(x: CGFloat(x) * size.width, y: CGFloat(y) * size.height), size: size)
                    participantView.view.layoutSubviews()
                }
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if !didDraw {
            rearrange()
            didDraw = true
        }
    }

    @objc private func toggleParticipant(_ sender: UIGestureRecognizer!) {
        if let participantView = sender.view as? ConferenceParticipantView,
            let id = participantViews[participantView] {
            enlargedParticipant = id == enlargedParticipant ? nil : id
        }
        rearrange()
    }
}

fileprivate extension Array where Element == ParticipantView {
    subscript(id: String) -> ConferenceParticipantView? {
        self.first{ $0.id == id }?.view
    }
    
    subscript(view: ConferenceParticipantView) -> String? {
        self.first{ $0.view == view }?.id
    }
    
    mutating func remove(for id: String) {
        if let index = self.firstIndex(where: { $0.id == id }) {
            self.remove(at: index)
        }
    }
}

fileprivate extension RangeReplaceableCollection where Indices: Equatable {
    mutating func rearrange(from: Index, to: Index) {
        precondition(from != to && indices.contains(from) && indices.contains(to), "invalid indices")
        insert(remove(at: from), at: to)
    }
}
