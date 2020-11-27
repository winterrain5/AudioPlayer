//
//  AudioPlayerVolumeView.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/27.
//

import UIKit
import MediaPlayer
import AVFoundation
class AudioPlayerVolumeView: MPVolumeView {

    var volumeValue:Float = 0
    
    var valueChanged:((_ value:Float)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        /// 滑竿
        self.setMaximumVolumeSliderImage(UIImage(named: "cm2_fm_vol_bg"), for: .normal)
        self.setMinimumVolumeSliderImage(UIImage(named: "cm2_fm_vol_cur"), for: .normal)
        self.setVolumeThumbImage(UIImage(named: "cm2_fm_vol_btn"), for: .normal)
        
        /// airplay
        self.setRouteButtonImage(UIImage(named: "cm2_play_icn_airplay"), for: .normal)
        self.setRouteButtonImage(UIImage(named: "cm2_play_icn_airplay_prs"), for: .highlighted)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
