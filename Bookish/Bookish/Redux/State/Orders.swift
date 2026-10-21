//
//  Orders.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct Orders: Equatable {
  var byId: [Order.ID: Order] = [:]
}
