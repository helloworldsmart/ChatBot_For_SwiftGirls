//
//  ViewController.swift
//  chatbotTutorial
//
//  Created by mac on 2017/4/11.
//  Copyright © 2017年 Meow.minithon.teama. All rights reserved.
//

import UIKit
import RealmSwift
import JSQMessagesViewController
import ApiAI

struct User {
    let id: String
    let name: String
}

class ViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    
    var outputTextView:UITextView!
    
    let user1 = User(id: "1", name: "Michael")
    let user2 = User(id: "2", name: "Chatbot")
    
    var currentUser: User {
        return user1
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.senderId = currentUser.id
        self.senderDisplayName = currentUser.name
        
        queryAllMessages()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// user - defined functions
extension ViewController {
    
    //add改成store
    func addMessage(_ senderName: String, _ senderID: String, _ senderMessage: String) {
        let message = Message()
        message.senderName = senderName
        message.senderID = senderID
        message.senderMessage = senderMessage
        
        //write to Realm
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(message)
        }
    }
    
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
    
    func handleSendMessageToBot(_ message: String) {
        let request = ApiAI.shared().textRequest()
        
        request?.query = message
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            
            if let responseFromAI = response.result.fulfillment.speech as? String {
                self.handleStoreBotMsg(responseFromAI)
            }
        }, failure: { (request, error) in
            print(error!)
        })
        
        // send message to bot.
        ApiAI.shared().enqueue(request)
    }
    
    //re
    func handleStoreBotMsg(_ botMsg: String) {
        //store message into Realm
        addMessage(user2.name, user2.id, botMsg)
        
        //store message into JSQMessage array
        let botMessage = JSQMessage(senderId: user2.id, displayName: user2.name, text: botMsg)
        messages.append(botMessage!)
        finishSendingMessage()
    }
    
}

//functions for JSQMessagesCollectionViewDataSource protocol
extension ViewController {
    
    // MARK: - 訊息印出來
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        //print("Hello")
    
        self.addMessage(senderDisplayName, senderId, text)
        
        // store message into JSQMessage Array
        
        let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        
        messages.append(message!)
        
        handleSendMessageToBot(text)
        
        finishSendingMessage()
        
        /*
        if let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text) {
            messages += [message]
            self.finishSendingMessage(animated: true)
            sendTextToAgent(text: text)
        }
         */
        
        
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
    
    // MARK: - 多少訊息顯示
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // MARK: - 顯示哪個訊息
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
}


//MARK:- APPCODE
extension ViewController {
    
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
                self.outputTextView.text = self.outputTextView.text.appending("\(textResponse)\n")
            }
            
            if let action = response.result.action {
                self.outputTextView.text = self.outputTextView.text.appending("Action: \(action)\n\n")
            }
            let range = NSMakeRange(self.outputTextView.text.characters.count - 1, 0)
            self.outputTextView.scrollRangeToVisible(range)
        }, failure: { (request, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
        ApiAI.shared().enqueue(request)
    }
}

