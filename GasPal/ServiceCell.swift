//
//  ServiceCell.swift
//  GasPal
//
//  Created by Luis Rocha on 4/30/17.
//  Copyright © 2017 Tyler Hackley Lewis. All rights reserved.
//

import UIKit

class ServiceCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var serviceDescriptionLabel: UILabel!
    @IBOutlet weak var vehicleName: UILabel!
    
    var service: ServiceModel! {
        didSet {
            if let date = service.serviceDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/YY"
                dateLabel.text = formatter.string(from: date)
            }
            if let totalPrice = service.price {
                totalPriceLabel.text = String.init(format: "$%.2f", totalPrice)
            }
            serviceDescriptionLabel.text = service.serviceDescription
            if let vehicle = service.vehicle {
                vehicleName.text = vehicle.getVehicleInfo()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
