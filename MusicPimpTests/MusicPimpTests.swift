import Foundation
import MusicPimp
import UIKit
import XCTest

class MusicPimpTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testSubscript() {
    let root = "/root"
    //let startIdx = root.count + 1
    let input = "/root/abba"
    XCTAssertEqual(input.dropFirst(root.count), "/abba")
  }

  func testUrls() {
    let url: URL? = URL(string: "http://www.google.com")
    XCTAssert(url != nil)
    if let url = url {
      XCTAssertEqual(url.absoluteString, "http://www.google.com")
      XCTAssertEqual(
        URL(string: "/tracks", relativeTo: url)!.absoluteString, "http://www.google.com/tracks")
      XCTAssertEqual(
        URL(string: "tracks", relativeTo: url)!.absoluteString, "http://www.google.com/tracks")
      XCTAssertEqual(url.absoluteString, "http://www.google.com")
      let queried = URL(string: "tracks?a=b", relativeTo: url)
      XCTAssert(queried != nil)
      if let queried = queried {
        XCTAssertEqual(queried.absoluteString, "http://www.google.com/tracks?a=b")
      }
      let folderUrl = URL(
        string: "folders/Apocalyptica%5CApocalyptica+-+7th+symphony+2010", relativeTo: url)!
      XCTAssertEqual(
        folderUrl.absoluteString,
        "http://www.google.com/folders/Apocalyptica%5CApocalyptica+-+7th+symphony+2010")
    }
  }

  func testExample() {
    // This is an example of a functional test case.
    XCTAssert(true, "Pass")
  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }

}
