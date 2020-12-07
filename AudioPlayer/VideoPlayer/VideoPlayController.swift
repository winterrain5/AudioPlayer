//
//  VideoPlayController.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/12/7.
//

import UIKit
import ZFPlayer
class VideoPlayController: UIViewController {

    var player:ZFPlayerController?
    var containerView:UIView = UIView()
    var controlView:VideoPlayControlView = VideoPlayControlView()
    
    var videoUrl:String?
    
    var coverUrl:String = "https://image.baidu.com/search/detail?ct=503316480&z=undefined&tn=baiduimagedetail&ipn=d&word=%E5%9B%BE%E7%89%87&step_word=&ie=utf-8&in=&cl=2&lm=-1&st=undefined&hd=undefined&latest=undefined&copyright=undefined&cs=1603365312,3218205429&os=1116313301,536553700&simid=4189071781,572287113&pn=17&rn=1&di=112750&ln=1517&fr=&fmq=1607307321632_R&fm=&ic=undefined&s=undefined&se=&sme=&tab=0&width=undefined&height=undefined&face=undefined&is=0,0&istype=0&ist=&jit=&bdtype=0&spn=0&pi=0&gsm=0&hs=2&objurl=http%3A%2F%2Fa0.att.hudong.com%2F52%2F62%2F31300542679117141195629117826.jpg&rpstart=0&rpnum=0&adpicid=0&force=undefined"
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        
        let navBarFrame = self.navigationController?.navigationBar.frame ?? .zero
        containerView.frame = CGRect(x: 0, y: navBarFrame.maxY, width: self.view.width, height: self.view.width * 9 / 16)
        self.view.addSubview(containerView)

        let manager = ZFAVPlayerManager()
        player = ZFPlayerController(playerManager: manager, containerView: containerView)
        player?.controlView = controlView
        player?.shouldAutoPlay = false
        
        self.player?.orientationWillChange = { player,isFull in
            UIApplication.changeOrientationTo(landscapeRight: isFull)
        }
        
        if let urlStr = videoUrl,let url = URL(string: urlStr) {
            manager.assetURL = url
        }
        
        controlView.show(title: "播放视频", placeHolder: UIImage(named: "video_place_holder")!, coverUrlStr: coverUrl, fullScreenModel: .landscape)
        
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}
