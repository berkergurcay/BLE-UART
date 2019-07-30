//
//  BluetoothTableViewController.swift
//  BluetoothTable
//
//  Created by berker gurcay on 25.07.2019.
//  Copyright © 2019 berker gurcay. All rights reserved.
//

import UIKit
import CoreBluetooth


var rxCharacteristic : CBCharacteristic?
var txCharacteristic : CBCharacteristic?
var characteristicValue = NSString()
 var cbPeripheral : CBPeripheral?

//Uart Service uuid


let kBLEService_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
let kBLE_Characteristic_uuid_Tx = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
let kBLE_Characteristic_uuid_Rx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
let MaxCharacters = 20

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)





class BluetoothTableViewController: UITableViewController,CBCentralManagerDelegate,CBPeripheralDelegate {
    
    
    @IBOutlet weak var deviceTable: UITableView!
    
    @IBAction func refreshButton(_ sender: UIBarButtonItem) {
        cancelScan()
        disconnectFromDevice()
        peripherals = []
        self.deviceTable.reloadData()
        startScan()
    }
    var cbBluetoothManager : CBCentralManager?
    var peripherals : [CBPeripheral] = []
    var timer = Timer()
    var RSSIs : [NSNumber] = []
   
    var upcomingData : String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.deviceTable.delegate = self
        self.deviceTable.dataSource = self
        
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        cbBluetoothManager = CBCentralManager(delegate: self, queue: nil)
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        disconnectFromDevice()
        super.viewDidDisappear(animated)
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("State is unknown")
        case .resetting:
            print("State is resetting")
        case .unsupported:
            print("Bluetooth is not supported")
        case .unauthorized:
            print("Bluetooth is unathorized")
        case .poweredOff:
            print("Bluetooh not enabled")
            
            let alert = UIAlertController(title: "Bluetooth is not enabled", message: "In order to scan devices plesae enable bluetooth", preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
                
                self.dismiss(animated: true, completion: nil)
            })
            
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        case .poweredOn:
            print("Bluetooth is powered on")
            startScan()
        }
    }
    func startScan(){
        peripherals = []
        print("Scan started")
        self.timer.invalidate()
        cbBluetoothManager?.scanForPeripherals(withServices: [BLEService_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        Timer.scheduledTimer(timeInterval: 15, target: self,selector: #selector(self.cancelScan),userInfo:nil,repeats: false )
    }
    
    @objc func cancelScan(){
        
        if (cbBluetoothManager?.isScanning)!{
        self.cbBluetoothManager?.stopScan()
        print("Scan stopped")
        }
        
    }
    func connectToDevice(){
        if cbPeripheral != nil {
            
            cbBluetoothManager?.connect(cbPeripheral!)
        }else{
            print("Cannot connect to device")
        }
    }
    func disconnectFromDevice(){
        if cbPeripheral != nil {
            cbBluetoothManager?.cancelPeripheralConnection(cbPeripheral!)
            print("Disconnected from peripheral: \(String(describing: cbPeripheral))")
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Peripherals discovered")
        print(peripheral)
        cbPeripheral = peripheral
        self.RSSIs.append(RSSI)
        self.peripherals.append(peripheral)
        cbPeripheral?.delegate = self
        deviceTable.reloadData()
    
    }
    
    
    

    // MARK: - Table view data source

  

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.peripherals.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "PeripheralTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PeripheralTableViewCell else {
            fatalError("The dequeued cell is not an instance of PeripheralTableViewCell")
        }
        
        let peripheral = peripherals[indexPath.row]
        let rssi = RSSIs[indexPath.row]
        
        if peripheral.name == nil {
            cell.deviceNameLabel.text = nil
        }else{
            cell.deviceNameLabel.text = peripheral.name
        }
        cell.rssiLabel.text = "RSSI: \(rssi)"
        

         

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(peripherals[indexPath.row])
        cbPeripheral = peripherals[indexPath.row]
        connectToDevice()
        cancelScan()
    
        
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(String(describing: cbPeripheral))")
        peripheral.delegate = self
        
        cbPeripheral?.discoverServices([BLEService_UUID])
        
        
        let storyboard = UIStoryboard(name:"Main", bundle: nil)
        
        let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        
        viewController.peripheral = peripheral
        
        navigationController?.pushViewController(viewController, animated: true)
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        self.peripherals = []
        self.RSSIs = []
        self.tableView.reloadData()
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil{
            print("Error discovering services")
            print(error.debugDescription)
            return
        }
        guard let services = peripheral.services else{
            return
        }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            print(error.debugDescription as Any)
            return
        }
        guard let characteristics = service.characteristics else {return}
        
        for characteristic in characteristics {
            if characteristic.uuid == BLE_Characteristic_uuid_Rx {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                
                peripheral.readValue(for: rxCharacteristic!)
                print("RX Characteristic: \(String(describing: rxCharacteristic?.uuid))")
            }
        
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                
                print("TX Characteristic: \(String(describing: txCharacteristic))")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            if error != nil {
                print(error.debugDescription)
                return
            }
            if rxCharacteristic == characteristic {
                print(characteristic.value)
                if let value = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                    characteristicValue = value
                    print("Value received: \(characteristicValue as String )")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue:"Notify"),object: nil)
                }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        print("Notification state has changed for: \(characteristic.uuid)")
        
    }
    

    
 

}
