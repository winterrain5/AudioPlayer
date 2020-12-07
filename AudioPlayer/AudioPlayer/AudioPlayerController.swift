//
//  AudioPlayerController.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit
import AVFoundation
import MediaPlayer

class AudioPlayerController: UIViewController {
    
    
    var isAutoPlay:Bool = false     // 是否自动播放，用于切换歌曲
    var isDraging:Bool = false     // 是否正在拖拽进度条
    var isSeeking:Bool = false      // 是否在快进快退，锁屏时操作
    var isChanged:Bool = false       // 是否正在切换歌曲，点击上一曲下一曲按钮
    var isPaused:Bool = false        // 是否点击暂停
    var isPlaying:Bool = false       // 是否正在播放

    var isInterrupt:Bool = false     // 是否被打断

    var duration:Float = 0       // 总时间
    var currentTime:Float = 0    // 当前时间
    var positionTime:Float = 0   // 锁屏时的滑杆时间

    var seekTimer:Timer?     // 快进、快退定时器

    var ifNowPlay:Bool = false      // 是否立即播放
    var toSeekProgress:Float = 0 // seek进度
    
    static let shared = AudioPlayerController()
    
    var controlView:AudioPlayerControlView = AudioPlayerControlView.loadViewFromNib()
    
    let player = AudioPlayer.shared
    var audioList:[String] = []
    var currentAudio:String = ""
    var currentIndex:Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        self.view.addSubview(controlView)
        controlView.delegate = self
        controlView.frame = CGRect(x: 0, y: self.view.height - 160, width: self.view.width, height: 160)
        
