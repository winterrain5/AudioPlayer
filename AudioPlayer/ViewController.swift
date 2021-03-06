//
//  ViewController.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit
//少司命 - 客官请进
let music1 = "http://music.163.com/song/media/outer/url?id=444444053.mp3"
//Mike Zhou - The Dawn
let music2 = "http://music.163.com/song/media/outer/url?id=476592630.mp3"
//大鱼 - 周深
let music3 = "http://music.163.com/song/media/outer/url?id=413812448.mp3"

let video = "https://file.victor.vip/upload/2020/10/13/13/24/6E3094C-0E4C-4D4E-A106-592EB81E23F9.mp4"

class ViewController: UITableViewController {
 
    var datas:[String] = ["少司命 - 客官请进","Mike zhou - The Dawn","大鱼 - 周深","播放视频"]
    var music:[String] = [music1,music2,music3]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = datas[indexPath.row]
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 3 {
            let vc = VideoPlayController()
            vc.videoUrl = video
            self.navigationController?.pushViewController(vc, animated: true)
        }else {
            let vc = AudioPlayerController.shared
            vc.audioList = music
            self.navigationController?.pushViewController(vc, animated: true)
            vc.playMusic(with: music[indexPath.row])
        }
        
        
    }

}

