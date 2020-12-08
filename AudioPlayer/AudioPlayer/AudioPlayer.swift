//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit
import FreeStreamer

protocol AudioPlayerDelegate:NSObjectProtocol {
    func playerStatusChanged(player:AudioPlayer, state:AudioPlayerState)
    func playerTimeChanged(player:AudioPlayer, currentTime:TimeInterval, totalTime:TimeInterval, progress:Float)
    func playerTotalTime(player:AudioPlayer, totalTime:TimeInterval)
    func playerBufferProgress(player:AudioPlayer, bufferProgress:Float)
}

class AudioPlayer: NSObject {

    weak var delegate:AudioPlayerDelegate?
    
   
    /// 播放器状态
    var playState:AudioPlayerState = .stoped
    /// 缓冲状态
    var bufferState:AudioBufferState = .none
    
    private var playTimer:Timer?
    private var bufferTimer:Timer?
    private var audioStream:FSAudioStream?
    /// 本地或者网络音频地址
    var audioUrl:String = ""
    
    static let shared = AudioPlayer()
    
    private override init() {
        super.init()
        configAudioStream()
    }
    
    
    func configAudioStream() {
        let config = FSStreamConfiguration()
        config.enableTimeAndPitchConversion = true
        // 设置最大缓存
        config.maxPrebufferedByteCount = 100 * 1000 * 1000
        config.maxDiskCacheSize = 100 * 1000 * 1000
        config.cacheEnabled = true
        
        let stream = FSAudioStream(configuration: config)
        stream?.strictContentTypeChecking = false
        stream?.defaultContentType = "audio/x-m4a"
        stream?.preload()
        
        stream?.onCompletion = {
            print("完成")
        }
        
        stream?.onStateChange = {
            [weak self] state in
            guard let `self` = self else {return}
            switch state {
            case .fsAudioStreamRetrievingURL:
                print("检索URL")
                self.playState = .loading
            case .fsAudioStreamBuffering:
                print("缓冲中。。。")
                self.playState = .buffering
                self.bufferState = .buffering
            case .fsAudioStreamSeeking:
                print("seek中....")
                self.playState = .loading
            case .fsAudioStreamPlaying:
                print("播放中。。。")
                self.playState = .playing
            case .fsAudioStreamPaused:
                print("暂停播放")
                self.playState = .paused
            case .fsAudioStreamStopped:
                
                // 切换歌曲时主动调用停止方法也会走这里，需要区分是切换歌曲还是被打断停止
                if self.playState != .stopedByUser && self.playState != .ended {
                    print("播放停止")
                    self.playState = .stoped
                }
            case .fsAudioStreamRetryingFailed:
                print("检索URL失败")
                self.playState = .error
            case .fsAudioStreamRetryingStarted:
                print("检索开始")
                self.playState = .loading
            case .fsAudioStreamFailed:
                print("播放失败")
                self.playState = .error
            case .fsAudioStreamPlaybackCompleted:
                print("播放完成")
                self.playState = .ended
            case .fsAudioStreamRetryingSucceeded:
                print("检索成功")
                self.playState = .playing
            case .fsAudioStreamUnknownState:
                print("未知状态")
                self.playState = .error
            case .fsAudioStreamEndOfFile:
                print("缓冲结束")
                if self.bufferState == .finished { return }
                // 定时器停止后需要再次调用获取进度方法，防止出现进度不准确的情况
                
            
            default:
                break
            }
            
            self.delegate?.playerStatusChanged(player: self, state: self.playState)
        }
        
        audioStream = stream
    }
    

    func startTimer() {
        if self.playTimer == nil {
            self.playTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }
    }
    func stopTimer() {
        if self.playTimer != nil {
            self.playTimer?.invalidate()
            self.playTimer = nil
        }
    }
    
    @objc func timerAction() {
        DispatchQueue.main.async {
            guard let stream = self.audioStream else { return }
            let curentPosition = stream.currentTimePlayed
            let currentTime = curentPosition.playbackTimeInSeconds * 1000
            let totalTime = stream.duration.playbackTimeInSeconds * 1000
            let progress = curentPosition.position
            
            self.delegate?.playerTimeChanged(player: self, currentTime: TimeInterval(currentTime), totalTime: TimeInterval(totalTime), progress: progress)
            self.delegate?.playerTotalTime(player: self, totalTime: TimeInterval(totalTime))
        }
    }
    
