//
//  ViewController.swift
//  rush01
//
//  Created by Liudmyla POHRIBNIAK on 4/13/19.
//  Copyright © 2019 Liudmyla POHRIBNIAK. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class locationCell: UITableViewCell {
    @IBOutlet weak var locationCell: UILabel!
}

class customCell: UITableViewCell {
    
    @IBOutlet weak var proposedLocationLabel: UILabel!
}

extension ViewController: GMSMapViewDelegate {
    
    
    func createMarker(titleMarker: String, iconMarker: UIImage, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        marker.title = titleMarker
        marker.icon = iconMarker
        marker.map = mapView
    }
    
    func showAlert(err : String) {
        let alert = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default,
                                   handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func drawPath(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D)
    {
        let origin = "\(startLocation.latitude),\(startLocation.longitude)"
        let destination = "\(endLocation.latitude),\(endLocation.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyDuCofUuvYuYWUZplyQlGcYr90Fgo1Brss"
        
        let searchurl = NSURL(string : url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!)
        let searchrequest = NSMutableURLRequest(url : searchurl! as URL)
        
        let taskSearch = URLSession.shared.dataTask(with: searchrequest as URLRequest) {
            (data, response, error) in
            if error != nil {
                self.showAlert(err: "Routes not Found")
                return
            } else if data != nil {
                do {
                    let dic : NSDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    let routes = dic["routes"] as? [NSDictionary]
                    if dic["status"] as! String == "ZERO_RESULTS" {
                        self.showAlert(err: "Routes not Found")
                    }
                    if routes != nil{
                        for route in routes! {
                            let routeOverviewPolyline = route["overview_polyline"] as? NSDictionary
                            if(routeOverviewPolyline != nil){
                                var points = ""
                                for (key, value) in routeOverviewPolyline! {
                                    if ("\(key)" == "points"){
                                        points = value as! String
                                        
                                        DispatchQueue.main.async {
                                            
                                            let path = GMSPath.init(fromEncodedPath: points)
                                            
                                            
                                            
                                            let polyline = GMSPolyline.init(path: path)
                                            
                                            polyline.strokeWidth = 5
                                            polyline.strokeColor = UIColor(red: 221, green: 151, blue: 1, alpha: 1.0)
                                            polyline.geodesic = true
                                            polyline.map = self.mapView
                                            self.mapView.animate(with: GMSCameraUpdate.fit(GMSCoordinateBounds(path: path!)))
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                        self.showAlert(err: "Routes not Found")
                    }
                }catch {
                    self.showAlert(err: "Routes not Found")
                    return
                }
            }
        }
        taskSearch.resume()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = dropOffTable.dequeueReusableCell(withIdentifier: "predictCell") as! customCell
        if indexPath.row == 0 {
            let cell = dropOffTable.dequeueReusableCell(withIdentifier: "myLocationCell") as! locationCell
            cell.locationCell.text = "Current location"
             return cell
        } else {
        let cell = dropOffTable.dequeueReusableCell(withIdentifier: "predictCell") as! customCell
            cell.proposedLocationLabel.text = predictions[indexPath.row - 1].attributedFullText.string
             return cell
        }
//         return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let NewView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height:20))
        NewView.alpha = 0.5
        let title = UILabel(frame: CGRect(x: 0, y: 0, width: NewView.frame.width, height: NewView.frame.height))
        title.font = UIFont(name: "Verdana", size: 15)
        title.text = "Search"
        title.textColor = UIColor.black
        NewView.addSubview(title)
        NewView.backgroundColor = UIColor.lightGray
        return NewView
    }
        
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row != 0 {
        self.placesClient.lookUpPlaceID(self.predictions[indexPath.row - 1].placeID , callback: { (place, error) in
            if tableView == self.pickUpTable {
                self.pickUpLocation.text = self.predictions[indexPath.row - 1].attributedFullText.string
                self.start_loc = place?.coordinate
                if self.finish_loc == nil {
                    self.mapView.clear()
                    self.dropOffLocation.text = ""
                }
                self.createMarker(titleMarker: "Start", iconMarker: #imageLiteral(resourceName: "start"), latitude: (place?.coordinate.latitude)!, longitude: (place?.coordinate.longitude)!)

            }else{
                self.dropOffLocation.text =  self.predictions[indexPath.row - 1].attributedFullText.string
                self.finish_loc = place?.coordinate
                if self.start_loc == nil {
                    self.mapView.clear()
                    self.pickUpLocation.text = ""
                }
                self.createMarker(titleMarker: "Finish", iconMarker: #imageLiteral(resourceName: "finish"), latitude: (place?.coordinate.latitude)!, longitude: (place?.coordinate.longitude)!)
            }
            if self.start_loc != nil && self.finish_loc != nil {
                self.drawPath(startLocation: self.start_loc, endLocation: self.finish_loc)
                self.start_loc = nil
                self.finish_loc = nil
            }
            self.mapView.camera = GMSCameraPosition(latitude:  (place?.coordinate.latitude)!, longitude: (place?.coordinate.longitude)!, zoom: 16)
        })
        } else {
            if let currlocation = locationManager.location?.coordinate {
                if tableView == self.dropOffTable {
                    dropOffLocation.text = "Current location"
                    self.finish_loc = locationManager.location?.coordinate
                    if self.start_loc == nil {
                        self.mapView.clear()
                        self.pickUpLocation.text = ""
                    }
                    self.createMarker(titleMarker: "Finish", iconMarker: #imageLiteral(resourceName: "finish"), latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
                }
            if tableView == self.pickUpTable {
                self.start_loc = locationManager.location?.coordinate
                if self.finish_loc == nil {
                    self.mapView.clear()
                    self.dropOffLocation.text = ""
                }
                self.createMarker(titleMarker: "Start", iconMarker: #imageLiteral(resourceName: "start"), latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
                
               pickUpLocation.text = "Current location"
            }
            if self.start_loc != nil && self.finish_loc != nil {
                self.drawPath(startLocation: self.start_loc, endLocation: self.finish_loc)
                self.start_loc = nil
                self.finish_loc = nil
            }
            self.mapView.camera = GMSCameraPosition(latitude:  (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!, zoom: 16)
            
            self.pickUpLocation.resignFirstResponder()
            self.dropOffLocation.resignFirstResponder()
            self.view.sendSubview(toBack: self.dropOffView)
            self.view.sendSubview(toBack: self.pickUpView)
            } else {
                showAlert(err: "Tne location is not allowed")
            }
        }
            tableView.deselectRow(at: indexPath, animated: false)
        view.sendSubview(toBack: dropOffView)
        view.sendSubview(toBack: pickUpView)
        pickUpLocation.resignFirstResponder()
        dropOffLocation.resignFirstResponder()
    }
}

extension ViewController: UITextFieldDelegate {

    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        predictions = []
        pickUpTable.reloadData()
        dropOffTable.reloadData()
        
        if textField == pickUpLocation {
            view.bringSubview(toFront: pickUpView)
            view.sendSubview(toBack: dropOffView)
        }else{
            view.bringSubview(toFront: dropOffView)
            view.sendSubview(toBack: pickUpView)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.sendSubview(toBack: dropOffView)
        view.sendSubview(toBack: pickUpView)
        textField.resignFirstResponder()
//        predictions = []
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        
        placesClient.findAutocompletePredictions(fromQuery: textField.text!, bounds: GMSCoordinateBounds().includingCoordinate((locationManager.location?.coordinate)!), boundsMode: GMSAutocompleteBoundsMode(rawValue: 0)!, filter: nil, sessionToken: sessionToken) { (res, error) in
            self.predictions = res!
            
                
                if textField == self.pickUpLocation {
                    self.pickUpTable.reloadData()
                }else{
                    self.dropOffTable.reloadData()
                }
            
        }
    
        
        return true
    }
}

class ViewController: UIViewController {

    let locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    let sessionToken = GMSAutocompleteSessionToken.init()
    var predictions : [GMSAutocompletePrediction] = []
    let fields: GMSPlaceField = GMSPlaceField(rawValue: 0)!
    var start_loc: CLLocationCoordinate2D!
    var finish_loc: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var pickUpLocation: UITextField!
    @IBOutlet weak var dropOffLocation: UITextField!
    @IBOutlet weak var pickUpView: UIView!
    @IBOutlet weak var dropOffView: UIView!
    @IBOutlet weak var dropOffTable: UITableView!
    @IBOutlet weak var pickUpTable: UITableView!
    
    
    @IBAction func changeMapType(_ sender: UISegmentedControl) {
        switch  sender.titleForSegment(at: sender.selectedSegmentIndex) {
        case "Normal"?:
            mapView.mapType = .normal
        case "Satellite"?:
            mapView.mapType = .satellite
        case "Terrain"?:
            mapView.mapType = .terrain
        default:
            return
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        placesClient = GMSPlacesClient.shared()
        
        pickUpLocation.delegate = self
        dropOffLocation.delegate = self
        
        
        dropOffTable.delegate = self
        pickUpTable.delegate = self
        pickUpTable.dataSource = self
        dropOffTable.dataSource = self
        
        
        view.bringSubview(toFront: pickUpLocation)
        view.bringSubview(toFront: dropOffLocation)

        mapView.delegate =  self
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.mapType = .normal
    }



}

