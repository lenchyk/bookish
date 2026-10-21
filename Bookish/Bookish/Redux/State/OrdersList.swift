//
//  OrdersList.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct OrdersList: Equatable {
  var ids: [Order.ID] = []
  var loadingState: LoadingState = .idle
}
