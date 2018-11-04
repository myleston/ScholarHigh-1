//
//  TableViewController.swift
//  ScholarHighPrototype1
//
//  Created by 広瀬陽一 on 2018/10/15.
//  Copyright © 2018年 FRESHNESS. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth



class TableViewController: UITableViewController {

    @IBOutlet weak var classNameBar: UINavigationItem!
    @IBOutlet weak var classView: UITableView!
    

    // new declarations
     let db = Firestore.firestore()
    let schoolName = "ynu"
    var thisClass = Class(title: "計算理論", day: .Tue, period: 1, teacherName: "松本勉", classId: "ofJknO8lBmuiDVjEwNjO")
    var data: [String: Any]?
    var rooms = [Room]()
    var room: Room?
    var classRef: CollectionReference {
        return db
        .collection( ["schools", schoolName, "classes", thisClass.classId, "rooms"].joined(separator: "/"))
    }
    private var roomListener: ListenerRegistration?
    let user = Auth.auth().currentUser
    
    @IBAction func addNewRoom(_ sender: Any) {
        let controller: UIAlertController = UIAlertController(title: "新しい部屋をつくる", message: nil, preferredStyle: UIAlertController.Style.alert)
        
        controller.addAction(UIAlertAction(title: "決定",
                                           style: UIAlertAction.Style.default,
                                           handler:{(action) in
                                            let newRoomNameField = controller.textFields![0]
                                            if let roomName = newRoomNameField.text {
                                                if roomName == "" {
                                                    return
                                                }
                                                self.classRef.addDocument(data:  ["title": roomName, "latestTime": Timestamp(date: Date())])
                                            }
        }))
        controller.addAction(UIAlertAction(title: "キャンセル",
                                           style: UIAlertAction.Style.cancel,
                                           handler: nil))
        
        controller.addTextField(configurationHandler:){
            (newRoomNameField: UITextField?) -> Void in
            newRoomNameField?.placeholder = "部屋名を入力してください"
        }
        
        self.present(controller, animated: true, completion: nil)
    }
    
    
    @IBAction func signOut(_ sender: UIBarButtonItem) {
        let ac = UIAlertController(title: nil, message: "アカウントデータは残りません。本当にサインアウトしますか？", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "サインアウト", style: .destructive, handler: { _ in
            do {
                try Auth.auth().signOut()
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }))
        present(ac, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        

        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        roomListener = classRef.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            
            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        }
        
        classNameBar.title = thisClass.title
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        guard let room = Room(document: change.document) else {
            return
        }
        
        switch change.type {
        case .added:
            addChannelToTable(room)
            
        case .modified:
            updateChannelInTable(room)
            
        case .removed:
            removeChannelFromTable(room)
        }
    }
    
    private func addChannelToTable(_ room: Room) {
        guard !rooms.contains(room) else {
            return
        }
        
        rooms.append(room)
        rooms.sort(by: {$0 > $1})
        
        guard let index = rooms.index(of: room) else {
            return
        }
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    private func updateChannelInTable(_ room: Room) {
        guard let index = rooms.index(of: room) else {
            return
        }
        
        rooms[index] = room
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    private func removeChannelFromTable(_ room: Room) {
        guard let index = rooms.index(of: room) else {
            return
        }
        
        rooms.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return rooms.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "room", for: indexPath)
        cell.textLabel?.text = rooms[indexPath.row].title
        let format = DateFormatter()
        format.dateFormat = "HH:mm"
        cell.detailTextLabel?.text = format.string(from: rooms[indexPath.row].latestTime.dateValue())
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        room = rooms[indexPath.row]
        self.performSegue(withIdentifier: "toRoom", sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRoom" {
            let roomController: RoomController  = segue.destination as! RoomController
            roomController.thisClass = thisClass
            guard let room = room else {
                print("err: room")
                return
            }
            print("good: room")
            print(room)
            roomController.room = room
            print(roomController.room?.title)
            roomController.user = user
        }
        
    }
  
}
