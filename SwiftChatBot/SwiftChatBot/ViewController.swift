//
//  ViewController.swift
//  SwiftChatBot
//
//  Created by mac on 2017/4/17.
//  Copyright © 2017年 Meow.minithon.teama. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ApiAI
import RealmSwift

struct User {
    let id: String
    let Name: String
}

class ViewController: JSQMessagesViewController {

    var messages = [JSQMessage]()
    
    let user1 = User(id: "1", Name: "Michael")
    let user2 = User(id: "2", Name: "ChatBot")
    
    var currentUser: User {
        return user1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.senderId = currentUser.id
        self.senderDisplayName = currentUser.Name
        
        queryAllMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

// JSQMessagesCollectionViewDataSource protocol
extension ViewController {
    
    // MARK: - 訊息印出來
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text) {
            messages.append(message)
            self.finishSendingMessage(animated: true)
            sendTextToAgent(text: text)
        }
        
    }
    
    // MARK: - 多少訊息顯示
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // MARK: - 顯示哪個訊息
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    // MARK: - 定義好顯示使用者名稱
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]
        let messageUserName = message.senderDisplayName
        return NSAttributedString(string: messageUserName!)
    }
    
    // MARK: - 定義好bubblename 與框框距離
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    //MARK: - 頭像
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        
        if currentUser.id == message.senderId {
            return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named:"SongHyekyo")!, diameter: 30)
        } else {
            return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named:"KiAile")!, diameter: 30)
        }
    }
    
    // MARK: - 判斷使用者id顯示對話框顏色
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        let message = messages[indexPath.row]
        
        if currentUser.id == message.senderId {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: .green)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: .blue)
        }
    }

}

extension ViewController {
    
    //MARK: - write to Realm
    func storeMessage(_ senderName: String, _ senderID: String, _ senderMessage: String) {
        let message = Message()
        message.senderName = senderName
        message.senderID = senderID
        message.senderMessage = senderMessage
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(message)
        }
    }
    
    //MARK: - query from Realm
    func queryAllMessages() {
        let realm = try! Realm()
        let messages = realm.objects(Message.self)
        //讀進來是集合
        //for every message in the Realm
        for message in messages {
            // make each message as a JQMessage.
            let msg = JSQMessage(senderId: message.senderID, displayName: message.senderName, text: message.senderMessage)
            // append it to the JQMessage Array
            self.messages.append(msg!)
        }
    }
    //MARK: - send message to bot.
    func sendTextToAgent(text: String) {
        if text == "" { return }
        //由於是文字訊息，先準備一個textRequest
        let request = ApiAI.shared().textRequest()
        //設定要發送給Agent的訊息
        request?.query = text
        // 由於是Async Request, 要先設定Completion Block
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            guard let response = response as? AIResponse else {
                return
            }
            
            if let textResponse = response.result.fulfillment.speech {
                self.handleStoreBotMsg(textResponse)
            }
        }, failure: { (request, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
        
        //MARK: response是Any?型態，所以guard判別是否nil.串接api資料常遇到~
        let ok: SuccesfullResponseBlock! = { (request, response) in
            guard let response = response as? AIResponse  else {
                return
            }
            if let textResponse = response.result.fulfillment.speech {
                self.handleStoreBotMsg(textResponse)
            }
        }
        
        let failure: FailureResponseBlock! = { (request, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        request?.setMappedCompletionBlockSuccess(ok, failure: failure)
        
        
        
        
        ApiAI.shared().enqueue(request)
    }
    
    //MARK: - store message into Realm
    func handleStoreBotMsg(_ botMsg: String) {
        storeMessage(user2.Name, user2.id, botMsg)
        
        //store message into JSQMessage array
        let botMessage = JSQMessage(senderId: user2.id, displayName: user2.Name, text: botMsg)
        messages.append(botMessage!)
        finishSendingMessage(animated: true)
    }
    
}



