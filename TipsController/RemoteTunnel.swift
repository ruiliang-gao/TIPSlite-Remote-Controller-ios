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
    
    var inputstream: InputStream?
    var outputstream: OutputStream?
    var host: String?
    var port: Int?
    
    
    init() {
        _ = getToken(username: self.username, password: self.password, secret: self.devSecret)
//        _ = try! JSONSerialization.data(withJSONObject: getToken(username: self.username, password: self.password, secret: self.devSecret), options: [])
//        let token = authJSON["token"]
//        let url = URL(string: "")
//        self.manager = SocketManager(socketURL: url!, config: [.log(false)])
//        self.socket = self.manager.defaultSocket
        let url: String = ""
        let port: Int = 0
        let _ = initNetworkCommunication(url: url, port: port)
        
    }
}

//
//let username:String = "sofa.tips.jr@gmail.com"
//let password:String = "wZB#:{8zvY}-@2%E"
//let devSecret: String = "RjVDNjkzMTgtMjEyOS00ODlGLTk0QzMtOTcxRDAzQ0FCMDcw"

extension RemoteTunnel {
    
    private func getToken(username: String, password : String, secret : String) -> String {
        let json: [String: Any] = ["username": username, "password": password]
//        let token = "here is the token"
        let url = URL(string: "https://api.remot3.it/apv/v27/user/login")

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue( secret, forHTTPHeaderField: "developerkey")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }

        task.resume()
        
        return "EMPTY BODY RESPONSE"
    }
    
    private func getProxy(token : String, id: String, secret : String) -> String {
//        let token = "here is the token"
        let ip = "0.0.0.0"
        
        let json: [String: Any] = ["deviceaddress": id, "wait": "true", "hostip": ip]
        let url = URL(string: "https://api.remot3.it/apv/v27/user/connect")

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue( secret, forHTTPHeaderField: "developerkey")
        request.setValue( token, forHTTPHeaderField: "token")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        

        task.resume()
        return "EMPTY BODY RESPONSE"
    }
    
    private mutating func initNetworkCommunication(url: String, port: Int) {
        Stream.getStreamsToHost(withName: host!, port: port, inputStream: &inputstream, outputStream: &outputstream)

        //here we are going to calling a delegate function
        inputstream?.delegate = self as? StreamDelegate
        outputstream?.delegate = self as? StreamDelegate

        inputstream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        outputstream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)

        inputstream?.open()
        print("Here the input stream will open")

        outputstream?.open()
        print("connected")
    }
    
    func sendArr(data: String) -> String {

//        socket?.emit("data", data)
        var response: NSString = ""
        let buf = [UInt8](data.utf8)
        print("This is buf = \(buf))")


        outputstream?.write(buf, maxLength: buf.count)
        
        var buffer = [UInt8](repeating: 0, count: 4096)

        while (self.inputstream!.hasBytesAvailable)
        {
            let len = inputstream!.read(&buffer, maxLength: buffer.count)

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
                response = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)!

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
