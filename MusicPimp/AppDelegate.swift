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
import MediaPlayer
import StoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let settings = PimpSettings.sharedInstance
    let notifications = PimpNotifications.sharedInstance
    
//    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    var window: UIWindow?
    
    let audioSession = AVAudioSession.sharedInstance()
    
    var downloadCompletionHandlers: [String: () -> Void] = [:]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window?.makeKeyAndVisible()
        window?.rootViewController = PimpTabBarController() // UINavigationController(rootViewController: SnapLibrary())
//        window?.rootViewController = UINavigationController(rootViewController: SettingsController())
        
        // Override point for customization after application launch.
        initAudio()
        BackgroundDownloader.musicDownloader.setup()
        connectToPlayer()
//        notifications.initNotifications(application)
        if let launchOptions = launchOptions {
            notifications.handleNotification(application, data: launchOptions)
        }
        SKPaymentQueue.default().add(TransactionObserver.sharedInstance)
//        Log.info("didFinishLaunchingWithOptions")
        initTheme(application)
//        test()
        return true
    }
    
    fileprivate func test() {
        let rootDir = LocalLibrary.sharedInstance.musicRootURL
        let contents = Files.sharedInstance.listContents(rootDir)
        for dir in contents.folders {
            Log.info("\(dir.name), last modified: \(dir.lastModified?.description ?? "never"), accessed: \(dir.lastAccessed?.description ?? "never")")
        }
        for file in contents.files {
            Log.info("\(file.name), size: \(file.size), last modified: \(file.lastModified?.description ?? "never")")
        }
        let dirs = contents.folders.count
        let files = contents.files.count
        let size = Files.sharedInstance.folderSize(rootDir)
        Log.info("Dirs: \(dirs) files: \(files) size: \(size)")
    }
    
    func initTheme(_ app: UIApplication) {
        app.delegate?.window??.tintColor = PimpColors.tintColor
        UINavigationBar.appearance().barStyle = PimpColors.barStyle
        UINavigationBar.appearance().tintColor = PimpColors.tintColor
        UITabBar.appearance().barStyle = PimpColors.barStyle
        UIView.appearance().tintColor = PimpColors.tintColor
        UITableView.appearance().backgroundColor = PimpColors.background
        UITableView.appearance().separatorColor = PimpColors.separator
        UITableViewCell.appearance().backgroundColor = PimpColors.background
        let backgroundView = PimpView()
        backgroundView.backgroundColor = PimpColors.selectedBackground
        UITableViewCell.appearance().selectedBackgroundView = backgroundView
        //UISegmentedControl.appearance().backgroundColor = PimpColors.background
        // titles for cell texts
        UILabel.appearance().textColor = PimpColors.titles
//        UISearchBar.appearance().barStyle = PimpColors.searchBarStyle
        UITextView.appearance().backgroundColor = PimpColors.background
        UITextView.appearance().textColor = PimpColors.titles
        PimpView.appearance().backgroundColor = PimpColors.background
//        UIBarButtonItem.appearance()
//            .setTitleTextAttributes([NSFontAttributeName : PimpColors.titleFont], forState: UIControlState.Normal)
    }
    
    func initAudio() {
        let categorySuccess: Bool
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            categorySuccess = true
        } catch _ {
            categorySuccess = false
        }
        if categorySuccess {
            ExternalCommandDelegate.sharedInstance.initialize(MPRemoteCommandCenter.shared())
        } else {
            Log.info("Failed to initialize audio category")
            return
        }
        let activationSuccess: Bool
        do {
            try audioSession.setActive(true)
            activationSuccess = true
        } catch _ {
            activationSuccess = false
        }
        if !activationSuccess {
            Log.info("Failed to activate audio session")
        }
        Log.info("Audio session initialized")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notifications.didRegister(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        notifications.didFailToRegister(error)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        let allowed = notificationSettings.types != .none
        if !allowed {
            notifications.didNotGetPermission()
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        notifications.handleNotification(application, data: userInfo)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Log.info("Complete: \(identifier)")
        downloadCompletionHandlers[identifier] = completionHandler
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        PlayerManager.sharedInstance.active.close()
        settings.trackHistory = Limiter.sharedInstance.history
        Log.info("Entered background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // However, this is not called when the app is first launched.
        connectToPlayer()
        Log.info("Entering foreground")
    }
    
    func connectToPlayer() {
        PlayerManager.sharedInstance.active.open(onConnectionOpened, onError: onConnectionFailure)
    }
    
    func onConnectionOpened() {
        Log.info("Connected")
    }
    func onConnectionFailure(_ error: Error) {
        Log.error("Unable to connect")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //Log.info("Became active")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        settings.trackHistory = Limiter.sharedInstance.history
        Log.info("Terminating")
    }
    
    //    override func remoteControlReceivedWithEvent(event: UIEvent) {
    //        switch event.subtype {
    //        case UIEventSubtype.RemoteControlPlay:
    //            break;
    //        case UIEventSubtype.RemoteControlPause:
    //            break;
    //        case UIEventSubtype.RemoteControlStop:
    //            break;
    //        case UIEventSubtype.RemoteControlNextTrack:
    //            break;
    //        case UIEventSubtype.RemoteControlPreviousTrack:
    //            break;
    //        case UIEventSubtype.RemoteControlTogglePlayPause:
    //            break;
    //        case UIEventSubtype.RemoteControlBeginSeekingForward:
    //            break;
    //        case UIEventSubtype.RemoteControlEndSeekingForward:
    //            break;
    //        case UIEventSubtype.RemoteControlBeginSeekingBackward:
    //            break;
    //        case UIEventSubtype.RemoteControlEndSeekingBackward:
    //            break;
    //        default:
    //            Log.error("Unknown remote control event: \(event.subtype)")
    //        }
    //    }
}
