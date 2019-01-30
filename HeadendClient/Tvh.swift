//
//  Tvh.swift
//  TVHeadend Client
//
//  Created by Kin Wai Koo on 2019-01-01.
//

import Foundation

struct FinishedGrid: Codable {
    let entries: [VideoMetadata]
}

class VideoMetadata: Codable {
    let uuid : String
    let start : Double
    let stop : Double
    let channelName : String?
    let channelIcon : String?
    let image : String?
    let fanartImage : String?
    let title : String
    let subtitle : String?
    let description : String?
    let url : String
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case start
        case stop
        case channelName = "channelname"
        case channelIcon = "channel_icon"
        case image
        case fanartImage = "fanart_image"
        case title = "disp_title"
        case subtitle = "disp_subtitle"
        case description = "disp_description"
        case url
    }
    
    func getStartTimeAsDate() -> Date {
        return Date(timeIntervalSince1970: self.start)
        
    }
    
    func getStopTimeAsDate() -> Date {
        return Date(timeIntervalSince1970: self.stop)
        
    }
}

enum TvhServerError: Error {
    case invalidURL
    case noData
}

protocol TvhClient {
    func recordedProgramsLoaded(error: Error?)
}

protocol VideoDetailsDelegate {
    func showVideoDetails(data: VideoMetadata)
}

protocol ChannelIconDisplay {
    func showChannelIcon(data: Data)
}

class TvhServer {
    private var tvhServer: String
    private var tvhPort: Int
    private var baseURL: URL
    private var allRecordedPrograms: [VideoMetadata] = []
    private var recordedProgramTitles: [String:[VideoMetadata]] = [:]
    
    init(serverAddress: String, serverPort: Int) throws {
        self.tvhServer = serverAddress
        self.tvhPort = serverPort
        if let u: URL = URL(string: "http://\(serverAddress):\(serverPort)") {
            self.baseURL = u
        } else {
            throw TvhServerError.invalidURL
        }
    }
    
    func loadRecordedPrograms(client: TvhClient) {
        guard let url = URL(string: "/api/dvr/entry/grid_finished?limit=999999999", relativeTo: self.baseURL) else {
            client.recordedProgramsLoaded(error: TvhServerError.invalidURL)
            return
        }
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                client.recordedProgramsLoaded(error: error)
                return
            }
            guard let data = data else {
                client.recordedProgramsLoaded(error: TvhServerError.noData)
                return
            }
            do {
                let decoder = JSONDecoder()
                let serverData = try decoder.decode(FinishedGrid.self, from: data)
                self.processRecordedPrograms(entries: serverData.entries)
                client.recordedProgramsLoaded(error: nil)
            } catch let err {
                client.recordedProgramsLoaded(error: err)
            }
            }.resume()
    }
    
    func processRecordedPrograms(entries: [VideoMetadata]) {
        self.allRecordedPrograms = entries
        self.allRecordedPrograms.sort(by: { $0.start > $1.start })
        
        self.recordedProgramTitles.removeAll()
        
        for i in 0..<entries.count {
            let entry = self.allRecordedPrograms[entries.count - i - 1]
            let title = entry.title
            if let episodes = self.recordedProgramTitles[title] {
                var episodes = episodes
                episodes.append(entry)
                self.recordedProgramTitles[title] = episodes
            } else {
                self.recordedProgramTitles[title] = [entry]
            }
        }
    }
    
    func getTitles() -> [String] {
        var titles : [String] = []
        for (key, _) in self.recordedProgramTitles {
            titles.append(key)
        }
        titles.sort(by: { $0 < $1 })
        return titles
    }
    
    func getRecordedPrograms(title: String) -> [VideoMetadata] {
        if title == "" { return self.allRecordedPrograms }
        
        if let programs = self.recordedProgramTitles[title] { return programs }
        
        return []
    }
    
    func getChannelIcon(video: VideoMetadata, delegate: ChannelIconDisplay) {
        guard let iconPath = video.channelIcon else
            { return }
        guard let iconURL = URL(string: iconPath, relativeTo: self.baseURL) else
            { return }
        URLSession.shared.dataTask(with: iconURL, completionHandler: { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                delegate.showChannelIcon(data: data)
            }
        }).resume()
    }
    
    func getVideoURL(video: VideoMetadata) -> URL? {
        return URL(string: video.url, relativeTo: baseURL)
    }
}