    func startBufferTimer() {
        if self.bufferTimer == nil {
            self.bufferTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(bufferTimerAction), userInfo: nil, repeats: true)
        }
    }
    func stopBufferTimer() {
        if self.bufferTimer != nil {
            self.bufferTimer?.invalidate()
            self.bufferTimer = nil
        }
    }
    @objc func bufferTimerAction() {
        DispatchQueue.main.async {
            guard let stream = self.audioStream else { return }
            let preBuffer = stream.prebufferedByteCount
            let contentLength = stream.contentLength
            
            // 这里获取的进度不能准确地获取到1
            var bufferProgress = Double(contentLength > 0 ? preBuffer / Int(contentLength) : 0)
            // 为了能使进度准确的到1，这里做了一些处理
            let buffer = bufferProgress + 0.5
            
            if bufferProgress > 0.9 && buffer >= 1 {
                self.bufferState = .finished
                self.stopBufferTimer()
                // 这里把进度设置为1，防止进度条出现不准确的情况
                bufferProgress = 1.0
                print("缓冲结束")
            }else {
                self.bufferState = .buffering
            }
            
            self.delegate?.playerBufferProgress(player: self, bufferProgress: Float(bufferProgress))
        }
    }
    
}

//MARK: 公开方法
extension AudioPlayer {
    
    
    /// 设置播放地址
    /// - Parameter path: 播放地址
    func setAudioUrl(path:String) {
        self.audioUrl = path
        
        DispatchQueue.main.async {
            guard let stream = self.audioStream else {return}
            if path.hasPrefix("http") {
                stream.url = URL(string: path) as NSURL?
            }else {
                stream.url = URL(fileURLWithPath: path) as NSURL
            }
        }
        
    }
    
    /// 快进 快退
    /// - Parameter progress: 进度
    func setPlayerProgress(_ progress:Float) {
        var tempProgress = progress
        if progress == 0 {
            tempProgress = 0.001
        }
        if progress == 1 {
            tempProgress = 0.999
        }
        
        var position = FSStreamPosition()
        position.position = tempProgress
        DispatchQueue.main.async {
            self.audioStream?.seek(to: position)
        }
    }
    
    
    /// 设置播放速率 0.5-2.0 1.0为正常速率
    /// - Parameter rate: 速率
    func setPlayerRate(_ rate:Float) {
        var tempRate = rate
        if rate < 0.5 {
            tempRate = 0.5
        }
        if rate > 2 {
            tempRate = 2
        }
        DispatchQueue.main.async {
            self.audioStream?.setPlayRate(tempRate)
        }
    }
    
    
    /// 播放
    func play() {
        if self.playState == .playing { return }
        
        DispatchQueue.main.async {
            self.audioStream?.play()
        }
    
        startTimer()
        
        // 如果缓冲未能完成
        if self.bufferState != .finished {
            self.bufferState = .none
            startBufferTimer()
        }
    }
    
    
    /// 从某个进度播放
    /// - Parameter progress: 进度
    func play(by progress:Float) {
        var offset = FSSeekByteOffset()
        offset.position = progress
        
        DispatchQueue.main.async {
            self.audioStream?.play(from: offset)
        }
        
        startTimer()
        
        // 如果缓冲未能完成
        if self.bufferState != .finished {
            self.bufferState = .none
            startBufferTimer()
        }
        
    }
    
    
    /// 暂停
    func pause() {
        if self.playState == .paused { return }
        
        self.playState = .paused
        self.delegate?.playerStatusChanged(player: self, state: playState)
        
        DispatchQueue.main.async {
            self.audioStream?.pause()
        }
        stopTimer()
    }
    
    
    /// 恢复
    func resume() {
        if self.playState == .playing { return }
        
        DispatchQueue.main.async {
            // 恢复播放仍然用pause
            self.audioStream?.pause()
        }
        
        startTimer()
    }
    
    
    /// 停止
    func stop() {
        if self.playState == .stopedByUser { return }
        self.playState = .stopedByUser
        self.delegate?.playerStatusChanged(player: self, state: playState)
        
        DispatchQueue.main.async {
            self.audioStream?.stop()
        }
        
        stopTimer()
    }
}
