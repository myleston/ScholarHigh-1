//
//  AppSettings.swift
//  ScholarHighPrototype1
//
//  Created by 広瀬陽一 on 2018/10/27.
//  Copyright © 2018 FRESHNESS. All rights reserved.
//

import Foundation
import Firebase
import MessageKit

final class AppDefs {
    static var displayName: String = ""
}

enum Day {
    case Mon
    case Tue
    case Wed
    case Thu
    case Fri
    case Sat
    case Sun
}

struct Class {
    let title: String
    let day: Day
    let period: Int
    let teacherName: String
    let classId: String
}

struct Room {
    let title: String
    let latestTime: Timestamp
    let roomId: String
    
    init(title: String, latestTime: Timestamp, roomId: String) {
        self.title = title
        self.latestTime = latestTime
        self.roomId = roomId
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let title = data["title"] as? String else {
            return nil
        }
        self.title = title
        
        guard let time = data["latestTime"] as? Timestamp else {
            return nil
        }
        self.latestTime = time
        
        self.roomId = document.documentID
    }
}

extension Room: Comparable {
    
    static func == (lhs: Room, rhs: Room) -> Bool {
        return lhs.roomId == rhs.roomId
    }
    static func < (lhs: Room, rhs: Room) -> Bool {
        return lhs.latestTime.dateValue() < rhs.latestTime.dateValue()
    }
    
    
}

struct Image: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
}

struct Message: MessageType {
  
    let messageId: String
    let sender: Sender
    let sentDate: Date
    var image: Image?
    let content: String
    var kind: MessageKind {
        if let image = image {
            return .photo(image)
        } else {
            return .text(content)
        }
    }
    
    init(messageId: String, sender: Sender, sentDate: Date, content: String) {
        self.messageId = messageId
        self.sender = sender
        self.sentDate = sentDate
        self.content = content
        self.image?.image = nil
        self.image?.url = nil
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let senderId = data["senderId"] as? String,
            let senderDisplayName =  data["senderDisplayName"] as? String else {
            return nil
        }
        guard let time = data["sentDate"] as? Timestamp else {
            return nil
        }
        guard let content = data["content"] as? String else {
            return nil
        }
         self.sender = Sender(id: senderId, displayName: senderDisplayName)
        self.sentDate = time.dateValue()
        self.content = content
        self.messageId = document.documentID
        self.image = nil
        self.image?.url = nil
    }
    
    init(user: User, content: String) {
        sender = Sender(id: user.uid, displayName: AppDefs.displayName)
        self.content = content
        sentDate = Date()
        // ignoring messageId
        self.messageId = "0"
    }
    
}

extension Message: Comparable {
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.messageId == rhs.messageId
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
    
}
protocol DatabaseRepresentation {
    var representation: [String: Any] { get }
}

extension Message: DatabaseRepresentation {
    
    var representation: [String : Any] {
        var rep: [String : Any] = [
            "created": sentDate,
            "senderID": sender.id,
            "senderName": sender.displayName
        ]
        
        if let url = image?.url {
            rep["url"] = url.absoluteString
        } else {
            rep["content"] = content
        }
        
        return rep
    }
    
}


extension UIColor {
    
    static var primary: UIColor {
        return UIColor(red: 1 / 255, green: 93 / 255, blue: 48 / 255, alpha: 1)
    }
    
    static var incomingMessage: UIColor {
        return UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
    }
    
}
