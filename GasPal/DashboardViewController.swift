//
//  DashboardViewController.swift
//  GasPal
//
//  Created by Kumawat, Diwakar on 4/28/17.
//  Copyright © 2017 Tyler Hackley Lewis. All rights reserved.
//

import UIKit
import Charts
import MapKit

class DashboardViewController: UIViewController, MKMapViewDelegate, LocationServiceDelegate {

    @IBOutlet weak var headerView: Header!
    @IBOutlet weak var mpgChartView: LineChartView!
    @IBOutlet weak var mpgFilterSegmentedControl: UISegmentedControl!
    
    var lineChartColors: [UIColor] = [UIColor.blue, UIColor.red, UIColor.yellow]
    
    var vehicles: [VehicleModel]!
    var selectedVehicleIndexes: [Int] = [Int]() // The vehicles user is including in chart
    var selectedTimelineFilter: TrackingTimelineFilter = TrackingTimelineFilter.lastWeek
    
    @IBOutlet weak var mapView: MKMapView!

    let CLIENT_ID = "QA1L0Z0ZNA2QVEEDHFPQWK0I5F1DE3GPLSNW4BZEBGJXUCFL"
    let CLIENT_SECRET = "W2AOE1TYC4MHK5SZYOUGX0J3LVRALMPB4CXT3ZH21ZCPUMCU"
    
    var results: NSArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DashboardViewController")
        
        headerView.title = "Dashboard"
        
        mpgFilterSegmentedControl.apportionsSegmentWidthsByContent = true
        mpgFilterSegmentedControl.insertSegment(withTitle: TrackingTimelineFilter.lastYear.rawValue, at: 2, animated: false)
        mpgFilterSegmentedControl.insertSegment(withTitle: TrackingTimelineFilter.allTime.rawValue, at: 3, animated: false)
        
