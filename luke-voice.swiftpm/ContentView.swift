import AudioKit
import AudioKitEX
import AudioKitUI
import SoundpipeAudioKit
import AVFoundation
import SwiftUI

struct RecorderData {
    var isRecording = false
    var isPlaying = false
    var pitch = 0.0
}

class RecorderConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var recorder: NodeRecorder?
    let player = AudioPlayer()
    var silencer: Fader?
    let mixer = Mixer()
    var pitchTap: PitchTap!
    
    @Published var data = RecorderData() {
        didSet {
            if data.isRecording {
                do {
                    try recorder?.record()
                } catch let err {
                    print(err)
                }
            } else {
                recorder?.stop()
            }

            if data.isPlaying {
                if let file = recorder?.audioFile {
                    player.file = file
                    player.play()
                }
            } else {
                player.stop()
            }
        }
    }

    init() {
        guard let input = engine.input else {
            fatalError()
        }

        do {
            recorder = try NodeRecorder(node: input)
        } catch let err {
            fatalError("\(err)")
        }

        let silencer = Fader(input, gain: 0)
        self.silencer = silencer
        
        mixer.addInput(silencer)
        mixer.addInput(player)
        
        engine.output = mixer
        
        pitchTap = PitchTap(input, handler: { pitch, amp in
            // Handle the pitch and amplitude values here
            print("Pitch: \(pitch), Amplitude: \(amp)")
            self.data.pitch = Double(pitch.first!)
        })
        
    }
    
    func start() {
        // Start the audio engine
        do {
            try engine.start()
            pitchTap.start()
        } catch let err {
            fatalError("\(err)")
        }
    }
    
    func stop() {
        // Stop the pitch tap node and the audio engine
        pitchTap.stop()
        engine.stop()
    }
}


struct ContentView: View {
    @StateObject var conductor = RecorderConductor()

    var body: some View {
        VStack {
            Spacer()
            Text(conductor.data.isRecording ? "STOP RECORDING" : "RECORD")
                .foregroundColor(.blue)
                .onTapGesture {
                conductor.data.isRecording.toggle()
            }
            Spacer()
            Text(conductor.data.isPlaying ? "STOP" : "PLAY")
                .foregroundColor(.blue)
                .onTapGesture {
                conductor.data.isPlaying.toggle()
            }
            Spacer()
            Text(String(conductor.data.pitch))
        }

        .padding()
        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
    }
}
