//
//  ContentView.swift
//  SystemValuesPhone
//
//  Created by Algun Romper  on 27.12.2023.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var modelSystemValues = ViewModelSystemValuesOfPhone()

    var systemVersion: String {
        modelSystemValues.systemVersion
    }
    var storageSize: String {
        UIDevice.current.totalDiskSpaceInGB
    }
    var storageUsed: String {
        UIDevice.current.usedDiskSpaceInGB
    }
    var wifiDownload: Float {
        modelSystemValues.wifiDownload
    }
    var wifiUpload: Float {
        modelSystemValues.wifiUpLoad
    }
    var ram: Float {
        modelSystemValues.ram
    }
    var cpu: Float {
        modelSystemValues.cpu
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Phone info")
                    .bold()
                
                HStack {
                    PhoneInfoView(type: "iOS Version", info: "", value: systemVersion)
                }
                HStack {
                    PhoneInfoView(type: "Storage Size", info: "", value: storageSize)
                    PhoneInfoView(type: "Storage Used", info: "", value: storageUsed)
                }
                HStack(spacing: 10) {
                    PhoneInfoView(type: "Wifi", info: "download", value: "\(String(format: "%.2f", wifiDownload)) KB/s")
                    PhoneInfoView(type: "Wifi", info: "upload", value: "\(String(format: "%.2f", wifiUpload)) KB/s")
                }
                
                HStack(spacing: 10) {
                    PhoneInfoView(type: "RAM", info: "Available", value: "\(String(format: "%.2f", ram)) Mb")
                    
                    PhoneInfoView(type: "CPU", info: "used", value: "\(cpu) %")
                }
                Spacer()
            }
            .padding(20)
        }
        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
        .onAppear {
            modelSystemValues.startUpdatingValues()
        }
        .onDisappear {
            modelSystemValues.stopUpdatingValues()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var modelSystemValues = ViewModelSystemValuesOfPhone()
    
    static var previews: some View {
        ContentView()
            .environmentObject(modelSystemValues)
    }
}