        player.delegate = self
        addNotifications()
        configLockScreenControlInfo()
        configLockScreenMediaInfo()
        
        
    }
    
    // Public
    func playMusic(with url:String) {
        let index = audioList.firstIndex(of: url) ?? 0
        if index == currentIndex {
            return
        }
        stop()
        currentIndex = index
        playMusic(with: index)
        let duration = audioDuration(urlStr: audioList[index])
        self.controlView.totalTime = formatTime(msTime: duration)
        if toSeekProgress > 0 {
            self.controlView.currentTime = formatTime(msTime: duration * toSeekProgress)
            self.controlView.progress = toSeekProgress
        }
        self.controlView.setupPlayBtn()
    }
    
    // Private
    /// 设置锁屏播放控制  在viewDidLoad中设置
    private func configLockScreenControlInfo() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 锁屏播放
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if !self.isPlaying {
                self.play()
            }
            return .success
        }
        
        // 锁屏暂停
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if self.isPlaying {
                self.pause()
            }
            return .success
        }
        
        commandCenter.stopCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return .success
        }
        
        // 播放暂停按钮（耳机控制）
        let playpauseCommand = commandCenter.togglePlayPauseCommand
        playpauseCommand.isEnabled = true
        playpauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            if self.isPlaying {
                self.pause()
            }else {
                self.play()
            }
            
            return .success
        }
        
        // 上一曲
        let prevCommand = commandCenter.previousTrackCommand
        prevCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
           
            self.playPreMusic()
            
            return .success
        }
        
        // 下一曲
        let nextCommand = commandCenter.nextTrackCommand
        nextCommand.isEnabled = true
        nextCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.isAutoPlay = false
            
            if self.isPlaying {
                self.stop()
            }
            
            self.isChanged = true
            
            self.playNextMusic()
            
            return .success
        }
        
        // 快进
        let forwardCommand = commandCenter.seekForwardCommand
        forwardCommand.isEnabled = true
        forwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let seekEvent = event as! MPSeekCommandEvent
            if seekEvent.type == .beginSeeking {
                self.seekingForwardStart()
            }else {
                self.seekingForwardStop()
            }
            
            return .success
        }
        
        // 快退
        let backwardCommand = commandCenter.seekBackwardCommand
        backwardCommand.isEnabled = true
        backwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let seekEvent = event as! MPSeekCommandEvent
            if seekEvent.type == .beginSeeking {
                self.seekingBackwardStart()
            }else {
                self.seekingBackwardStop()
            }
            
            return .success
        }
        
        // 拖动进度条
        commandCenter.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            let positionEvent = event as! MPChangePlaybackPositionCommandEvent
            if Float(positionEvent.positionTime) != self.positionTime {
                self.positionTime = Float(positionEvent.positionTime)
                self.currentTime = self.positionTime * 1000
                self.player.setPlayerProgress(self.currentTime/self.duration)
            }
            
            return .success
        }
        
    }
    
    /// 设置锁屏信息 在播放进度改变时调用
    private func configLockScreenMediaInfo() {
        let playingCenter = MPNowPlayingInfoCenter.default()
        
        var playinfo:[String:Any] = [:]
        playinfo[MPMediaItemPropertyAlbumTitle] = "专辑名称"
        playinfo[MPMediaItemPropertyTitle] = "歌曲名称"
        playinfo[MPMediaItemPropertyArtist] = "歌手名称"
        
        let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 100)) { (size) -> UIImage in
            return UIImage(named: "cm2_default_cover_fm")!
        }
        playinfo[MPMediaItemPropertyArtwork] = artwork
        
        // 当前播放时间
        playinfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = (self.duration * self.controlView.progress) / 1000
        // 进度的速度
        playinfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        // 总时间
        playinfo[MPMediaItemPropertyPlaybackDuration] = self.duration / 1000
        // 当前进度
        playinfo[MPNowPlayingInfoPropertyPlaybackProgress] = self.controlView.progress
        
        playingCenter.nowPlayingInfo = playinfo
    }
    
    private func addNotifications() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // 插拔耳机
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: OperationQueue.main) { (notifi) in
            let info = notifi.userInfo
            if let changeReason = info?[AVAudioSessionRouteChangeReasonKey] {
                switch changeReason {
                case AVAudioSession.RouteChangeReason.newDeviceAvailable:
                    print("耳机插入")
                case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
                    print("耳机拔出")
                    // 耳机拔出 系统会自动暂停正在播放的音频，这里只需要改变UI为暂停状态
                    if self.isPlaying {
                        self.pause()
                    }
                default:
                    break
                }
            }
        }
        
        // 播放打断
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: OperationQueue.main) { (notifi) in
            let info = notifi.userInfo
            if let type = info?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType {
                // 收到播放中断的通知 ，暂停播放
                if type == AVAudioSession.InterruptionType.began {
                    if self.isPlaying {
                        self.isInterrupt = true
                        self.pause()
                    }
                }
                // 中断结束 判断是否需要恢复播放
                if type == AVAudioSession.InterruptionType.ended {
                    if !self.isPlaying {
                        self.play()
                    }
                }
            }
        }
    }
    
    //MARK 播放相关
    /// 播放上一曲
    private func playPreMusic() {
       
        self.currentIndex -= 1
        if self.currentIndex <= 0 {
            self.currentIndex = 0
        }
        self.ifNowPlay = true
        if self.isPlaying { return }
        self.playMusic(with: self.currentIndex)
        
    }
    
    /// 播放下一曲
    private func playNextMusic() {
        
        self.currentIndex += 1
        if self.currentIndex == self.audioList.count {
            self.currentIndex = 0
        }
        self.ifNowPlay = true
        if self.isPlaying { return }
        self.playMusic(with: self.currentIndex)
    }
    
    private func playMusic(with index:Int) {
        self.player.setAudioUrl(path: audioList[index])
        self.play()
    }
    
    /// 快进开始
    private func seekingForwardStart() {
        if !self.isPlaying { return }
        self.isSeeking = true
        self.currentTime = self.controlView.progress * self.duration
        self.seekTimer = Timer(timeInterval: 0.05, target: self, selector: #selector(seekingForwardAction), userInfo: nil, repeats: true)
    }
    
    /// 快进结束
    private func seekingForwardStop() {
        if !self.isPlaying { return }
        if (self.seekTimer != nil) { return }
        
        self.isSeeking = false
        self.seekTimeInvalidate()
        
        player.setPlayerProgress(self.currentTime / self.duration)
    }
    
    @objc private func seekingForwardAction() {
        if self.currentTime >= self.duration {
            seekTimeInvalidate()
            return
        }
        
        self.currentTime += 1000
        self.controlView.progress = self.duration == 0 ? 0 : (self.currentTime / self.duration)
        self.controlView.currentTime = formatTime(msTime: self.currentTime)
        
    }
    
    /// 快退开始
    private func seekingBackwardStart() {
        if !self.isPlaying { return }
        
        self.isSeeking = true
        self.currentTime = self.controlView.progress * self.duration
        self.seekTimer = Timer(timeInterval: 0.05, target: self, selector: #selector(seekingBackwardAction), userInfo: nil, repeats: true)
    }
    
    /// 快退结束
    private func seekingBackwardStop() {
        if !self.isPlaying { return }
        if self.seekTimer != nil { return }
        
        self.isSeeking = false
        self.seekTimeInvalidate()
        
        player.setPlayerProgress(self.currentTime / self.duration)
    }
    
    @objc private func seekingBackwardAction() {
        if self.currentTime <= 0 {
            self.seekTimeInvalidate()
            return
        }
        
        self.currentTime -= 1000
        self.controlView.progress = self.duration == 0 ? 0 : (self.currentTime / self.duration)
        self.controlView.currentTime = formatTime(msTime: self.currentTime)
    }
    
    private func seekTimeInvalidate() {
        if self.seekTimer != nil {
            self.seekTimer?.invalidate()
            self.seekTimer = nil
        }
    }

    private func pause() {
        player.pause()
        isPlaying = false
    }
    
    private func play() {
        player.play()
        isPlaying = true
        if player.audioUrl.isEmpty {
            return
        }else {
            if player.playState == .stoped {
                player.play()
            }else if player.playState == .paused {
                player.resume()
            }else {
                player.play()
            }
        }
    }
    
    private func stop() {
        player.stop()
        isPlaying = false
    }
    
    
    /// 格式化时间
    /// - Parameter msTime: 毫秒
    private func formatTime(msTime:Float) -> String{
        let second = msTime / 1000
        return String(format: "%02.f:%02.f",
                      CGFloat(second).truncatingRemainder(dividingBy: 3600)/60,
                      CGFloat(second).truncatingRemainder(dividingBy: 60))
    }
    
    
    /// 获取音频总时间
    /// - Parameter urlStr: 音频地址
    /// - Returns: 音频时长 毫秒单位
    private func audioDuration(urlStr:String) -> Float {
        guard let url = URL(string: urlStr) else { return 0 }
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        let time = CMTimeGetSeconds(duration)
        return Float(time * 1000)
    }
}
extension AudioPlayerController:AudioPlayerDelegate {
    func playerStatusChanged(player: AudioPlayer, state: AudioPlayerState) {
        switch state {
        case .loading:
            self.controlView.showLoading()
            self.controlView.setupPauseBtn()
            self.isPlaying = false
        case .buffering:
            self.controlView.hideLoading()
            self.controlView.setupPlayBtn()
            self.isPlaying = true
        case .playing:
            self.controlView.hideLoading()
            self.controlView.setupPlayBtn()
            if self.toSeekProgress > 0 {
                player.setPlayerProgress(self.toSeekProgress)
                self.toSeekProgress = 0
            }
            self.isPlaying = true
        case .paused:
            self.controlView.hideLoading()
            self.controlView.setupPauseBtn()
            self.isPlaying = false
        case .stopedByUser:
            self.controlView.hideLoading()
            self.controlView.setupPauseBtn()
            self.isPlaying = false
        case .stoped:
            self.controlView.hideLoading()
            self.controlView.setupPauseBtn()
            self.isPlaying = false
            self.pause()
        case .ended:
            self.controlView.hideLoading()
            self.controlView.setupPauseBtn()
            if self.isPlaying {
                self.controlView.currentTime = self.controlView.totalTime
                self.isPlaying = false
                self.isAutoPlay = true
                self.playNextMusic()
            }else {
                self.controlView.hideLoading()
                self.controlView.setupPauseBtn()
            }
        case .error:
            self.controlView.hideLoading()
            self.controlView.setupPauseBtn()
            self.isPlaying = false
        }
    }
    
    func playerTimeChanged(player: AudioPlayer, currentTime: TimeInterval, totalTime: TimeInterval, progress: Float) {
        
        if isDraging { return }
        if isSeeking { return }
        
        var tempProgress = progress
        if toSeekProgress > 0 {
            tempProgress = toSeekProgress
        }
        
        self.controlView.currentTime = formatTime(msTime: Float(currentTime))
        self.controlView.progress = tempProgress
        
        configLockScreenMediaInfo()
    }
    
    func playerTotalTime(player: AudioPlayer, totalTime: TimeInterval) {
        self.controlView.totalTime = formatTime(msTime: Float(totalTime))
        self.duration = Float(totalTime)
    }
    
    func playerBufferProgress(player: AudioPlayer, bufferProgress: Float) {
        self.controlView.bufferProgress = bufferProgress
    }
    
    
}
extension AudioPlayerController:AudioPlayerControlViewDelegate {
    func controlView(controlView: AudioPlayerControlView, didClickLoop: UIButton) {
        
    }
    
    func controlView(controlView: AudioPlayerControlView, didClickPrev: UIButton) {
        self.isChanged = true
        
        if self.isPlaying {
            stop()
        }
        
        self.playPreMusic()
    }
    
    func controlView(controlView: AudioPlayerControlView, didClickPlay: UIButton) {
        if self.isPlaying {
            pause()
        }else {
            play()
        }
    }
    
    func controlView(controlView: AudioPlayerControlView, didClickNext: UIButton) {
        
        self.isAutoPlay = false
        
        if self.isPlaying {
            stop()
        }
        
        self.isChanged = true
        self.playNextMusic()
    }
    
    func controlView(controlView: AudioPlayerControlView, didClickList: UIButton) {
        
    }
    
    func controlView(controlView: AudioPlayerControlView, didSliderTouchBegan value: Float) {
        print("didSliderTouchBegan\(value)")
        self.isDraging = true
    }
    
    func controlView(controlView: AudioPlayerControlView, didSliderTouchEnded value: Float) {
        print("didSliderTouchEnded\(value)")
        self.isDraging = false
        if self.isPlaying {
            player.setPlayerProgress(value)
        }else {
            self.toSeekProgress = value
        }
    }
    
    func controlView(controlView: AudioPlayerControlView, didSliderValueChange value: Float) {
        print("didSliderValueChange\(value)")
        self.isDraging = true
        self.controlView.currentTime = formatTime(msTime: self.duration * value)
    }
    
    func controlView(controlView: AudioPlayerControlView, didSliderTapped value: Float) {
        print("didSliderTapped\(value)")
        if self.isPlaying {
            player.setPlayerProgress(value)
        }else {
            self.toSeekProgress = value
        }
    }
}


