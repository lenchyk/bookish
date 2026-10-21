//
//  OrderDetails.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct OrderDetails: Equatable {
  var loadingStateById: [Order.ID: LoadingState] = [:]
}
