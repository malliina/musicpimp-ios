import UIKit
import AudioToolbox
import AVFoundation
import MediaPlayer
import StoreKit
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import RxSwift
import SwiftUI

struct AppRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PimpTabBarController {
        PimpTabBarController()
    }
    
    func updateUIViewController(_ uiViewController: PimpTabBarController, context: Context) {
        
    }
    
    typealias UIViewControllerType = PimpTabBarController
}

@main
struct MusicPimpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let log = LoggerFactory.shared.pimp(MusicPimpApp.self)
    let audioSession = AVAudioSession.sharedInstance()
    let bag = DisposeBag()
    
    init() {
        log.info("PimpApp launching")
        AppCenter.start(withAppSecret: "bfa6d43e-d1f3-42e2-823a-920a16965470", services: [
            Analytics.self,
            Crashes.self
        ])
        initAudio()
        BackgroundDownloader.musicDownloader.setup()
        let _ = PlaylistPrefetcher.shared
        connectToPlayer()
        SKPaymentQueue.default().add(TransactionObserver.sharedInstance)
        delegate.initTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            PimpTabView()
                .ignoresSafeArea(.all)
//            AppRepresentable()
//
//            .navigationViewStyle(.stack)
        }
    }
    
    private func initAudio() {
        let categorySuccess: Bool = (try? audioSession.setCategory(.playback, mode: .default)) != nil
        if categorySuccess {
            ExternalCommandDelegate.sharedInstance.initialize(MPRemoteCommandCenter.shared())
        } else {
            log.info("Failed to initialize audio category")
            return
        }
        let activationSuccess = (try? audioSession.setActive(true)) != nil
        if !activationSuccess {
            log.error("Failed to activate audio session")
        } else {
            log.info("Audio session initialized")
        }
    }
    private func connectToPlayer() {
        PlayerManager.sharedInstance.active.open().subscribe { (event) in
            switch event {
            case .next(_): ()
            case .error(let err): self.onConnectionFailure(err)
            case .completed: self.onConnectionOpened()
            }
        }.disposed(by: bag)
    }
    private func onConnectionOpened() {
        log.info("Connected")
    }
    private func onConnectionFailure(_ error: Error) {
        log.error("Unable to connect")
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    let log = LoggerFactory.shared.pimp(AppDelegate.self)
    let settings = PimpSettings.sharedInstance
    let notifications = PimpNotifications.sharedInstance
    let colors = PimpColors.shared
    
//    var window: UIWindow?
    
    var downloadCompletionHandlers: [String: () -> Void] = [:]
    // Hack
    private var notification: [AnyHashable: Any]? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.info("App launching")
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.makeKeyAndVisible()
//        window?.rootViewController = PimpTabBarController()
//        window?.rootViewController = DemoView()
        
        // Override point for customization after application launch.
//        initAudio()
//        BackgroundDownloader.musicDownloader.setup()
//        let _ = PlaylistPrefetcher.shared
//        connectToPlayer()

//        if let launchOptions = launchOptions, let payload = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
//            log.info("Launched app via remote notification, handling...")
//            notifications.handleNotification(application, window: window, data: payload)
//        }
//        SKPaymentQueue.default().add(TransactionObserver.sharedInstance)

//        initTheme(application)
//        test()
        log.info("App init complete")
        return true
    }
    
    fileprivate func test() {
        let rootDir = LocalLibrary.sharedInstance.musicRootURL
        let contents = Files.sharedInstance.listContents(rootDir)
        for dir in contents.folders {
            log.info("\(dir.name), last modified: \(dir.lastModified?.description ?? "never"), accessed: \(dir.lastAccessed?.description ?? "never")")
        }
        for file in contents.files {
            log.info("\(file.name), size: \(file.size), last modified: \(file.lastModified?.description ?? "never")")
        }
        let dirs = contents.folders.count
        let files = contents.files.count
        let size = Files.sharedInstance.folderSize(rootDir)
        log.info("Dirs: \(dirs) files: \(files) size: \(size)")
    }
    
    func initTheme() {
//        app.delegate?.window??.tintColor = colors.tintColor
        UINavigationBar.appearance().barStyle = colors.barStyle
        // UINavigationBar.appearance().tintColor = colors.tintColor
        UITabBar.appearance().barStyle = colors.barStyle
        UIView.appearance().tintColor = colors.tintColor
        UITableView.appearance().backgroundColor = colors.background
        UITableView.appearance().separatorColor = colors.separator
        UITableView.appearance().tintColor = colors.deletion
        UITableViewCell.appearance().backgroundColor = colors.background
        UITableViewCell.appearance().tintColor = colors.deletion
        let backgroundView = PimpView()
        backgroundView.backgroundColor = colors.selectedBackground
        UITableViewCell.appearance().selectedBackgroundView = backgroundView
        //UISegmentedControl.appearance().backgroundColor = PimpColors.background
        // titles for cell texts
        UILabel.appearance().textColor = colors.titles
//        UISearchBar.appearance().barStyle = colors.searchBarStyle
        UITextView.appearance().backgroundColor = colors.background
        UITextView.appearance().textColor = colors.titles
        PimpView.appearance().backgroundColor = colors.background
//        UIBarButtonItem.appearance()
//            .setTitleTextAttributes([NSFontAttributeName : PimpColors.titleFont], forState: UIControlState.Normal)
        if #available(iOS 13.0, *) {
            UISegmentedControl.appearance().selectedSegmentTintColor = PimpColors.shared.background
        } else {
            // Fallback on earlier versions
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notifications.didRegister(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        notifications.didFailToRegister(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        log.info("Received remote notification...")
        notification = userInfo
//        notifications.handleNotification(application, window: window, data: userInfo)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        log.info("Complete: \(identifier)")
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
        log.info("Entered background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // However, this is not called when the app is first launched.
        
        // TODO call this using swiftui
//        connectToPlayer()
        log.info("Entering foreground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        log.info("Became active, TODO swiftui")
//        if let notification = notification {
//            notifications.handleNotification(application, window: window, data: notification)
//            self.notification = nil
//        }
//        if let viewController = window?.rootViewController {
//            Players.sharedInstance.suggestPlayerChangeIfNecessary(view: viewController)
//        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        settings.trackHistory = Limiter.sharedInstance.history
        log.info("Terminating")
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