        // Map View
        //one degree of latitude is approximately 111 kilometers (69 miles) at all times.
        let sfRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(37.386051, -122.083855),
                                              MKCoordinateSpanMake(0.5, 0.5))
        
        mapView.delegate = self
        
        mapView.setRegion(sfRegion, animated: false)
        
        fetchLocations("Gas Station")
        
        // Load vehicles to build mpg charts
        ParseClient.sharedInstance.getVehicles(success: { (vehicles: [VehicleModel]) in
            self.vehicles = vehicles
            for i in 0...vehicles.count - 1 { self.selectedVehicleIndexes.append(i) }
            self.createChart()
            
            // Create checkboxes for user to select which vehicles are shown in chart
            self.createCheckboxes()
        }) { (Error) in
            print("ERROR GETTING VEHICLES")
        }
    }
    
    func onLocationChange(location: CLLocation) {
        print("location: ", location)
        
//        let sfRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(37.783333, -122.416667),
//                                              MKCoordinateSpanMake(0.1, 0.1))
        
        let sfRegion = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.1, 0.1))
        
        mapView.setRegion(sfRegion, animated: false)
        
        print("set the location")

    }
    
    func fetchLocations(_ query: String, near: String = "Mountain View") {
        let baseUrlString = "https://api.foursquare.com/v2/venues/search?"
        let queryString = "client_id=\(CLIENT_ID)&client_secret=\(CLIENT_SECRET)&v=20141020&near=\(near),CA&query=\(query)"
        
        let url = URL(string: baseUrlString + queryString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
        let request = URLRequest(url: url)
        
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request,
                                                         completionHandler: { (dataOrNil, response, error) in
                                                            if let data = dataOrNil {
                                                                if let responseDictionary = try! JSONSerialization.jsonObject(
                                                                    with: data, options:[]) as? NSDictionary {
                                                                    NSLog("response: \(responseDictionary)")
                                                                    self.results = responseDictionary.value(forKeyPath: "response.venues") as! NSArray
                                                                    
                                                                    var gasAnnotations: [MKPointAnnotation] = []
                                                                    
                                                                    var count = 0;
                                                                    while count <= 10 {
                                                                        let venue = self.results[count] as! NSDictionary
                                                                        let lat = venue.value(forKeyPath: "location.lat") as! NSNumber
                                                                        let lng = venue.value(forKeyPath: "location.lng") as! NSNumber
                                                                        var city: NSString?
                                                                        var address: NSString?
                                                                        var zipCode: NSString?
                                                                        let name = venue.value(forKeyPath: "name") as! NSString
                                                                        if let _address = venue.value(forKeyPath: "location.address") as? NSString {
                                                                            address = _address
                                                                        } else {
                                                                            address = ""
                                                                        }
                                                                        if let _city = venue.value(forKeyPath: "location.city") as? NSString {
                                                                            city = _city
                                                                        } else {
                                                                            city = ""
                                                                        }
                                                                        if let _zipCode = venue.value(forKeyPath: "location.postalCode") as? NSString {
                                                                            zipCode = _zipCode
                                                                        } else {
                                                                            zipCode = ""
                                                                        }

                                                                        let annotation = MKPointAnnotation()
                                                                        let myLocation = CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
                                                                        annotation.coordinate = myLocation.coordinate
                                                                        annotation.title = name as String
                                                                        annotation.subtitle = (address as! String) + " " + (city as! String) + " " + (zipCode as! String)
                                                                        
                                                                        gasAnnotations.append(annotation)
                                                                        count = count + 1
                                                                    }
                                                                    self.mapView.addAnnotations(gasAnnotations)
                                                                }
                                                            }
        });
        task.resume()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "pin"
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKPinAnnotationView
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            pin!.pinTintColor = UIColor.blue

            print(annotation.title!)
            pin!.canShowCallout = true
            //pin!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            // create a new View
            let multiLineView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 60))
            // add all the labels you need here
            let label1 = UILabel(frame: CGRect(x: 4, y: 0, width: 120, height: 20))
            // get regular price
            label1.text = "Regular: $2.99"

            ParseClient.sharedInstance.getFuelPrice(fuelType: "regular", success: { (price) in
                if let _price = price.price {
                    label1.text = "Regular: $" + _price
                }
            }, failure: { (error) in
                print(error)
            })
            label1.font = UIFont(name: label1.font.fontName, size: 12)
            multiLineView.addSubview(label1)
            let label2 = UILabel(frame: CGRect(x: 4, y: 15, width: 120, height: 20))
            label2.text = "Plus: $3.49"
            label2.font = UIFont(name: label2.font.fontName, size: 12)
            multiLineView.addSubview(label2)
            let label3 = UILabel(frame: CGRect(x: 4, y: 30, width: 120, height: 20))
            label3.text = "Premium: $3.99"
            label3.font = UIFont(name: label2.font.fontName, size: 12)
            multiLineView.addSubview(label3)

            multiLineView.backgroundColor = UIColor.lightGray
            pin!.leftCalloutAccessoryView = multiLineView
        } else {
            pin!.annotation = annotation
        }
        return pin
    }
    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.shared
            app.openURL(NSURL(string: (annotationView.annotation!.subtitle!)!)! as URL)
        }
    }
    
    func onLocationChangeError(error: Error) {
        print("location error: ", error.localizedDescription)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getChartDataSet(vehicle: VehicleModel) -> LineChartDataSet {
        var dataEntries: [ChartDataEntry] = [ChartDataEntry]()
        
        let trackingModels = TrackingModel.getAllByTimelineAndVehicle(timelineFilter: selectedTimelineFilter, vehicle: vehicle)
        
        var index = 0
        for tracking in trackingModels {
            if let mpg = tracking.mpg {
                let dataEntry = ChartDataEntry(x: Double(index), y: mpg)
                dataEntries.append(dataEntry)
                
                index += 1
            }
            
        }
        
        let dataSet = LineChartDataSet(values: dataEntries, label: "\(vehicle.make!) \(vehicle.model!)")
        
        return dataSet
    }
    
    func createChart() {
        var dataSets = [LineChartDataSet]()

        var index = 0
        for vehicleIndex in selectedVehicleIndexes {
            let vehicle = vehicles[vehicleIndex]
            let dataSet = getChartDataSet(vehicle: vehicle)
            let color = lineChartColors[index % 3]
            dataSet.setColor(color)
            dataSet.setCircleColor(color)
            dataSet.circleRadius = 5.0
            dataSets.append(dataSet)
            
            index += 1
        }
        
        let xAxis: XAxis = XAxis()
        let lineChartFormatter: LineChartFormatter = LineChartFormatter()
        xAxis.valueFormatter = lineChartFormatter
        
        let data = LineChartData(dataSets: dataSets)
        data.setDrawValues(false)
        mpgChartView.data = data
        mpgChartView.xAxis.valueFormatter = xAxis.valueFormatter
    }
    
    func createCheckboxes() {
        var index = 0
        for vehicle in vehicles {
            let vehicleButton = UIButton(frame: CGRect(x: 16, y: 360 + (index * 25), width: 60, height: 20))
            vehicleButton.addTarget(self, action: #selector(onVehicleTap(_ :)), for: .touchUpInside)
            vehicleButton.backgroundColor = UIColor.gray
            let vehicleButtonTitle = NSAttributedString(string: "\(vehicle.make!) \(vehicle.model!)", attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: 11),
                NSForegroundColorAttributeName: UIColor.black
            ])
            vehicleButton.setAttributedTitle(vehicleButtonTitle, for: .normal)
            vehicleButton.tag = index
            view.addSubview(vehicleButton)
            
            index += 1
        }
    }
    
    func onVehicleTap(_ sender: UIButton) {
        let vehicleIndex = sender.tag
        if selectedVehicleIndexes.contains(vehicleIndex) {
            selectedVehicleIndexes.remove(at: vehicleIndex)
        } else {
            selectedVehicleIndexes.insert(vehicleIndex, at: vehicleIndex)
        }
        createChart()
    }
    
    @IBAction func onMPGFilterChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedTimelineFilter = TrackingTimelineFilter.lastWeek
        case 1:
            selectedTimelineFilter = TrackingTimelineFilter.lastMonth
        case 2:
            selectedTimelineFilter = TrackingTimelineFilter.lastYear
        case 3:
            selectedTimelineFilter = TrackingTimelineFilter.allTime
        default:
            break
        }
        createChart()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
