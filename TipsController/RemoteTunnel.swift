//
//  RemoteTunnel.swift
//  TipsController
//
//  Created by Prasan Dhareshwar on 1/16/21.
//

import Foundation
//import SocketIO

struct RemoteTunnel {
    var username: String = "sofa.tips.jr@gmail.com"
    var password: String = "wZB#:{8zvY}-@2%E"
    var devSecret: String = "RjVDNjkzMTgtMjEyOS00ODlGLTk0QzMtOTcxRDAzQ0FCMDcw"
    var devId: String = "80:00:00:00:01:09:3A:54"
    var status: String?
    
    var inputstream: InputStream?
    var outputstream: OutputStream?
    
    init() {
        var token: String?
        var url: String?
        var port: Int?
        var status: String?
        let group = DispatchGroup()
        
        group.enter()
        self.getToken(username: self.username, password: self.password, secret: self.devSecret) { authJSON in
            token = authJSON["token"] as? String
//            print(authJSON)
            group.leave()
        }
        
        group.wait()
        
        group.enter()
        self.getProxy(token: token!, id: self.devId, secret: self.devSecret) { proxyJSON in
            let connection = proxyJSON["connection"] as! [String: Any]
            url = connection["proxyserver"] as! String
            port = Int(connection["proxyport"] as! String)
//            status = connection["status"] as! String
            group.leave()
        }
        
        group.wait()
        
        
        let _ = initNetworkCommunication(url: url! as String, port: port! as Int)
        
//
//        _ = try! JSONSerialization.data(withJSONObject: getToken(username: self.username, password: self.password, secret: self.devSecret), options: [])
//        let token = authJSON["token"]
//        let url = URL(string: "")
//        self.manager = SocketManager(socketURL: url!, config: [.log(false)])
//        self.socket = self.manager.defaultSocket
//        let url: String = ""
//        let port: Int = 0
//        let _ = initNetworkCommunication(url: url, port: port)
        
    }
}


extension RemoteTunnel {
    
    private func getToken(username: String, password: String, secret: String, completion: @escaping ([String:Any]) -> Void) {
        let json: [String: Any] = ["username": username, "password": password]
        let url = URL(string: "https://api.remot3.it/apv/v27/user/login")
        
//        let lock = NSLock()
//        let semaphore = DispatchSemaphore(value: 0)
//        var jsonDict: NSDictionary = NSDictionary()

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(secret, forHTTPHeaderField: "developerkey")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
//            let sample = (try? JSONSerialization.jsonObject(with: data, options: []))
//            let sampledict = (sample as? NSDictionary)!
//            print(sampledict)
            let responseJSON = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any]
            let jsonDict = (responseJSON as NSDictionary?)!
//                if let responseJSON = responseJSON {
//
////                    let token = jsonDict["token"]
////                    print("Token",token!)
//                    print(responseJSON)
//                }
//            DispatchQueue.main.async {
                completion(jsonDict as! [String : Any])
//            }
            
            
//            semaphore.signal()
//                lock.unlock()
//                completion(responseJSON)
//            }
//            catch _ as NSError {
//                completion(nil)
//            }
            
//            if let responseJSON = responseJSON  {
////                print(responseJSON)
//
//            }
//            let token = responseJSON?["token"] as? [String: Any]
        }
        
//        semaphore.wait(timeout: .distantFuture)

        task.resume()
        
//        return "EMPTY BODY RESPONSE"
//        return jsonDict as! [String : String]
    }
    
    private func getProxy(token: String, id: String, secret: String, completion: @escaping ([String:Any]) -> Void) {
//        let token = "here is the token"
        let ip = "0.0.0.0"
        
        let json: [String: Any] = ["deviceaddress": id, "wait": "true", "hostip": ip]
        let url = URL(string: "https://api.remot3.it/apv/v27/device/connect")

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(secret, forHTTPHeaderField: "developerkey")
        request.setValue(token, forHTTPHeaderField: "token")
        
//        print(token)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
//            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
//            if let responseJSON = responseJSON as? [String: Any] {
//                print(responseJSON)
//            }
            
            let responseJSON = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any]
            let jsonDict = (responseJSON as NSDictionary?)!
//                if let responseJSON = responseJSON {
//
////                    let token = jsonDict["token"]
////                    print("Token",token!)
//                    print(responseJSON)
//                }
//            DispatchQueue.main.async {
                completion(jsonDict as! [String : Any])
//            }
        }
        

        task.resume()
//        return "EMPTY BODY RESPONSE"
    }
    
    private mutating func initNetworkCommunication(url: String, port: Int) {
        Stream.getStreamsToHost(withName: url, port: port, inputStream: &self.inputstream, outputStream: &self.outputstream)

        //here we are going to calling a delegate function
        self.inputstream?.delegate = self as? StreamDelegate
        self.outputstream?.delegate = self as? StreamDelegate

        self.inputstream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        self.outputstream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)

        self.inputstream?.open()
        print("Here the input stream will open")

        self.outputstream?.open()
        print("connected")
        
        let sampleData: String = "Test Data"
        let response = self.sendArr(data: sampleData)
        print("Response", response)
    }
    
    
    func sendArr(data: String) -> String {

//        socket?.emit("data", data)
        var response: NSString = ""
        var buffer = [UInt8](data.utf8)
        print("This is buf = \(buffer))")
        
        if let string = String(bytes: buffer, encoding: .utf8) {
            print("String",string)
        } else {
            print("not a valid UTF-8 sequence")
        }


        self.outputstream?.write(buffer, maxLength: buffer.count)
        
//        var buffer = [UInt8](repeating: 0, count: 4096)

        while (self.inputstream!.hasBytesAvailable)
        {
            let len = self.inputstream!.read(&buffer, maxLength: buffer.count)

            // If read bytes are less than 0 -> error
            if len < 0
            {
                let error = self.inputstream!.streamError
                print("Input stream has less than 0 bytes\(error!)")
            }
            // If read bytes equal 0 -> close connection
            else if len == 0
            {
                print("Input stream has 0 bytes")
            }

            if(len > 0)
            //here it will check it out for the data sending from the server if it is greater than 0 means if there is a data means it will write
            {
                response = NSString(bytes: buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)!

                if response == nil
                {
                    print("Network hasbeen closed")
                }
                else
                {
                    print("MessageFromServer = \(String(describing: response))")
                }
            }
        }
        
        
        return response as String
    }

}
