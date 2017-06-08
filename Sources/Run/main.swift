import App
import HTTP
import SlackKit
import Foundation
/// We have isolated all of our App's logic into
/// the App module because it makes our app
/// more testable.
///
/// In general, the executable portion of our App
/// shouldn't include much more code than is presented
/// here.
///
/// We simply initialize our Droplet, optionally
/// passing in values if necessary
/// Then, we pass it to our App's setup function
/// this should setup all the routes and special
/// features of our app
///
/// .run() runs the Droplet's commands,
/// if no command is given, it will default to "serve"





// Declaring vars
//  let Client_id = ""
//  let Client_secret = ""
//  let Refresh_token = ""
//  let API_Key = ""
//  var Access_token = ""
//  let gfycatClientId = ""
//  let gfycatClientSecret = ""
//   let slackBotToken = ""

let tfmt = "srt"


// Instantiate a Drop
let config = try Config()
try config.setup()
let drop = try Droplet(config)



// Declaring Methods



// Call methods

let bot = SlackKit()

bot.addRTMBotWithAPIToken(slackBotToken)
bot.addWebAPIAccessWithToken(slackBotToken)

bot.notificationForEvent(.message) {(event, client) in
    
    
    guard
        let message = event.message,
        let id = client?.authenticatedUser?.id,
        message.text?.contains(id) == true
        else {
            return
    }
    
    
    
    
    if let newToken = refreshYoutubeToken(), var searchedText: String = event.message?.text, let channel = message.channel {
        Access_token = newToken
        
            searchedText.removeSubrange(searchedText.startIndex...searchedText.characters.index(of: " ")!)
        
            while searchedText.characters[searchedText.startIndex] == " " {
                
                searchedText.remove(at: searchedText.startIndex)

        }
        
        
        
        
        
        var bestCaptions = [Caption]()
        if let videoIdArray = getVideoIds(search: searchedText,maxResults: 10){
            
            videoIdArray.forEach({ (my_videoId) in
                
                
                if let captionIds = getCaptionIds(videoId: my_videoId){
                    
                    captionIds.forEach{ (captionId) in
                        
                        if let captionString = getCaption(id: captionId) {
                            
                            if let caption = Caption(id: captionId, subtitleRaw: captionString, videoId: my_videoId){
                                
                                let numberOfIteration = caption.countOfWord(searchedText)
                                
                                
                                if numberOfIteration != 0  {
                                    bestCaptions.append(caption)
                                }
                                print (numberOfIteration)
                                
                            }
                        }
                    }
                }
            })
        }
        
        bestCaptions = bestCaptions
            .filter({caption -> Bool in caption.countOfWord(searchedText) != 0})
            .sorted(by: { (caption1, caption2) -> Bool in
                caption1.countOfWord(searchedText) > caption2.countOfWord(searchedText)
                
            })
        let randomCaption = bestCaptions.random()
        
        print(randomCaption?.videoId ?? "no match")
        
        if let punchlines = randomCaption?.subtitlesWithWord(word: searchedText) {   // extraction des sous-titres contenant le mot cherché dans un Caption random de bestCaptions
            
            if punchlines.count != 0 {
                
                let randomPunchline = punchlines.random()
                
                let reaction = "https://thumbs.gfycat.com/" + getYoutubeGif(videoId: (randomCaption!.videoId), startDate: (randomPunchline?.startDateNumber())!, endDate: (randomPunchline?.endDateNumber())!, captionText: (punchlines.first?.text)! + "-size_restricted.gif")  //getyoutubeGif sur une "punchline" random
                
                // print(getYoutubeGif(videoId: (bestCaptions.first?.videoId)!, startDate: (punchlines.last?.startDateNumber())!, endDate: (punchlines.last?.endDateNumber())!, captionText: (punchlines.last?.text)!)) //getyoutubeGif sur la dernière "punchline"
                
                bot.webAPI?.sendMessage(channel: channel, text: reaction, success: nil, failure: nil)
                return
            }
            
            
        }
        
        bot.webAPI?.addReaction(name: "Pardon?", channel: channel, timestamp: message.ts, success: nil, failure: nil)
        return
    }
    
}


// Start HTTP Server with no routes
//try drop.run()

RunLoop.main.run()


