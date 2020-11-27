//
//  AppDelegate.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        
        let vc = ViewController()
        let nav = UINavigationController(rootViewController: vc)
        
        self.window?.rootViewController = nav
        return true
    }


}

