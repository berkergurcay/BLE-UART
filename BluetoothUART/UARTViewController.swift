//
//  ViewController.swift
//  BluetoothTable
//
//  Created by berker gurcay on 25.07.2019.
//  Copyright © 2019 berker gurcay. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController,UITextViewDelegate,UITextFieldDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!
    
    private var asciiText:NSAttributedString? = NSAttributedString(string: "")
    let newFont = UIFont(name: "Helvetica Neue", size: 13)
    let newLine = "\n"
    
    
    var peripheral : CBPeripheral?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.textView.text = " "
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        self.textView.delegate = self
        self.textField.delegate = self
        incomingData()
        characteristicValue = ""
    }
    override func viewDidAppear(_ animated: Bool) {
        self.textView.text = "[Received]: "
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.textView.text = "[Received]: "
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func incomingData(){
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil, queue: nil){
            notification in
            
           
            let receivedAttributes = [NSAttributedStringKey.font : self.newFont!, NSAttributedStringKey.foregroundColor: UIColor.red]
            let newAttributedString = NSAttributedString(string: "[Received]: " + (characteristicValue as String), attributes: receivedAttributes)
            let newAsciiText = NSMutableAttributedString(attributedString: self.asciiText!)
            self.textView.attributedText = NSAttributedString(string: characteristicValue as String, attributes: receivedAttributes)
            
            newAsciiText.append(newAttributedString)
            
            self.asciiText = newAsciiText
            self.textView.attributedText = self.asciiText
            
        }
        
    }
    
    func sendData(){
        
        
        let sentData = textField.text
        
       
        let sentAttributes = [NSAttributedStringKey.font: newFont!, NSAttributedStringKey.foregroundColor: UIColor.blue]
        
       
        
        let attribString = NSAttributedString(string: "[Sent]: " + sentData! + self.newLine, attributes:sentAttributes)
        let newAsciiText = NSMutableAttributedString(attributedString: self.asciiText!)
        
        newAsciiText.append(attribString)
        
        self.asciiText = newAsciiText
        textView.attributedText = self.asciiText
        
        
        
        
        let valueString = (sentData as! NSString).data(using: String.Encoding.utf8.rawValue)
        
        if let cbPeripheral = cbPeripheral{
            if let txCharacteristic = txCharacteristic {
                cbPeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)    }
   
    
    
        }
    
    }
 
    @IBAction func sendButton(_ sender: Any) {
        sendData()
        textField.text = ""
    
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0,y:250), animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    

  

}

