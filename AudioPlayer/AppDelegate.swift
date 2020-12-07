//
//  AppDelegate.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit
import SnapKit
import Then

/// 导航栏高度
let kNavBarHeight: CGFloat = iPhoneX() ? 88 : 64
/// tab栏高度
let kTabBarHeight: CGFloat = iPhoneX() ? 83 : 49
/// 底部安全区域
let kBottomsafeAreaMargin: CGFloat = iPhoneX() ? 34 : 0
/// 顶部安全区域
let kTopsafeAreaMargin: CGFloat = iPhoneX() ? 44 : 0
/// 状态栏高度
let kStatusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
/// 屏幕高度
let kScreenHeight:CGFloat = UIScreen.main.bounds.size.height
/// 屏幕宽度
let kScreenWidth:CGFloat = UIScreen.main.bounds.size.width
/// 判断是否是iPhone
func iPhoneX() -> Bool {
    if #available(iOS 11, *) {
        guard let w = UIApplication.shared.delegate?.window, let unwrapedWindow = w else {
            return false
        }
        if  unwrapedWindow.safeAreaInsets.bottom > 0 {
            return true
        }
    }
    return false
}


@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?
    var allowOrentitaionRotation:Bool = false
    //当前界面支持的方向（默认情况下只能竖屏，不能横屏显示）
    var interfaceOrientations:UIInterfaceOrientationMask = .portrait{
        didSet{
            //强制设置成竖屏
            if interfaceOrientations == .portrait{
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue,
                                          forKey: "orientation")
            }
            //强制设置成横屏
            else if !interfaceOrientations.contains(.portrait){
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue,
                                          forKey: "orientation")
            }
        }
    }
    
    //返回当前界面支持的旋转方向
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor
                        window: UIWindow?)-> UIInterfaceOrientationMask {
        if allowOrentitaionRotation {
            return .allButUpsideDown
        }else {
            return .portrait
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        
        let vc = ViewController()
        let nav = UINavigationController(rootViewController: vc)
        
        self.window?.rootViewController = nav
        return true
    }


}



extension UIApplication {
    class func changeOrientationTo(landscapeRight: Bool) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        if landscapeRight == true {
            delegate.allowOrentitaionRotation = true
        } else {
            delegate.allowOrentitaionRotation = false
        }
    }
    var window:UIWindow? {
        return (self.delegate as? AppDelegate)?.window
    }
}

extension UIImageView {
    func blur(withStyle style: UIBlurEffect.Style = .light) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        addSubview(blurEffectView)
        clipsToBounds = true
    }
}
