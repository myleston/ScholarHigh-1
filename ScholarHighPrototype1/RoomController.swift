//
//  RoomController.swift
//  ScholarHighPrototype1
//
//  Created by 広瀬陽一 on 2018/10/16.
//  Copyright © 2018年 FRESHNESS. All rights reserved.
//

import UIKit
import MessageKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

final class RoomController: MessagesViewController {
    
    let schoolName = "ynu"
    var thisClass: Class?
    var messages = [Message]()
    var room: Room?
    let db = Firestore.firestore()
    var roomRef: CollectionReference? {
        if let unwrappedClass = thisClass, let unwrappedRoom = room {
            return db
                .collection( ["schools", schoolName, "classes", unwrappedClass.classId, "rooms", unwrappedRoom.roomId, "messages"].joined(separator: "/") )
        }
        return nil
    }
    var messageListener: ListenerRegistration?
    var user: User!
    
    deinit {
        messageListener?.remove()
    }
    
    
    
    
    @IBOutlet weak var roomNameBar: UINavigationItem!
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
    
        roomNameBar.title = self.room?.title
        
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
     
        
        guard let roomRef = roomRef else {
            return
        }
        
        messageListener = roomRef.addSnapshotListener { querySnapshot, error in
          
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
           
            snapshot.documentChanges.forEach { change in
            
                self.handleDocumentChange(change)
            }
            
        }
        
    }
        
    func handleDocumentChange(_ change: DocumentChange) {
        guard let message = Message(document: change.document) else {
            
            return
        }
        print(message.kind)
        
        switch change.type {
            case .added:
                
                insertNewMessage(message)
           
            default:
            break
        }
    }
    
    private func insertNewMessage(_ message: Message) {
        guard !messages.contains(message) else {
            return
        }
        print(message)
        messages.append(message)
        messages.sort()
     
        let isLatestMessage = messages.index(of: message) == (messages.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        
        messagesCollectionView.reloadData()
        
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func save(_ message: Message) {
        roomRef?.addDocument(data: message.representation) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            
            self.messagesCollectionView.scrollToBottom()
        }
    }
}



    
extension RoomController: MessagesDisplayDelegate {
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .primary : .incomingMessage
    }
    
    
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
}

// MARK: - MessagesLayoutDelegate

extension RoomController: MessagesLayoutDelegate {
    
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
}

// MARK: - MessagesDataSource

extension RoomController: MessagesDataSource {
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    func currentSender() -> Sender {
        return Sender(id: user.uid, displayName: AppDefs.displayName)
    }
    
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let time = message.sentDate
        let df = DateFormatter()
        df.dateFormat = "hh:mm"
        let timeStr = df.string(from: time)
        return NSAttributedString(
            string: timeStr,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }
    
}

// MARK: - MessageInputBarDelegate

extension RoomController: MessageInputBarDelegate {
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let message = Message(user: user, content: text)
        
        save(message)
        inputBar.inputTextView.text = ""
    }
    
}

/*
// MARK: - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destination.
    // Pass the selected object to the new view controller.
}
*/
extension UIScrollView {
    
    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }
    
    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
    
}

