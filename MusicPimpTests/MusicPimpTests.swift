//
//  MusicPimpTests.swift
//  MusicPimpTests
//
//  Created by Michael Skogberg on 13/11/14.
//  Copyright (c) 2014 Skogberg Labs. All rights reserved.
//

import UIKit
import XCTest
import Foundation
import MusicPimp

class MusicPimpTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testStringPathTest() {
//        let s = "".lastPathComponent().stringByDeletingPathExtension.stringByDeletingLastPathComponent.lastPathComponent
//        XCTAssert(s == "", "String methods should return the empty string if operating on one")
//    }
    
    func testSubscript() {
        let root = "/root"
        //let startIdx = root.count + 1
        let input = "/root/abba"
//        let out = input.dropFirst(root.count)
//        let out = input[startIdx<..]
//        let outStr = String(out)
        XCTAssertEqual(input.dropFirst(root.count), "/abba")
    }
    
    func testUrls() {
        let url: URL? = URL(string: "http://www.google.com")
        XCTAssert(url != nil)
        if let url = url {
            XCTAssertEqual(url.absoluteString, "http://www.google.com")
            XCTAssertEqual(URL(string: "/tracks", relativeTo: url)!.absoluteString, "http://www.google.com/tracks")
            XCTAssertEqual(URL(string: "tracks", relativeTo: url)!.absoluteString, "http://www.google.com/tracks")
            XCTAssertEqual(url.absoluteString, "http://www.google.com")
            let queried = URL(string: "tracks?a=b", relativeTo: url)
            XCTAssert(queried != nil)
            if let queried = queried {
                XCTAssertEqual(queried.absoluteString, "http://www.google.com/tracks?a=b")
            }
            let folderUrl = URL(string: "folders/Apocalyptica%5CApocalyptica+-+7th+symphony+2010", relativeTo: url)!
            XCTAssertEqual(folderUrl.absoluteString, "http://www.google.com/folders/Apocalyptica%5CApocalyptica+-+7th+symphony+2010")
        }
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testJson() {
        let testURL = "file:///www.google.com"
        let testData: [Int: DownloadInfo] = [1: DownloadInfo(relativePath: "abba/mammamia.music", destinationURL: URL(string: testURL)!)]
        let jsValue = PimpJson.sharedInstance.toJson(testData)
        let isValidJson = JSONSerialization.isValidJSONObject(jsValue)
        XCTAssert(isValidJson, "Serializer produces valid JSON")
        let s = Json.stringifyObject(jsValue, prettyPrinted: true)
        let containsGoogle = s!.range(of: "google") != nil
        XCTAssert(containsGoogle, "Serialized value contains original content")
        let json = Json.asJson(s!) as! NSDictionary
        let tasks = PimpJson.sharedInstance.asTasks(json as! [String : AnyObject])!
        let deURL = tasks[1]?.destinationURL.absoluteString
        let isUrlCorrect = deURL == testURL
        XCTAssert(isUrlCorrect, "Deserializes back to original content")
    }
    
    func testPlaylistSerialization() {
        let track = Track(id: "id", title: "a", album: "b", artist: "c", duration: 5.seconds, path: "path", size: 5.bytes!, url: URL(fileURLWithPath: "hey"))
        let pl = SavedPlaylist(id: nil, name: "test pl", trackCount: 1, duration: 5.seconds, tracks: [track])
        let json = SavedPlaylist.toJson(pl)
        if let data = try? JSONSerialization.data(withJSONObject: json, options: []),
            let s = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? {
            print(pl.description)
            print(s)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
    
    func testLimitSerialization() {
        let settings = PimpSettings.sharedInstance
        let json = settings.serializeHistory([])!
        let history = settings.readHistory(json)
        XCTAssert(history.count == 0)
        let firstDate = Date() // hehe
        let firstSeconds = round(firstDate.timeIntervalSince1970)
        let dates = [ Date(), Date() ]
        let json2 = settings.serializeHistory(dates)!
        let history2 = settings.readHistory(json2)
        XCTAssert(history2.count == dates.count)
        let firstInt = round(history2.first!.timeIntervalSince1970)
        XCTAssert(firstInt == firstSeconds)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
