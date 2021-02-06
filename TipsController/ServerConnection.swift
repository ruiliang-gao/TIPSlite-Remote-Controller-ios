//
//  ServerConnection.swift
//  TipsController
//
//  Created by Prasan Dhareshwar on 2/5/21.
//

import Foundation

class ServerConnection: NSObject, StreamDelegate {
    let url: String
    let port: Int
    var inputStream: InputStream!
    var outputStream: OutputStream!
    var reponse = ""
    
    init(_ url:String, port:Int) {
        self.url = url
        self.port = port
    }
    
    func initNetworkCommunication() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, self.url as CFString, UInt32(self.port), &readStream, &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        inputStream.delegate = self
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        inputStream.open()
        outputStream.open()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            switch eventCode {
            case Stream.Event.hasBytesAvailable:
                printAvailableBytes(stream: aStream as! InputStream)
            case Stream.Event.endEncountered:
                print("<End Encountered>")
                close()
            case Stream.Event.errorOccurred:
                print("<Error occurred>")
            default:
                print("<Some other event>")
            }
        }
    
    func close() {
           inputStream.close()
           outputStream.close()
       }
    
    func printAvailableBytes(stream: InputStream) {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
            while stream.hasBytesAvailable {
                let numberOfBytesRead = inputStream.read(buffer, maxLength: 4096)
                if numberOfBytesRead < 0 {
                    if stream.streamError != nil {
                        break
                    }
                }

                if let message = String(bytesNoCopy: buffer, length: numberOfBytesRead, encoding: .utf8, freeWhenDone: true) {
                    reponse = message
                }
            }
        }
    
    func sendArr(data: String) -> String  {
        let buffer = [UInt8](data.utf8)
        
//        if let string = String(bytes: buffer, encoding: .utf8) {
//            print("String",string)
//        } else {
//            print("not a valid UTF-8 sequence")
//        }

        outputStream.write(buffer, maxLength: buffer.count)
        
        return reponse
    }
    
}
