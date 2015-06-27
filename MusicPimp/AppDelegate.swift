//
//  AppDelegate.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 13/11/14.
//  Copyright (c) 2014 Skogberg Labs. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let audioSession = AVAudioSession.sharedInstance()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Log.info("Launched")
        initAudio()
        PlayerManager.sharedInstance.active.open()
        test()
        return true
    }
    private func test() {
        let i = Duration(hours: 5)
    }
    
    func initAudio() {
        var categoryError: NSError?
        let categorySuccess = audioSession.setCategory(AVAudioSessionCategoryPlayback, error: &categoryError)
        if(!categorySuccess) {
            Log.info("Failed to initialize audio category")
            return
        }
        var activationError: NSError?
        let activationSuccess = audioSession.setActive(true, error: &activationError)
        if(!activationSuccess) {
            Log.info("Failed to activate audio session")
        }
        Log.info("Audio session initialized.")
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        PlayerManager.sharedInstance.active.close()
        Log.info("Entered background")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // However, this is not called when the app is first launched.
        PlayerManager.sharedInstance.active.open()
        Log.info("Entering foreground")
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //Log.info("Became active")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

