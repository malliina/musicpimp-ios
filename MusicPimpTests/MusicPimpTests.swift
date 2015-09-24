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
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testJson() {
        let testURL = "file:///www.google.com"
        let testData: [Int: DownloadInfo] = [1: DownloadInfo(relativePath: "abba/mammamia.music", destinationURL: NSURL(string: testURL)!)]
        let jsValue = PimpJson.sharedInstance.toJson(testData)
        let isValidJson = NSJSONSerialization.isValidJSONObject(jsValue)
        XCTAssert(isValidJson, "Serializer produces valid JSON")
        let s = Json.stringifyObject(jsValue, prettyPrinted: true)
        let containsGoogle = s!.rangeOfString("google") != nil
        XCTAssert(containsGoogle, "Serialized value contains original content")
        let json = (try! Json.asJson(s!)) as! NSDictionary
        let tasks = PimpJson.sharedInstance.asTasks(json)!
        let deURL = tasks[1]?.destinationURL.absoluteString
        let isUrlCorrect = deURL == testURL
        XCTAssert(isUrlCorrect, "Deserializes back to original content")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
