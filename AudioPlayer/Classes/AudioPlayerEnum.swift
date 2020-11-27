//
//  AudioPlayerState.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import Foundation

/// 播放器播放状态
enum AudioPlayerState {
    /// 加载中
    case loading
    /// 缓冲中
    case buffering
    /// 播放中
    case playing
    /// 暂停
    case paused
    /// 停止（用户切换歌曲时调用）
    case stopedByUser
    /// 停止 （播放器主动发出：如播放被打断）
    case stoped
    /// 结束 （播放完成）
    case ended
    /// 错误
    case error
}

/// 播放器缓冲状态
enum AudioBufferState {
    /// 缓冲中
    case buffering
    /// 缓冲结束
    case finished
    case none
}
