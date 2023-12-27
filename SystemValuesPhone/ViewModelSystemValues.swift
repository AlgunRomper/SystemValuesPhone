//
//  ViewModelSystemValues.swift
//  SystemValuesPhone
//
//  Created by Algun Romper  on 27.12.2023.
//

import Foundation
import Alamofire
import UIKit

final class ViewModelSystemValuesOfPhone: ObservableObject {
    @Published var wifiDownload: Float = 0.0
    @Published var wifiUpLoad: Float = 0.0
    @Published var systemVersion: String = ""
    @Published var ram: Float = 0
    @Published var cpu: Float = 0.0
    
    private var updateTimer: DispatchSourceTimer?
    
    init() {
        getWifiDownload { speed in
            if let speed = speed {
                DispatchQueue.main.async {
                    self.wifiDownload = Float(speed)
                }
            }
        }
        getWifiDownload { speed in
            if let speed = speed {
                DispatchQueue.main.async {
                    self.wifiUpLoad = Float(speed)
                }
            }
        }
        self.systemVersion = getIosVersion()
        self.cpu = getCPUUsage()
        self.ram = getRAMUsage()
    }

    func startUpdatingValues() {
        let queue = DispatchQueue(label: "")
        updateTimer = DispatchSource.makeTimerSource(queue: queue)
        updateTimer?.schedule(deadline: .now(), repeating: .seconds(3))
        updateTimer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.cpu = self?.getCPUUsage() ?? 0.0
                self?.ram = self?.getRAMUsage() ?? 0.0
                self?.getWifiDownload { speed in
                    if let speed = speed {
                        DispatchQueue.main.async {
                            self?.wifiDownload = Float(speed)
                        }
                    }
                }
                self?.getWifiDownload { speed in
                    if let speed = speed {
                        DispatchQueue.main.async {
                            self?.wifiUpLoad = Float(speed)
                        }
                    }
                }
            }
            
        }
        updateTimer?.resume()
    }

    func stopUpdatingValues() {
        updateTimer?.cancel()
        updateTimer = nil
    }

    //Version
    private func getIosVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    //WifiDownload
    private func getWifiDownload(completion: @escaping (Double?) -> Void) {
        let url = "https://www.google.com/?client=safari"
        AF.download(url).validate().responseData { response in
            guard let data = response.value, let duration = response.metrics?.taskInterval.duration else {
                completion(nil)
                return
            }

            let bytes = Double(data.count)
            let kilobytes = bytes / 1024
            let speed = kilobytes / duration

            completion(speed)
        }
    }

    //WifiUpload
    private func getWifiUpload(completion: @escaping (Double?) -> Void) {
        let text = "Test upload content"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testSpeedFile.txt")

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write file")
        }

        let url = "https://www.google.com/?client=safari"

        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(fileURL, withName: "testSpeedFile")
        },
                  to: url).validate().responseData { response in
            guard let data = response.value,
                  let duration = response.metrics?.taskInterval.duration else
            { completion(nil)
                return
            }

            let bytes = Double(data.count)
            let kilobytes = bytes / 1024
            let speed = kilobytes / duration

            completion(speed)
        }
    }

    //RAM
    private func getRAMUsage() -> Float {
        let physicalMemory = Float(ProcessInfo.processInfo.physicalMemory)
        let total_megabytes = physicalMemory / 1024.0 / 1024.0

        var usedMemory: Int64 = 0
        var totalUsedMemoryInMB: Float = 0
        var availableRAMInMb: Float = 0

        let hostPort: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        var pagesize:vm_size_t = 0
        host_page_size(hostPort, &pagesize)
        var vmStat: vm_statistics = vm_statistics_data_t()
        let capacity = MemoryLayout.size(ofValue: vmStat) / MemoryLayout<Int32>.stride

        let status: kern_return_t = withUnsafeMutableBytes(of: &vmStat) {
        let boundPtr = $0.baseAddress?.bindMemory( to: Int32.self, capacity: capacity )
                   return host_statistics(hostPort, HOST_VM_INFO, boundPtr, &host_size)
        }

        if status == KERN_SUCCESS {
            usedMemory = (Int64)((vm_size_t)(vmStat.active_count + vmStat.inactive_count + vmStat.wire_count) * pagesize)
            totalUsedMemoryInMB = (Float)( usedMemory / 1024 / 1024 )
            availableRAMInMb = total_megabytes - totalUsedMemoryInMB
        }

        return availableRAMInMb
    }
    
    //CPU
    private func getCPUUsage() -> Float {
        var usage = Float(0.0)
        
        var totalUsageOfCPU: Double = 0.0
        var threads = thread_act_array_t(bitPattern: 0)
        var thread_count = mach_msg_type_number_t()
        
        let kr = withUnsafeMutablePointer(to: &threads) {
            task_threads(mach_task_self_, $0, &thread_count)
        }
        
        if kr == KERN_SUCCESS {
            for i in 0..<Int(thread_count) {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                
                let kr = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threads![i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                if kr == KERN_SUCCESS {
                    totalUsageOfCPU += Double(threadInfo.cpu_usage)
                }
            }
        }
        
        if thread_count > 0 {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(thread_count))
        }
        
        usage = Float(totalUsageOfCPU) / 10
        
        return usage
    }
}

//MARK: Get storage value
extension UIDevice {
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    //MARK: Get String Value
    var totalDiskSpaceInGB: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalDiskSpaceInBytes), countStyle: ByteCountFormatter.CountStyle.file)
    }
    
    var freeDiskSpaceInGB: String {
        ByteCountFormatter.string(fromByteCount: Int64(freeDiskSpaceInBytes), countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var usedDiskSpaceInGB: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedDiskSpaceInBytes), countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInMB: String {
        return MBFormatter(Int64(totalDiskSpaceInBytes))
    }
    
    var freeDiskSpaceInMB: String {
        return MBFormatter(Int64(freeDiskSpaceInBytes))
    }
    
    var usedDiskSpaceInMB: String {
        return MBFormatter(Int64(usedDiskSpaceInBytes))
    }
    
    //MARK: Get raw value
    var totalDiskSpaceInBytes: Float {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.floatValue else { return 0 }
        return space
    }
    
    var freeDiskSpaceInBytes: Float {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return Float(space)
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.floatValue {
                return freeSpace
            } else {
                return 0
            }
        }
    }
    
    var usedDiskSpaceInBytes: Float {
       return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }

}
